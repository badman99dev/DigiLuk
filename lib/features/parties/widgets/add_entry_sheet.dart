import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/repositories/cloudinary_repository.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/image_upload_preview.dart';
import 'package:digiluk/features/khata/controller/khata_controller.dart';
import 'package:digiluk/models/khata_entry_model.dart';
import 'package:digiluk/models/party_model.dart';

class AddEntrySheet extends ConsumerStatefulWidget {
  final PartyModel party;
  final String partyId;
  final KhataEntryType defaultType;

  const AddEntrySheet({
    super.key,
    required this.party,
    required this.partyId,
    required this.defaultType,
  });

  @override
  ConsumerState<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<AddEntrySheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  File? _billPhoto;
  String? _billUrl;
  ImageUploadState _uploadState = ImageUploadState.initial;
  int _uploadPercent = 0;
  late KhataEntryType _selected = widget.defaultType;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectBillImage() async {
    final img = await pickImageFromGallery(context);
    if (img == null) return;
    _startUpload(img);
  }

  Future<void> _startUpload(File img) async {
    setState(() {
      _billPhoto = img;
      _billUrl = null;
      _uploadState = ImageUploadState.uploading;
      _uploadPercent = 0;
    });
    try {
      final url = await ref.read(cloudinaryRepositoryProvider).uploadImage(
        img,
        folder: 'digiluk/bills/${widget.party.uid}/${widget.partyId}',
        onProgress: (percent) => setState(() => _uploadPercent = percent),
      );
      setState(() {
        _billUrl = url;
        _uploadState = ImageUploadState.uploaded;
      });
    } catch (e) {
      setState(() => _uploadState = ImageUploadState.error);
      showSnackBar(context: context, content: 'Upload failed: $e');
    }
  }

  void _retryUpload() {
    if (_billPhoto != null) _startUpload(_billPhoto!);
  }

  void _removeBill() {
    setState(() {
      _billPhoto = null;
      _billUrl = null;
      _uploadState = ImageUploadState.initial;
      _uploadPercent = 0;
    });
  }

  void _save() {
    if (_uploadState.isBlocking) return;
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      showSnackBar(context: context, content: 'Enter valid amount');
      return;
    }
    ref.read(khataControllerProvider).addEntry(
          context: context,
          partyId: widget.partyId,
          type: _selected,
          amount: amount,
          note: _noteCtrl.text.trim(),
          billUrl: _billUrl,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Gave \u{20B9}'),
                  selected: _selected == KhataEntryType.give,
                  selectedColor: digilukExpense,
                  labelStyle: TextStyle(
                    color: _selected == KhataEntryType.give
                        ? digilukWhite
                        : digilukTextColor,
                  ),
                  onSelected: (v) {
                    if (v) setState(() => _selected = KhataEntryType.give);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Got \u{20B9}'),
                  selected: _selected == KhataEntryType.receive,
                  selectedColor: digilukIncome,
                  labelStyle: TextStyle(
                    color: _selected == KhataEntryType.receive
                        ? digilukWhite
                        : digilukTextColor,
                  ),
                  onSelected: (v) {
                    if (v) setState(() => _selected = KhataEntryType.receive);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: '\u{20B9} ',
              hintText: '0',
              prefixStyle: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: digilukPrimary),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Note (optional)',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file, size: 18),
                label: const Text('Attach Bill'),
                onPressed: _uploadState.isBlocking ? null : _selectBillImage,
              ),
              const SizedBox(width: 8),
              if (_billPhoto != null)
                SizedBox(
                  width: 56,
                  height: 56,
                  child: ImageUploadPreview(
                    file: _billPhoto,
                    uploadedUrl: _billUrl,
                    state: _uploadState,
                    uploadPercent: _uploadPercent,
                    onSelect: _selectBillImage,
                    onRetry: _retryUpload,
                    onRemove: _removeBill,
                    width: 56,
                    height: 56,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _uploadState.isBlocking ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selected == KhataEntryType.give
                    ? digilukExpense
                    : digilukIncome,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _selected == KhataEntryType.give ? 'Save Gave' : 'Save Got',
                style: const TextStyle(color: digilukWhite, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
