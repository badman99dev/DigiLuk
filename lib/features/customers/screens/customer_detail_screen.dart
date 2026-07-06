import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/customers/controller/customer_controller.dart';
import 'package:digiluk/models/ledger_entry_model.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  static const String routeName = '/customer-detail';
  final String trustId;
  final String customerId;
  final String customerName;

  const CustomerDetailScreen({
    super.key,
    required this.trustId,
    required this.customerId,
    required this.customerName,
  });

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  void _showAddEntryDialog(LedgerEntryType defaultType) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    LedgerEntryType selectedType = defaultType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                  Text(
                    selectedType == LedgerEntryType.udhaar
                        ? 'Add Udhaar (Gave)'
                        : 'Add Payment (Got)',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Udhaar (Gave)'),
                          selected: selectedType == LedgerEntryType.udhaar,
                          selectedColor: digilukExpense,
                          labelStyle: TextStyle(
                            color: selectedType == LedgerEntryType.udhaar
                                ? digilukWhite
                                : digilukTextColor,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() =>
                                  selectedType = LedgerEntryType.udhaar);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Payment (Got)'),
                          selected: selectedType == LedgerEntryType.payment,
                          selectedColor: digilukIncome,
                          labelStyle: TextStyle(
                            color: selectedType == LedgerEntryType.payment
                                ? digilukWhite
                                : digilukTextColor,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() =>
                                  selectedType = LedgerEntryType.payment);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: '\u{20B9} ',
                      hintText: '0',
                      prefixStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: digilukPrimary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Note (optional)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        double? amount =
                            double.tryParse(amountController.text.trim());
                        if (amount == null || amount <= 0) {
                          showSnackBar(
                              context: context,
                              content: 'Enter valid amount');
                          return;
                        }
                        ref.read(customerControllerProvider).addLedgerEntry(
                              context: context,
                              trustId: widget.trustId,
                              customerId: widget.customerId,
                              type: selectedType,
                              amount: amount,
                              note: noteController.text.trim(),
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedType == LedgerEntryType.udhaar
                            ? digilukExpense
                            : digilukIncome,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        selectedType == LedgerEntryType.udhaar
                            ? 'Add Udhaar'
                            : 'Add Payment',
                        style: const TextStyle(
                            color: digilukWhite, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerController = ref.watch(customerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerName),
      ),
      body: StreamBuilder<List<LedgerEntryModel>>(
        stream: customerController.getLedgerEntries(
            widget.trustId, widget.customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyState(
              title: 'No Transactions',
              subtitle: 'Add udhaar or payment entries',
              icon: Icons.receipt_long_outlined,
            );
          }
          final entries = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isUdhaar = entry.type == LedgerEntryType.udhaar;
                    final color = isUdhaar ? digilukExpense : digilukIncome;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isUdhaar
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: color,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              '${isUdhaar ? '+' : '-'}\u{20B9}${entry.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isUdhaar ? 'UDHAAR' : 'PAYMENT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            entry.note.isNotEmpty
                                ? entry.note
                                : 'No note',
                            style: const TextStyle(
                                fontSize: 12, color: digilukSubTextColor),
                          ),
                        ),
                        trailing: Text(
                          formatDate(entry.date),
                          style: const TextStyle(
                              fontSize: 11, color: digilukSubTextColor),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'payment',
            onPressed: () => _showAddEntryDialog(LedgerEntryType.payment),
            backgroundColor: digilukIncome,
            child: const Icon(Icons.add, color: digilukWhite),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            heroTag: 'udhaar',
            onPressed: () => _showAddEntryDialog(LedgerEntryType.udhaar),
            backgroundColor: digilukExpense,
            child: const Icon(Icons.remove, color: digilukWhite),
          ),
        ],
      ),
    );
  }
}
