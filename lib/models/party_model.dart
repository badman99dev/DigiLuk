enum PartyType { customer, supplier }

class PartyCategory {
  final String id;
  final String displayName;
  final String giveLabel;
  final String receiveLabel;
  final String receiveTitle;
  final String payTitle;
  final String balanceDueLabel;

  const PartyCategory({
    required this.id,
    required this.displayName,
    required this.giveLabel,
    required this.receiveLabel,
    this.receiveTitle = 'You\'ll Receive',
    this.payTitle = 'You\'ll Pay',
    this.balanceDueLabel = 'Balance Due',
  });

  static const List<PartyCategory> defaults = [
    PartyCategory(
      id: 'shopkeeper',
      displayName: 'Shopkeeper',
      giveLabel: 'Gave',
      receiveLabel: 'Got',
      receiveTitle: 'You\'ll Receive',
      payTitle: 'You\'ll Pay',
      balanceDueLabel: 'Balance Due',
    ),
    PartyCategory(
      id: 'student',
      displayName: 'Coaching Student',
      giveLabel: 'Add Fee',
      receiveLabel: 'Fee Received',
      receiveTitle: 'Fee Due',
      payTitle: 'Fee Advance',
      balanceDueLabel: 'Fee Due',
    ),
    PartyCategory(
      id: 'tenant',
      displayName: 'Tenant',
      giveLabel: 'Add Rent',
      receiveLabel: 'Rent Received',
      receiveTitle: 'Rent Due',
      payTitle: 'Rent Advance',
      balanceDueLabel: 'Rent Due',
    ),
    PartyCategory(
      id: 'lender',
      displayName: 'Lender',
      giveLabel: 'Give Loan',
      receiveLabel: 'Loan Received',
      receiveTitle: 'Loan to Receive',
      payTitle: 'Loan to Pay',
      balanceDueLabel: 'Loan Due',
    ),
    PartyCategory(
      id: 'freelancer',
      displayName: 'Freelancer / Service',
      giveLabel: 'Add Bill',
      receiveLabel: 'Payment Received',
      receiveTitle: 'Payment Due',
      payTitle: 'Advance Paid',
      balanceDueLabel: 'Payment Due',
    ),
    PartyCategory(
      id: 'custom',
      displayName: 'Custom',
      giveLabel: 'Gave',
      receiveLabel: 'Got',
      receiveTitle: 'You\'ll Receive',
      payTitle: 'You\'ll Pay',
      balanceDueLabel: 'Balance Due',
    ),
  ];

  static PartyCategory getById(String id) {
    return defaults.firstWhere(
      (c) => c.id == id,
      orElse: () => defaults.first,
    );
  }

  PartyCategory copyWith({
    String? giveLabel,
    String? receiveLabel,
    String? receiveTitle,
    String? payTitle,
    String? balanceDueLabel,
  }) {
    return PartyCategory(
      id: id,
      displayName: displayName,
      giveLabel: giveLabel ?? this.giveLabel,
      receiveLabel: receiveLabel ?? this.receiveLabel,
      receiveTitle: receiveTitle ?? this.receiveTitle,
      payTitle: payTitle ?? this.payTitle,
      balanceDueLabel: balanceDueLabel ?? this.balanceDueLabel,
    );
  }
}

class PartyModel {
  final String partyId;
  final String uid;
  final PartyType type;
  final String name;
  final String phone;
  final String email;
  final String photoUrl;
  final String category;
  final String customCategoryName;
  final String giveLabel;
  final String receiveLabel;
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
    this.email = '',
    this.photoUrl = '',
    this.category = 'shopkeeper',
    this.customCategoryName = '',
    this.giveLabel = '',
    this.receiveLabel = '',
    this.openingBalance = 0,
    this.balance = 0,
    required this.createdAt,
    required this.lastTransactionAt,
  });

  PartyCategory get resolvedCategory {
    final base = PartyCategory.getById(category);
    if (category == 'custom' && customCategoryName.isNotEmpty) {
      return base.copyWith(
        displayName: customCategoryName,
        giveLabel: giveLabel.isNotEmpty ? giveLabel : base.giveLabel,
        receiveLabel: receiveLabel.isNotEmpty ? receiveLabel : base.receiveLabel,
      );
    }
    return base;
  }

  PartyModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? photoUrl,
    String? category,
    String? customCategoryName,
    String? giveLabel,
    String? receiveLabel,
    double? balance,
    DateTime? lastTransactionAt,
  }) {
    return PartyModel(
      partyId: partyId,
      uid: uid,
      type: type,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      category: category ?? this.category,
      customCategoryName: customCategoryName ?? this.customCategoryName,
      giveLabel: giveLabel ?? this.giveLabel,
      receiveLabel: receiveLabel ?? this.receiveLabel,
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
      'email': email,
      'photoUrl': photoUrl,
      'category': category,
      'customCategoryName': customCategoryName,
      'giveLabel': giveLabel,
      'receiveLabel': receiveLabel,
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
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      category: map['category'] ?? 'shopkeeper',
      customCategoryName: map['customCategoryName'] ?? '',
      giveLabel: map['giveLabel'] ?? '',
      receiveLabel: map['receiveLabel'] ?? '',
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
