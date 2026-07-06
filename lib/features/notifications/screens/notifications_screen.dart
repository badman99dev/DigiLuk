import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/features/auth/controller/auth_controller.dart';
import 'package:digiluk/features/trust/controller/trust_controller.dart';
import 'package:digiluk/models/transaction_model.dart';
import 'package:digiluk/models/trust_model.dart';
import 'package:digiluk/common/utils/utils.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null || user.trustIds.isEmpty) {
            return const EmptyState(
              title: 'No Alerts',
              subtitle: 'Notifications about pending approvals and new transactions will appear here',
              icon: Icons.notifications_none,
            );
          }
          return StreamBuilder<List<TrustModel>>(
            stream:
                ref.watch(trustControllerProvider).getUserTrusts(user.trustIds),
            builder: (context, trustSnapshot) {
              if (!trustSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final trusts = trustSnapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trusts.length,
                itemBuilder: (context, index) {
                  final trust = trusts[index];
                  return _buildTrustNotifications(context, ref, trust);
                },
              );
            },
          );
        },
        error: (err, trace) => Center(child: Text(err.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildTrustNotifications(
    BuildContext context,
    WidgetRef ref,
    TrustModel trust,
  ) {
    return StreamBuilder<List<TransactionModel>>(
      stream: ref.watch(trustControllerProvider).getTransactions(trust.trustId),
      builder: (context, snapshot) {
        List<Widget> notifications = [];

        if (snapshot.hasData) {
          final pendingTxns = snapshot.data!
              .where((t) => t.status == TransactionStatus.pending)
              .toList();

          for (var txn in pendingTxns) {
            notifications.add(_buildNotificationTile(
              trust.name,
              'Pending approval: ${txn.type.name} of \u{20B9}${txn.amount.toStringAsFixed(0)} by ${txn.addedByName}',
              digilukPending,
              Icons.pending_actions,
              txn.createdAt,
            ));
          }

          final recentTxns = snapshot.data!
              .where((t) =>
                  t.status == TransactionStatus.approved &&
                  DateTime.now().difference(t.createdAt).inHours < 24)
              .toList();

          for (var txn in recentTxns) {
            notifications.add(_buildNotificationTile(
              trust.name,
              'New ${txn.type.name}: ${txn.type == TransactionType.income ? '+' : '-'}\u{20B9}${txn.amount.toStringAsFixed(0)} - ${txn.description.isNotEmpty ? txn.description : txn.category}',
              txn.type == TransactionType.income ? digilukIncome : digilukExpense,
              txn.type == TransactionType.income
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              txn.createdAt,
            ));
          }
        }

        if (notifications.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
              child: Text(
                trust.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: digilukSubTextColor,
                ),
              ),
            ),
            ...notifications,
          ],
        );
      },
    );
  }

  Widget _buildNotificationTile(
    String trustName,
    String message,
    Color color,
    IconData icon,
    DateTime time,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          message,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            formatTimeAgo(time),
            style: const TextStyle(fontSize: 11, color: digilukSubTextColor),
          ),
        ),
      ),
    );
  }
}
