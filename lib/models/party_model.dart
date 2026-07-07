enum PartyType { customer, supplier }

class PartyModel {
  final String partyId;
  final String uid;
  final PartyType type;
  final String name;
  final String phone;
  final String photoUrl;
  final double openingBalance;
  final double balance;
  final DateTime createdAt;
  final DateTime lastTransactionAt;

  PartyModel({
    required this.partyId,
    required this.uid,
    required this.type,
    required this.name,
    this.phone = '',
    this.photoUrl = '',
    this.openingBalance = 0,
    this.balance = 0,
    required this.createdAt,
    required this.lastTransactionAt,
  });

  PartyModel copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    double? balance,
    DateTime? lastTransactionAt,
  }) {
    return PartyModel(
      partyId: partyId,
      uid: uid,
      type: type,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      openingBalance: openingBalance,
      balance: balance ?? this.balance,
      createdAt: createdAt,
      lastTransactionAt: lastTransactionAt ?? this.lastTransactionAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partyId': partyId,
      'uid': uid,
      'type': type.name,
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'openingBalance': openingBalance,
      'balance': balance,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastTransactionAt': lastTransactionAt.millisecondsSinceEpoch,
    };
  }

  factory PartyModel.fromMap(Map<String, dynamic> map) {
    return PartyModel(
      partyId: map['partyId'] ?? '',
      uid: map['uid'] ?? '',
      type: PartyType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PartyType.customer,
      ),
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      openingBalance: (map['openingBalance'] ?? 0).toDouble(),
      balance: (map['balance'] ?? 0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      lastTransactionAt: DateTime.fromMillisecondsSinceEpoch(
        map['lastTransactionAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
