enum KhataEntryType { give, receive }

class KhataEntryModel {
  final String entryId;
  final String partyId;
  final String uid;
  final KhataEntryType type;
  final double amount;
  final String note;
  final String billUrl;
  final DateTime date;
  final String addedBy;
  final bool isDeleted;

  KhataEntryModel({
    required this.entryId,
    required this.partyId,
    required this.uid,
    required this.type,
    required this.amount,
    this.note = '',
    this.billUrl = '',
    required this.date,
    required this.addedBy,
    this.isDeleted = false,
  });

  KhataEntryModel copyWith({
    double? amount,
    String? note,
    String? billUrl,
    bool? isDeleted,
  }) {
    return KhataEntryModel(
      entryId: entryId,
      partyId: partyId,
      uid: uid,
      type: type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      billUrl: billUrl ?? this.billUrl,
      date: date,
      addedBy: addedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entryId': entryId,
      'partyId': partyId,
      'uid': uid,
      'type': type.name,
      'amount': amount,
      'note': note,
      'billUrl': billUrl,
      'date': date.millisecondsSinceEpoch,
      'addedBy': addedBy,
      'isDeleted': isDeleted,
    };
  }

  factory KhataEntryModel.fromMap(Map<String, dynamic> map) {
    return KhataEntryModel(
      entryId: map['entryId'] ?? '',
      partyId: map['partyId'] ?? '',
      uid: map['uid'] ?? '',
      type: KhataEntryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => KhataEntryType.give,
      ),
      amount: (map['amount'] ?? 0).toDouble(),
      note: map['note'] ?? '',
      billUrl: map['billUrl'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(
        map['date'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      addedBy: map['addedBy'] ?? '',
      isDeleted: map['isDeleted'] ?? false,
    );
  }
}
