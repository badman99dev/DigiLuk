enum LedgerEntryType { udhaar, payment }

class LedgerEntryModel {
  final String entryId;
  final String customerId;
  final String trustId;
  final LedgerEntryType type;
  final double amount;
  final String note;
  final DateTime date;
  final String addedBy;
  final String addedByName;

  LedgerEntryModel({
    required this.entryId,
    required this.customerId,
    required this.trustId,
    required this.type,
    required this.amount,
    this.note = '',
    required this.date,
    required this.addedBy,
    required this.addedByName,
  });

  Map<String, dynamic> toMap() {
    return {
      'entryId': entryId,
      'customerId': customerId,
      'trustId': trustId,
      'type': type.name,
      'amount': amount,
      'note': note,
      'date': date.millisecondsSinceEpoch,
      'addedBy': addedBy,
      'addedByName': addedByName,
    };
  }

  factory LedgerEntryModel.fromMap(Map<String, dynamic> map) {
    return LedgerEntryModel(
      entryId: map['entryId'] ?? '',
      customerId: map['customerId'] ?? '',
      trustId: map['trustId'] ?? '',
      type: LedgerEntryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => LedgerEntryType.udhaar,
      ),
      amount: (map['amount'] ?? 0).toDouble(),
      note: map['note'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(
        map['date'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      addedBy: map['addedBy'] ?? '',
      addedByName: map['addedByName'] ?? '',
    );
  }
}
