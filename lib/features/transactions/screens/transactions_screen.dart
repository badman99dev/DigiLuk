import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/common/widgets/transaction_tile.dart';
import 'package:digiluk/features/trust/controller/trust_controller.dart';
import 'package:digiluk/models/transaction_model.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  static const String routeName = '/transactions';
  final String trustId;
  const TransactionsScreen({super.key, required this.trustId});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionType? _filterType;
  TransactionStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final trustController = ref.watch(trustControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: trustController.getTransactions(widget.trustId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Loader();
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptyState(
                    title: 'No Transactions',
                    subtitle: 'Transactions will appear here',
                    icon: Icons.receipt_long_outlined,
                  );
                }
                var txns = snapshot.data!;
                if (_filterType != null) {
                  txns =
                      txns.where((t) => t.type == _filterType).toList();
                }
                if (_filterStatus != null) {
                  txns = txns
                      .where((t) => t.status == _filterStatus)
                      .toList();
                }
                if (txns.isEmpty) {
                  return const EmptyState(
                    title: 'No Results',
                    subtitle: 'No transactions match your filter',
                    icon: Icons.filter_alt_off_outlined,
                  );
                }
                return ListView.builder(
                  itemCount: txns.length,
                  itemBuilder: (context, index) {
                    final txn = txns[index];
                    return TransactionTile(
                      transaction: txn,
                      onTap: () => _showTransactionDetail(context, txn),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', _filterType == null, () {
              setState(() => _filterType = null);
            }),
            const SizedBox(width: 8),
            _buildFilterChip('Income', _filterType == TransactionType.income,
                () {
              setState(() => _filterType = TransactionType.income);
            }),
            const SizedBox(width: 8),
            _buildFilterChip('Expense', _filterType == TransactionType.expense,
                () {
              setState(() => _filterType = TransactionType.expense);
            }),
            const SizedBox(width: 16),
            _buildFilterChip('Pending', _filterStatus == TransactionStatus.pending,
                () {
              setState(() => _filterStatus =
                  _filterStatus == TransactionStatus.pending
                      ? null
                      : TransactionStatus.pending);
            }),
            const SizedBox(width: 8),
            _buildFilterChip('Approved',
                _filterStatus == TransactionStatus.approved, () {
              setState(() => _filterStatus =
                  _filterStatus == TransactionStatus.approved
                      ? null
                      : TransactionStatus.approved);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: digilukPrimary,
      labelStyle: TextStyle(
        color: selected ? digilukWhite : digilukTextColor,
      ),
    );
  }

  void _showTransactionDetail(BuildContext context, TransactionModel txn) {
    final trustController = ref.read(trustControllerProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: digilukDividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    txn.type == TransactionType.income
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: txn.type == TransactionType.income
                        ? digilukIncome
                        : digilukExpense,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${txn.type == TransactionType.income ? '+' : '-'}\u{20B9}${txn.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: txn.type == TransactionType.income
                          ? digilukIncome
                          : digilukExpense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow('Status', txn.status.name.toUpperCase()),
              _detailRow('Category', txn.category),
              _detailRow('Description', txn.description),
              _detailRow('Payment Method', txn.paymentMethod.name),
              _detailRow('Added By', txn.addedByName),
              _detailRow('Date',
                  '${txn.transactionDate.day}/${txn.transactionDate.month}/${txn.transactionDate.year}'),
              if (txn.proofUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Proofs:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: txn.proofUrls.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          txn.proofUrls[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (txn.status == TransactionStatus.pending) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          trustController.approveTransaction(
                            context: context,
                            trustId: txn.trustId,
                            txnId: txn.transactionId,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: digilukIncome,
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          trustController.rejectTransaction(
                            context: context,
                            trustId: txn.trustId,
                            txnId: txn.transactionId,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: digilukExpense,
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: digilukSubTextColor, fontSize: 14)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}
