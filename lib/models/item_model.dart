class ItemModel {
  final String itemId;
  final String uid;
  final String name;
  final String unit;
  final double salePrice;
  final double purchasePrice;
  final double quantity;
  final double lowStockThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemModel({
    required this.itemId,
    required this.uid,
    required this.name,
    this.unit = 'pcs',
    this.salePrice = 0,
    this.purchasePrice = 0,
    this.quantity = 0,
    this.lowStockThreshold = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  ItemModel copyWith({
    String? name,
    String? unit,
    double? salePrice,
    double? purchasePrice,
    double? quantity,
    double? lowStockThreshold,
    DateTime? updatedAt,
  }) {
    return ItemModel(
      itemId: itemId,
      uid: uid,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      salePrice: salePrice ?? this.salePrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      quantity: quantity ?? this.quantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLowStock => quantity <= lowStockThreshold;

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'uid': uid,
      'name': name,
      'unit': unit,
      'salePrice': salePrice,
      'purchasePrice': purchasePrice,
      'quantity': quantity,
      'lowStockThreshold': lowStockThreshold,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      itemId: map['itemId'] ?? '',
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      unit: map['unit'] ?? 'pcs',
      salePrice: (map['salePrice'] ?? 0).toDouble(),
      purchasePrice: (map['purchasePrice'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toDouble(),
      lowStockThreshold: (map['lowStockThreshold'] ?? 0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

class InvoiceLineItem {
  final String itemId;
  final String name;
  final double quantity;
  final double rate;
  final double total;

  InvoiceLineItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.rate,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'quantity': quantity,
      'rate': rate,
      'total': total,
    };
  }

  factory InvoiceLineItem.fromMap(Map<String, dynamic> map) {
    return InvoiceLineItem(
      itemId: map['itemId'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      rate: (map['rate'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
    );
  }
}
