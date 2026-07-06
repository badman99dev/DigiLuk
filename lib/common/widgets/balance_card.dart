import 'package:flutter/material.dart';
import 'package:digiluk/common/utils/colors.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final String trustName;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.trustName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [digilukPrimary, digilukPrimaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: digilukPrimary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trustName,
            style: const TextStyle(
              color: digilukWhite,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          const Text(
            'Current Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\u{20B9}${balance.toStringAsFixed(0)}',
            style: const TextStyle(
              color: digilukWhite,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  'Income',
                  '\u{20B9}${totalIncome.toStringAsFixed(0)}',
                  Icons.arrow_downward,
                  digilukIncome,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
              ),
              Expanded(
                child: _buildStat(
                  'Expense',
                  '\u{20B9}${totalExpense.toStringAsFixed(0)}',
                  Icons.arrow_upward,
                  digilukExpense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: digilukWhite,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
