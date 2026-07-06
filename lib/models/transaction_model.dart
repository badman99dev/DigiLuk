enum TransactionType { income, expense }

enum TransactionStatus { pending, approved, rejected, reversed }

enum PaymentMethod { cash, upi, bank, other }

class TransactionModel {
  final String transactionId;
  final String trustId;
  final TransactionType type;
  final double amount;
  final String description;
  final String category;
  final List<String> proofUrls;
  final TransactionStatus status;
  final String addedBy;
  final String addedByName;
  final String? approvedBy;
  final PaymentMethod paymentMethod;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final bool isRecurring;

  TransactionModel({
    required this.transactionId,
    required this.trustId,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.proofUrls,
    required this.status,
    required this.addedBy,
    required this.addedByName,
    this.approvedBy,
    required this.paymentMethod,
    required this.transactionDate,
    required this.createdAt,
    this.approvedAt,
    this.isRecurring = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'trustId': trustId,
      'type': type.name,
      'amount': amount,
      'description': description,
      'category': category,
      'proofUrls': proofUrls,
      'status': status.name,
      'addedBy': addedBy,
      'addedByName': addedByName,
      'approvedBy': approvedBy,
      'paymentMethod': paymentMethod.name,
      'transactionDate': transactionDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'approvedAt': approvedAt?.millisecondsSinceEpoch,
      'isRecurring': isRecurring,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      transactionId: map['transactionId'] ?? '',
      trustId: map['trustId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.income,
      ),
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      proofUrls: List<String>.from(map['proofUrls'] ?? []),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransactionStatus.pending,
      ),
      addedBy: map['addedBy'] ?? '',
      addedByName: map['addedByName'] ?? '',
      approvedBy: map['approvedBy'],
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      transactionDate: DateTime.fromMillisecondsSinceEpoch(
        map['transactionDate'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      approvedAt: map['approvedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['approvedAt'])
          : null,
      isRecurring: map['isRecurring'] ?? false,
    );
  }

  TransactionModel copyWith({
    TransactionStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return TransactionModel(
      transactionId: transactionId,
      trustId: trustId,
      type: type,
      amount: amount,
      description: description,
      category: category,
      proofUrls: proofUrls,
      status: status ?? this.status,
      addedBy: addedBy,
      addedByName: addedByName,
      approvedBy: approvedBy ?? this.approvedBy,
      paymentMethod: paymentMethod,
      transactionDate: transactionDate,
      createdAt: createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      isRecurring: isRecurring,
    );
  }
}
