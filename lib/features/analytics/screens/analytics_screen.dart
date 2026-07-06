import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/auth/controller/auth_controller.dart';
import 'package:digiluk/features/trust/controller/trust_controller.dart';
import 'package:digiluk/models/transaction_model.dart';
import 'package:digiluk/models/trust_model.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null || user.trustIds.isEmpty) {
            return const EmptyState(
              title: 'No Data',
              subtitle: 'Create a trust to see analytics',
              icon: Icons.bar_chart_outlined,
            );
          }
          return StreamBuilder<List<TrustModel>>(
            stream: ref.watch(trustControllerProvider).getUserTrusts(user.trustIds),
            builder: (context, trustSnapshot) {
              if (trustSnapshot.connectionState == ConnectionState.waiting) {
                return const Loader();
              }
              if (!trustSnapshot.hasData || trustSnapshot.data!.isEmpty) {
                return const EmptyState(
                  title: 'No Data',
                  subtitle: 'Create a trust to see analytics',
                  icon: Icons.bar_chart_outlined,
                );
              }
              final trusts = trustSnapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trusts.length,
                itemBuilder: (context, index) {
                  final trust = trusts[index];
                  return _buildTrustAnalyticsCard(context, ref, trust);
                },
              );
            },
          );
        },
        error: (err, trace) => Center(child: Text(err.toString())),
        loading: () => const Loader(),
      ),
    );
  }

  Widget _buildTrustAnalyticsCard(
    BuildContext context,
    WidgetRef ref,
    TrustModel trust,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: digilukPrimary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trust.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '\u{20B9}${trust.totalBalance.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: digilukPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<TransactionModel>>(
              stream: ref
                  .watch(trustControllerProvider)
                  .getTransactions(trust.trustId),
              builder: (context, txnSnapshot) {
                double income = 0;
                double expense = 0;
                Map<String, double> categoryData = {};

                if (txnSnapshot.hasData) {
                  for (var txn in txnSnapshot.data!) {
                    if (txn.status == TransactionStatus.approved) {
                      if (txn.type == TransactionType.income) {
                        income += txn.amount;
                      } else {
                        expense += txn.amount;
                        categoryData[txn.category] =
                            (categoryData[txn.category] ?? 0) + txn.amount;
                      }
                    }
                  }
                }

                if (income == 0 && expense == 0) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No transaction data yet',
                      style: TextStyle(color: digilukSubTextColor),
                    ),
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Income',
                            income,
                            digilukIncome,
                            Icons.arrow_downward,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Expense',
                            expense,
                            digilukExpense,
                            Icons.arrow_upward,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (income > 0 || expense > 0) ...[
                      const Text(
                        'Income vs Expense',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (income > expense ? income : expense) * 1.2,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: const FlTitlesData(
                              show: false,
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: income,
                                    color: digilukIncome,
                                    width: 40,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: expense,
                                    color: digilukExpense,
                                    width: 40,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendDot(digilukIncome, 'Income'),
                          const SizedBox(width: 16),
                          _legendDot(digilukExpense, 'Expense'),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\u{20B9}${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
