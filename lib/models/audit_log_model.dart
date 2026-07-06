enum AuditAction {
  trustCreated,
  trustUpdated,
  trustDeleted,
  transactionAdded,
  transactionApproved,
  transactionRejected,
  transactionReversed,
  memberAdded,
  memberRemoved,
  memberPromoted,
  memberDemoted,
  settingsUpdated,
  userLoggedIn,
  userLoggedOut,
}

class AuditLogModel {
  final String logId;
  final String trustId;
  final AuditAction action;
  final String performedBy;
  final String performedByName;
  final DateTime timestamp;
  final String targetDoc;
  final String details;

  AuditLogModel({
    required this.logId,
    required this.trustId,
    required this.action,
    required this.performedBy,
    required this.performedByName,
    required this.timestamp,
    this.targetDoc = '',
    this.details = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'trustId': trustId,
      'action': action.name,
      'performedBy': performedBy,
      'performedByName': performedByName,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'targetDoc': targetDoc,
      'details': details,
    };
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      logId: map['logId'] ?? '',
      trustId: map['trustId'] ?? '',
      action: AuditAction.values.firstWhere(
        (e) => e.name == map['action'],
        orElse: () => AuditAction.trustCreated,
      ),
      performedBy: map['performedBy'] ?? '',
      performedByName: map['performedByName'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      targetDoc: map['targetDoc'] ?? '',
      details: map['details'] ?? '',
    );
  }
}
