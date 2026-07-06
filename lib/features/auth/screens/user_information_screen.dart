import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/custom_button.dart';
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
  File? image;
  String? _googlePhotoUrl;
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

  void selectImage() async {
    image = await pickImageFromGallery(context);
    setState(() {});
  }

  void storeUserData() async {
    String name = nameController.text.trim();
    if (name.isNotEmpty) {
      setState(() => _isLoading = true);
      ref.read(authControllerProvider).saveUserDataToFirebase(
            context,
            name,
            image,
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
              Stack(
                children: [
                  image != null
                      ? CircleAvatar(
                          radius: 64,
                          backgroundImage: FileImage(image!),
                        )
                      : _googlePhotoUrl != null
                          ? CircleAvatar(
                              radius: 64,
                              backgroundImage: NetworkImage(_googlePhotoUrl!),
                            )
                          : CircleAvatar(
                              radius: 64,
                              backgroundColor:
                                  digilukPrimary.withOpacity(0.1),
                              child: const Icon(
                                Icons.person,
                                size: 64,
                                color: digilukPrimary,
                              ),
                            ),
                  Positioned(
                    bottom: -10,
                    left: 80,
                    child: IconButton(
                      onPressed: selectImage,
                      icon: const Icon(Icons.add_a_photo,
                          color: digilukPrimary),
                    ),
                  ),
                ],
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
                onPressed: storeUserData,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
