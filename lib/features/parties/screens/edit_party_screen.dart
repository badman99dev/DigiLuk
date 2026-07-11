import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/repositories/cloudinary_repository.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/contact_picker.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/image_upload_preview.dart';
import 'package:digiluk/features/auth/controller/auth_controller.dart';
import 'package:digiluk/features/khata/controller/khata_controller.dart';
import 'package:digiluk/models/party_model.dart';

class EditPartyScreen extends ConsumerStatefulWidget {
  static const String routeName = '/edit-party';
  final PartyModel party;

  const EditPartyScreen({super.key, required this.party});

  @override
  ConsumerState<EditPartyScreen> createState() => _EditPartyScreenState();
}

class _EditPartyScreenState extends ConsumerState<EditPartyScreen> {
  late final _nameCtrl = TextEditingController(text: widget.party.name);
  late final _phoneCtrl = TextEditingController(text: widget.party.phone);
  late final _emailCtrl = TextEditingController(text: widget.party.email);
  late final _customNameCtrl = TextEditingController(text: widget.party.customCategoryName);
  late final _giveLabelCtrl = TextEditingController(text: widget.party.giveLabel);
  late final _receiveLabelCtrl = TextEditingController(text: widget.party.receiveLabel);
  File? _photoFile;
  String? _photoUrl;
  ImageUploadState _uploadState = ImageUploadState.initial;
  int _uploadPercent = 0;
  late String _category = widget.party.category;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _customNameCtrl.dispose();
    _giveLabelCtrl.dispose();
    _receiveLabelCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectPhoto() async {
    final img = await pickImageFromGallery(context);
    if (img == null) return;
    _startUpload(img);
  }

  Future<void> _startUpload(File img) async {
    setState(() {
      _photoFile = img;
      _photoUrl = null;
      _uploadState = ImageUploadState.uploading;
      _uploadPercent = 0;
    });
    try {
      final url = await ref.read(cloudinaryRepositoryProvider).uploadImage(
        img,
        folder: 'digiluk/parties',
        onProgress: (percent) => setState(() => _uploadPercent = percent),
      );
      setState(() {
        _photoUrl = url;
        _uploadState = ImageUploadState.uploaded;
      });
    } catch (e) {
      setState(() => _uploadState = ImageUploadState.error);
      showSnackBar(context: context, content: 'Upload failed: $e');
    }
  }

  void _retryUpload() {
    if (_photoFile != null) _startUpload(_photoFile!);
  }

  void _removePhoto() {
    setState(() {
      _photoFile = null;
      _photoUrl = null;
      _uploadState = ImageUploadState.initial;
      _uploadPercent = 0;
    });
  }

  void _submit() {
    if (_uploadState.isBlocking) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showSnackBar(context: context, content: 'Enter name');
      return;
    }

    final isCustom = _category == 'custom';
    final userAsync = ref.read(userDataAuthProvider);
    final user = userAsync.value;

    ref.read(khataControllerProvider).updateParty(
          context: context,
          oldParty: widget.party,
          name: name,
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          photoUrl: _photoUrl ?? widget.party.photoUrl,
          category: _category,
          customCategoryName: isCustom ? _customNameCtrl.text.trim() : '',
          giveLabel: isCustom ? _giveLabelCtrl.text.trim() : '',
          receiveLabel: isCustom ? _receiveLabelCtrl.text.trim() : '',
          editedByName: user?.name ?? 'User',
        );
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = _category == 'custom';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ImageUploadPreview(
                file: _photoFile,
                uploadedUrl: _photoUrl ?? widget.party.photoUrl,
                state: _uploadState,
                uploadPercent: _uploadPercent,
                onSelect: _selectPhoto,
                onRetry: _retryUpload,
                onRemove: _removePhoto,
                shape: BoxShape.circle,
                circleRadius: 44,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Customer Category',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: digilukTextColor),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PartyCategory.defaults.map((c) {
                return ChoiceChip(
                  label: Text(c.displayName),
                  selected: _category == c.id,
                  selectedColor: digilukPrimary,
                  labelStyle: TextStyle(
                    color: _category == c.id ? digilukWhite : digilukTextColor,
                  ),
                  onSelected: (v) {
                    if (v) setState(() => _category = c.id);
                  },
                );
              }).toList(),
            ),
            if (isCustom) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _customNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Custom Category Name',
                  hintText: 'e.g. Gym Member',
                  prefixIcon: Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _giveLabelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Give Label',
                        hintText: 'e.g. Add Fee',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _receiveLabelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Receive Label',
                        hintText: 'e.g. Fee Received',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'Enter name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone',
                hintText: 'Enter phone number',
                prefixIcon: const Icon(Icons.phone_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.contacts, color: digilukPrimary),
                  tooltip: 'Choose from contacts',
                  onPressed: () async {
                    final phone = await pickContactPhone(context);
                    if (phone != null && phone.isNotEmpty) {
                      _phoneCtrl.text = phone;
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploadState.isBlocking ? null : _submit,
                icon: const Icon(Icons.check),
                label: const Text('Save Changes',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
