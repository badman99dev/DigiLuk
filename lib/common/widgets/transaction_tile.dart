import 'package:flutter/material.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/models/transaction_model.dart';
import 'package:digiluk/common/utils/utils.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome ? digilukIncome : digilukExpense;
    final sign = isIncome ? '+' : '-';

    Color statusColor;
    switch (transaction.status) {
      case TransactionStatus.approved:
        statusColor = digilukApproved;
        break;
      case TransactionStatus.pending:
        statusColor = digilukPending;
        break;
      case TransactionStatus.rejected:
        statusColor = digilukRejected;
        break;
      case TransactionStatus.reversed:
        statusColor = digilukGrey;
        break;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: digilukCardColor,
          border: Border(
            bottom: BorderSide(color: digilukDividerColor, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: amountColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$sign${formatCurrency(transaction.amount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: amountColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          transaction.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.description.isNotEmpty
                        ? transaction.description
                        : transaction.category,
                    style: const TextStyle(
                      fontSize: 13,
                      color: digilukSubTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.addedByName} \u00b7 ${formatTimeAgo(transaction.createdAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: digilukGrey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (transaction.proofUrls.isNotEmpty)
              const Icon(Icons.receipt_long, size: 18, color: digilukGrey),
          ],
        ),
      ),
    );
  }
}
