import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/khata/controller/khata_controller.dart';
import 'package:digiluk/models/party_audit_log_model.dart';

class PartyAuditLogScreen extends ConsumerWidget {
  static const String routeName = '/party-audit-log';
  final String partyId;
  final String partyName;

  const PartyAuditLogScreen({
    super.key,
    required this.partyId,
    required this.partyName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.watch(khataControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Audit: $partyName'),
      ),
      body: StreamBuilder<List<PartyAuditLogModel>>(
        stream: ctrl.getPartyAuditLogs(partyId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
          final logs = snap.data ?? [];
          if (logs.isEmpty) {
            return const EmptyState(
              title: 'No Edits Yet',
              subtitle: 'All profile changes will be recorded here',
              icon: Icons.history,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              return _buildLogTile(log);
            },
          );
        },
      ),
    );
  }

  Widget _buildLogTile(PartyAuditLogModel log) {
    final isDelete = log.fieldName == 'Party Deleted';
    final color = isDelete ? digilukExpense : digilukPrimary;

    String subtitle;
    if (isDelete) {
      subtitle = 'Party "$log.oldValue" was deleted';
    } else if (log.oldValue.isEmpty) {
      subtitle = '${log.fieldName} set to "${log.newValue}"';
    } else if (log.newValue.isEmpty) {
      subtitle = '${log.fieldName} removed (was "${log.oldValue}")';
    } else if (log.fieldName == 'Photo') {
      subtitle = 'Photo updated';
    } else {
      subtitle = '${log.fieldName} changed from "${log.oldValue}" to "${log.newValue}"';
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
          child: Icon(
            isDelete ? Icons.delete : Icons.edit,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          subtitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                log.editedByName,
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
                formatDateTime(log.timestamp),
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
