import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/features/trust/controller/trust_controller.dart';
import 'package:digiluk/models/audit_log_model.dart';

class AuditLogScreen extends ConsumerWidget {
  static const String routeName = '/audit-log';
  final String trustId;
  const AuditLogScreen({super.key, required this.trustId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustController = ref.watch(trustControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
      ),
      body: StreamBuilder<List<AuditLogModel>>(
        stream: trustController.getAuditLogs(trustId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyState(
              title: 'No Activity Yet',
              subtitle: 'All actions will be recorded here',
              icon: Icons.history,
            );
          }
          final logs = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildLogTile(log);
            },
          );
        },
      ),
    );
  }

  Widget _buildLogTile(AuditLogModel log) {
    IconData icon;
    Color color;
    switch (log.action) {
      case AuditAction.trustCreated:
        icon = Icons.account_balance;
        color = digilukPrimary;
        break;
      case AuditAction.transactionAdded:
        icon = Icons.receipt_long;
        color = digilukPrimary;
        break;
      case AuditAction.transactionApproved:
        icon = Icons.check_circle;
        color = digilukIncome;
        break;
      case AuditAction.transactionRejected:
        icon = Icons.cancel;
        color = digilukExpense;
        break;
      case AuditAction.memberAdded:
        icon = Icons.person_add;
        color = digilukPrimary;
        break;
      case AuditAction.memberPromoted:
        icon = Icons.arrow_upward;
        color = digilukRoleCreator;
        break;
      case AuditAction.memberDemoted:
        icon = Icons.arrow_downward;
        color = digilukGrey;
        break;
      case AuditAction.settingsUpdated:
        icon = Icons.settings;
        color = digilukSubTextColor;
        break;
      default:
        icon = Icons.info;
        color = digilukSubTextColor;
    }

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
          log.details,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                log.performedByName,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                ' \u00b7 ',
                style: TextStyle(fontSize: 12, color: digilukGrey),
              ),
              Text(
                formatTimeAgo(log.timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  color: digilukSubTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
