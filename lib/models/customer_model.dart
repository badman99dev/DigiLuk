class CustomerModel {
  final String customerId;
  final String trustId;
  final String name;
  final String phone;
  final String email;
  final double balance;
  final DateTime createdAt;
  final DateTime lastTransactionAt;

  CustomerModel({
    required this.customerId,
    required this.trustId,
    required this.name,
    this.phone = '',
    this.email = '',
    this.balance = 0,
    required this.createdAt,
    required this.lastTransactionAt,
  });

  CustomerModel copyWith({
    String? name,
    String? phone,
    String? email,
    double? balance,
    DateTime? lastTransactionAt,
  }) {
    return CustomerModel(
      customerId: customerId,
      trustId: trustId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      balance: balance ?? this.balance,
      createdAt: createdAt,
      lastTransactionAt: lastTransactionAt ?? this.lastTransactionAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'trustId': trustId,
      'name': name,
      'phone': phone,
      'email': email,
      'balance': balance,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastTransactionAt': lastTransactionAt.millisecondsSinceEpoch,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      customerId: map['customerId'] ?? '',
      trustId: map['trustId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
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
