import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/customers/controller/customer_controller.dart';
import 'package:digiluk/features/customers/screens/add_customer_screen.dart';
import 'package:digiluk/features/customers/screens/customer_detail_screen.dart';
import 'package:digiluk/models/customer_model.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomersListScreen extends ConsumerWidget {
  static const String routeName = '/customers';
  final String trustId;
  const CustomersListScreen({super.key, required this.trustId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerController = ref.watch(customerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AddCustomerScreen.routeName,
                arguments: trustId,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<CustomerModel>>(
        stream: customerController.getCustomers(trustId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState(
              title: 'No Customers Yet',
              subtitle: 'Add customers to track their udhaar and payments',
              icon: Icons.people_outline,
              onAction: () {
                Navigator.pushNamed(
                  context,
                  AddCustomerScreen.routeName,
                  arguments: trustId,
                );
              },
              actionLabel: 'Add Customer',
            );
          }
          final customers = snapshot.data!;
          double totalUdhaar = customers
              .where((c) => c.balance > 0)
              .fold(0, (sum, c) => sum + c.balance);
          double totalPayable = customers
              .where((c) => c.balance < 0)
              .fold(0, (sum, c) => sum + c.balance.abs());

          return Column(
            children: [
              _buildSummaryCard(totalUdhaar, totalPayable, customers.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _buildCustomerCard(context, customer);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
      double udhaar, double payable, int count) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [digilukPrimary, digilukPrimaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$count Customers',
            style: const TextStyle(color: digilukWhite, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('You will get',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '\u{20B9}${udhaar.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: digilukIncome,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: Column(
                  children: [
                    const Text('You will give',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '\u{20B9}${payable.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: digilukExpense,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, CustomerModel customer) {
    final isUdhaar = customer.balance > 0;
    final balanceColor = isUdhaar ? digilukIncome : digilukExpense;
    final balanceText = customer.balance == 0
        ? 'Settled'
        : '${isUdhaar ? '+' : ''}\u{20B9}${customer.balance.toStringAsFixed(0)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: digilukPrimary.withOpacity(0.1),
          child: Text(
            customer.name.isNotEmpty
                ? customer.name[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: digilukPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: customer.phone.isNotEmpty
            ? Text(customer.phone,
                style: const TextStyle(fontSize: 12, color: digilukSubTextColor))
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              balanceText,
              style: TextStyle(
                color: customer.balance == 0 ? digilukGrey : balanceColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (customer.phone.isNotEmpty)
              GestureDetector(
                onTap: () => _sendWhatsAppReminder(customer),
                child: const Text(
                  'Remind',
                  style: TextStyle(
                    color: digilukPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            CustomerDetailScreen.routeName,
            arguments: {
              'trustId': trustId,
              'customerId': customer.customerId,
              'customerName': customer.name,
            },
          );
        },
      ),
    );
  }

  void _sendWhatsAppReminder(CustomerModel customer) async {
    if (customer.phone.isEmpty || customer.balance <= 0) return;
    String phone = customer.phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!phone.startsWith('91') && phone.length == 10) {
      phone = '91$phone';
    }
    String message =
        'Namaste ${customer.name},\nAapka \u{20B9}${customer.balance.toStringAsFixed(0)} pending hai.\n- DigiLuk';
    final url =
        'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
    await launchUrl(Uri.parse(url));
  }
}
