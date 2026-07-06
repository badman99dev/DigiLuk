import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/custom_button.dart';
import 'package:digiluk/features/customers/controller/customer_controller.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  static const String routeName = '/add-customer';
  final String trustId;
  const AddCustomerScreen({super.key, required this.trustId});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final balanceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    balanceController.dispose();
    super.dispose();
  }

  void _addCustomer() {
    String name = nameController.text.trim();
    if (name.isEmpty) {
      showSnackBar(context: context, content: 'Please enter customer name');
      return;
    }
    setState(() => _isLoading = true);
    double openingBalance =
        double.tryParse(balanceController.text.trim()) ?? 0;
    ref.read(customerControllerProvider).addCustomer(
          context: context,
          trustId: widget.trustId,
          name: name,
          phone: phoneController.text.trim(),
          email: emailController.text.trim(),
          openingBalance: openingBalance,
        );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Customer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer Name *',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: digilukTextColor)),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'e.g., Ramesh Kumar',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Phone Number',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: digilukTextColor)),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'e.g., 9876543210',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Email (Optional)',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: digilukTextColor)),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'customer@email.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Opening Balance (Optional)',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: digilukTextColor)),
            const SizedBox(height: 4),
            const Text(
                'Positive = customer owes you, Negative = you owe customer',
                style: TextStyle(fontSize: 11, color: digilukSubTextColor)),
            const SizedBox(height: 8),
            TextField(
              controller: balanceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: '0',
                prefixText: '\u{20B9} ',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Add Customer',
              onPressed: _addCustomer,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
