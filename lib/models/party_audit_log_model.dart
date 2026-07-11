class PartyAuditLogModel {
  final String logId;
  final String partyId;
  final String uid;
  final String fieldName;
  final String oldValue;
  final String newValue;
  final String editedBy;
  final String editedByName;
  final DateTime timestamp;

  PartyAuditLogModel({
    required this.logId,
    required this.partyId,
    required this.uid,
    required this.fieldName,
    this.oldValue = '',
    this.newValue = '',
    required this.editedBy,
    required this.editedByName,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'partyId': partyId,
      'uid': uid,
      'fieldName': fieldName,
      'oldValue': oldValue,
      'newValue': newValue,
      'editedBy': editedBy,
      'editedByName': editedByName,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory PartyAuditLogModel.fromMap(Map<String, dynamic> map) {
    return PartyAuditLogModel(
      logId: map['logId'] ?? '',
      partyId: map['partyId'] ?? '',
      uid: map['uid'] ?? '',
      fieldName: map['fieldName'] ?? '',
      oldValue: map['oldValue'] ?? '',
      newValue: map['newValue'] ?? '',
      editedBy: map['editedBy'] ?? '',
      editedByName: map['editedByName'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
