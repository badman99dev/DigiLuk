import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/repositories/cloudinary_repository.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/custom_button.dart';
import 'package:digiluk/common/widgets/image_upload_preview.dart';
import 'package:digiluk/features/trust/controller/trust_controller.dart';
import 'package:digiluk/models/transaction_model.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  static const String routeName = '/add-transaction';
  final String trustId;
  final TransactionType type;
  const AddTransactionScreen({
    super.key,
    required this.trustId,
    required this.type,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final amountController = TextEditingController();
  final descController = TextEditingController();
  final categoryController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  File? _proofFile;
  String? _proofUrl;
  ImageUploadState _proofUploadState = ImageUploadState.initial;
  int _proofUploadPercent = 0;
  bool _isLoading = false;

  final List<String> _incomeCategories = [
    'Donation',
    'Subscription',
    'Event Collection',
    'Interest',
    'Other Income',
  ];

  final List<String> _expenseCategories = [
    'Event Expense',
    'Maintenance',
    'Food',
    'Travel',
    'Utilities',
    'Salary',
    'Other Expense',
  ];

  @override
  void dispose() {
    amountController.dispose();
    descController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  Future<void> _selectProofImage() async {
    final img = await pickImageFromGallery(context);
    if (img == null) return;
    _startUpload(img);
  }

  Future<void> _startUpload(File img) async {
    setState(() {
      _proofFile = img;
      _proofUrl = null;
      _proofUploadState = ImageUploadState.uploading;
      _proofUploadPercent = 0;
    });
    try {
      final url = await ref.read(cloudinaryRepositoryProvider).uploadImage(
        img,
        folder: 'digiluk/groups/${widget.trustId}',
        onProgress: (percent) => setState(() => _proofUploadPercent = percent),
      );
      setState(() {
        _proofUrl = url;
        _proofUploadState = ImageUploadState.uploaded;
      });
    } catch (e) {
      setState(() => _proofUploadState = ImageUploadState.error);
      showSnackBar(context: context, content: 'Upload failed: $e');
    }
  }

  void _retryUpload() {
    if (_proofFile != null) _startUpload(_proofFile!);
  }

  void _removeProof() {
    setState(() {
      _proofFile = null;
      _proofUrl = null;
      _proofUploadState = ImageUploadState.initial;
      _proofUploadPercent = 0;
    });
  }

  void _submitTransaction() async {
    if (_proofUploadState.isBlocking) return;

    String amountStr = amountController.text.trim();
    if (amountStr.isEmpty) {
      showSnackBar(context: context, content: 'Please enter amount');
      return;
    }
    double? amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      showSnackBar(context: context, content: 'Please enter valid amount');
      return;
    }

    setState(() => _isLoading = true);

    List<String> proofUrls = [];
    if (_proofUrl != null && _proofUrl!.isNotEmpty) {
      proofUrls.add(_proofUrl!);
    }

    ref.read(trustControllerProvider).addTransaction(
          context: context,
          trustId: widget.trustId,
          type: widget.type,
          amount: amount,
          description: descController.text.trim(),
          category: categoryController.text.isEmpty
              ? (widget.type == TransactionType.income
                  ? 'Donation'
                  : 'Other Expense')
              : categoryController.text,
          paymentMethod: _paymentMethod,
          proofUrls: proofUrls,
        );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == TransactionType.income;
    final categories = isIncome ? _incomeCategories : _expenseCategories;
    final color = isIncome ? digilukIncome : digilukExpense;

    return Scaffold(
      appBar: AppBar(
        title: Text(isIncome ? 'Add Income' : 'Add Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: color,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isIncome ? 'Adding Income' : 'Adding Expense',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Amount',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: digilukTextColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                prefixText: '\u{20B9} ',
                hintText: '0',
                prefixStyle: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: digilukPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: digilukTextColor,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: categoryController.text.isEmpty ? null : categoryController.text,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
              ),
              hint: const Text('Select category'),
              items: categories
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() => categoryController.text = val ?? '');
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Description (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: digilukTextColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Add a note...',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: digilukTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PaymentMethod.values.map((method) {
                return ChoiceChip(
                  label: Text(_getPaymentLabel(method)),
                  selected: _paymentMethod == method,
                  selectedColor: digilukPrimary,
                  labelStyle: TextStyle(
                    color: _paymentMethod == method
                        ? digilukWhite
                        : digilukTextColor,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _paymentMethod = method);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Attach Bill/Receipt (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: digilukTextColor,
              ),
            ),
            const SizedBox(height: 8),
            ImageUploadPreview(
              file: _proofFile,
              uploadedUrl: _proofUrl,
              state: _proofUploadState,
              uploadPercent: _proofUploadPercent,
              onSelect: _selectProofImage,
              onRetry: _retryUpload,
              onRemove: _removeProof,
              placeholderText: 'Tap to upload bill/receipt',
              height: 120,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: isIncome ? 'Add Income' : 'Add Expense',
              color: color,
              onPressed: _submitTransaction,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  String _getPaymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.bank:
        return 'Bank';
      case PaymentMethod.other:
        return 'Other';
    }
  }
}
