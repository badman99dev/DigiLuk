import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/repositories/cloudinary_repository.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/custom_button.dart';
import 'package:digiluk/common/widgets/image_upload_preview.dart';
import 'package:digiluk/features/auth/controller/auth_controller.dart';

class UserInformationScreen extends ConsumerStatefulWidget {
  static const String routeName = '/user-information';
  const UserInformationScreen({super.key});

  @override
  ConsumerState<UserInformationScreen> createState() =>
      _UserInformationScreenState();
}

class _UserInformationScreenState extends ConsumerState<UserInformationScreen> {
  final TextEditingController nameController = TextEditingController();
  File? _imageFile;
  String? _uploadedPhotoUrl;
  String? _googlePhotoUrl;
  ImageUploadState _uploadState = ImageUploadState.initial;
  int _uploadPercent = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGoogleData();
  }

  void _loadGoogleData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      nameController.text = user.displayName ?? '';
      _googlePhotoUrl = user.photoURL;
      setState(() {});
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> selectImage() async {
    final img = await pickImageFromGallery(context);
    if (img == null) return;
    _startUpload(img);
  }

  Future<void> _startUpload(File img) async {
    setState(() {
      _imageFile = img;
      _uploadedPhotoUrl = null;
      _uploadState = ImageUploadState.uploading;
      _uploadPercent = 0;
    });
    try {
      final url = await ref.read(cloudinaryRepositoryProvider).uploadImage(
        img,
        folder: 'digiluk/profilePic',
        onProgress: (percent) => setState(() => _uploadPercent = percent),
      );
      setState(() {
        _uploadedPhotoUrl = url;
        _uploadState = ImageUploadState.uploaded;
      });
    } catch (e) {
      setState(() => _uploadState = ImageUploadState.error);
      showSnackBar(context: context, content: 'Upload failed: $e');
    }
  }

  void _retryUpload() {
    if (_imageFile != null) _startUpload(_imageFile!);
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _uploadedPhotoUrl = null;
      _uploadState = ImageUploadState.initial;
      _uploadPercent = 0;
    });
  }

  void storeUserData() async {
    if (_uploadState.isBlocking) return;
    String name = nameController.text.trim();
    if (name.isNotEmpty) {
      setState(() => _isLoading = true);
      final photoUrl = _uploadedPhotoUrl ?? _googlePhotoUrl;
      ref.read(authControllerProvider).saveUserDataToFirebase(
            context,
            name,
            photoUrl,
          );
      setState(() => _isLoading = false);
    } else {
      showSnackBar(context: context, content: 'Please enter your name');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              ImageUploadPreview(
                file: _imageFile,
                uploadedUrl: _uploadedPhotoUrl,
                state: _uploadState,
                uploadPercent: _uploadPercent,
                onSelect: selectImage,
                onRetry: _retryUpload,
                onRemove: _removeImage,
                shape: BoxShape.circle,
                circleRadius: 64,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Save & Continue',
                onPressed: _uploadState.isBlocking ? null : storeUserData,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
