import 'item_model.dart';

enum InvoiceType { kacha, pakka, gst, nonGst }

class InvoiceModel {
  final String invoiceId;
  final String uid;
  final String partyId;
  final String partyName;
  final InvoiceType type;
  final List<InvoiceLineItem> items;
  final double subTotal;
  final double gstRate;
  final double gstAmount;
  final double discount;
  final double total;
  final bool isPaid;
  final DateTime? dueDate;
  final DateTime createdAt;
  final String? linkedEntryId;

  InvoiceModel({
    required this.invoiceId,
    required this.uid,
    required this.partyId,
    required this.partyName,
    required this.type,
    required this.items,
    this.subTotal = 0,
    this.gstRate = 0,
    this.gstAmount = 0,
    this.discount = 0,
    this.total = 0,
    this.isPaid = false,
    this.dueDate,
    required this.createdAt,
    this.linkedEntryId,
  });

  InvoiceModel copyWith({
    bool? isPaid,
    String? linkedEntryId,
  }) {
    return InvoiceModel(
      invoiceId: invoiceId,
      uid: uid,
      partyId: partyId,
      partyName: partyName,
      type: type,
      items: items,
      subTotal: subTotal,
      gstRate: gstRate,
      gstAmount: gstAmount,
      discount: discount,
      total: total,
      isPaid: isPaid ?? this.isPaid,
      dueDate: dueDate,
      createdAt: createdAt,
      linkedEntryId: linkedEntryId ?? this.linkedEntryId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'uid': uid,
      'partyId': partyId,
      'partyName': partyName,
      'type': type.name,
      'items': items.map((i) => i.toMap()).toList(),
      'subTotal': subTotal,
      'gstRate': gstRate,
      'gstAmount': gstAmount,
      'discount': discount,
      'total': total,
      'isPaid': isPaid,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'linkedEntryId': linkedEntryId,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      invoiceId: map['invoiceId'] ?? '',
      uid: map['uid'] ?? '',
      partyId: map['partyId'] ?? '',
      partyName: map['partyName'] ?? '',
      type: InvoiceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InvoiceType.kacha,
      ),
      items: (map['items'] as List<dynamic>?)
              ?.map((i) => InvoiceLineItem.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
      subTotal: (map['subTotal'] ?? 0).toDouble(),
      gstRate: (map['gstRate'] ?? 0).toDouble(),
      gstAmount: (map['gstAmount'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      isPaid: map['isPaid'] ?? false,
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      linkedEntryId: map['linkedEntryId'],
    );
  }
}
