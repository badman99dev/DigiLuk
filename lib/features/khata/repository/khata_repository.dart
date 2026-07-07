import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digiluk/common/repositories/cloudinary_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/models/party_model.dart';
import 'package:digiluk/models/khata_entry_model.dart';
import 'package:digiluk/models/item_model.dart';
import 'package:digiluk/models/invoice_model.dart';
import 'dart:io';

final khataRepositoryProvider = Provider(
  (ref) => KhataRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    cloudinary: ref.read(cloudinaryRepositoryProvider),
  ),
);

class KhataRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final CloudinaryRepository cloudinary;
  KhataRepository({
    required this.firestore,
    required this.auth,
    required this.cloudinary,
  });

  String? get _uid => auth.currentUser?.uid;
  CollectionReference _partiesCol(String uid) =>
      firestore.collection('users').doc(uid).collection('parties');
  CollectionReference _itemsCol(String uid) =>
      firestore.collection('users').doc(uid).collection('items');
  CollectionReference _invoicesCol(String uid) =>
      firestore.collection('users').doc(uid).collection('invoices');

  // ===== PARTY CRUD =====
  Future<void> addParty({
    required BuildContext context,
    required PartyType type,
    required String name,
    required String phone,
    required double openingBalance,
    File? photo,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return;
      String partyId = const Uuid().v1();
      String photoUrl = '';
      if (photo != null) {
        photoUrl = await cloudinary.uploadImage(
          photo,
          folder: 'digiluk/parties/$uid',
        );
      }
      PartyModel party = PartyModel(
        partyId: partyId,
        uid: uid,
        type: type,
        name: name,
        phone: phone,
        photoUrl: photoUrl,
        openingBalance: openingBalance,
        balance: openingBalance,
        createdAt: DateTime.now(),
        lastTransactionAt: DateTime.now(),
      );
      await _partiesCol(uid).doc(partyId).set(party.toMap());
      if (openingBalance != 0) {
        await _addEntryInternal(
          uid: uid,
          partyId: partyId,
          type: type == PartyType.customer
              ? (openingBalance > 0 ? KhataEntryType.give : KhataEntryType.receive)
              : (openingBalance > 0 ? KhataEntryType.receive : KhataEntryType.give),
          amount: openingBalance.abs(),
          note: 'Opening balance',
        );
      }
      showSnackBar(context: context, content: 'Added successfully');
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Stream<List<PartyModel>> getParties(PartyType? typeFilter) {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    var q = _partiesCol(uid).orderBy('lastTransactionAt', descending: true);
    return q.snapshots().map((event) {
      var list = event.docs
          .map((d) => PartyModel.fromMap(d.data() as Map<String, dynamic>))
          .where((p) => typeFilter == null || p.type == typeFilter)
          .toList();
      return list;
    });
  }

  Stream<PartyModel> partyStream(String partyId) {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _partiesCol(uid)
        .doc(partyId)
        .snapshots()
        .map((d) => PartyModel.fromMap(d.data() as Map<String, dynamic>));
  }

  Future<void> deleteParty({
    required BuildContext context,
    required String partyId,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return;
      var entries =
          await _partiesCol(uid).doc(partyId).collection('entries').get();
      for (var d in entries.docs) {
        await d.reference.delete();
      }
      await _partiesCol(uid).doc(partyId).delete();
      showSnackBar(context: context, content: 'Deleted');
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  // ===== KHATA ENTRY CRUD =====
  Future<void> _addEntryInternal({
    required String uid,
    required String partyId,
    required KhataEntryType type,
    required double amount,
    required String note,
    String billUrl = '',
  }) async {
    String entryId = const Uuid().v1();
    KhataEntryModel entry = KhataEntryModel(
      entryId: entryId,
      partyId: partyId,
      uid: uid,
      type: type,
      amount: amount,
      note: note,
      billUrl: billUrl,
      date: DateTime.now(),
      addedBy: uid,
    );
    await _partiesCol(uid)
        .doc(partyId)
        .collection('entries')
        .doc(entryId)
        .set(entry.toMap());
  }

  Future<void> addEntry({
    required BuildContext context,
    required String partyId,
    required KhataEntryType type,
    required double amount,
    required String note,
    File? billPhoto,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return;
      String billUrl = '';
      if (billPhoto != null) {
        billUrl = await cloudinary.uploadImage(
          billPhoto,
          folder: 'digiluk/bills/$uid/$partyId',
        );
      }
      await _addEntryInternal(
        uid: uid,
        partyId: partyId,
        type: type,
        amount: amount,
        note: note,
        billUrl: billUrl,
      );
      var pDoc = await _partiesCol(uid).doc(partyId).get();
      if (pDoc.exists) {
        double cur = (pDoc.data() as Map<String, dynamic>)['balance'] ?? 0;
        double newBal = type == KhataEntryType.give ? cur + amount : cur - amount;
        await _partiesCol(uid).doc(partyId).update({
          'balance': newBal,
          'lastTransactionAt':
              DateTime.now().millisecondsSinceEpoch,
        });
      }
      showSnackBar(context: context, content: 'Entry added');
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Stream<List<KhataEntryModel>> getEntries(String partyId) {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _partiesCol(uid)
        .doc(partyId)
        .collection('entries')
        .orderBy('date', descending: true)
        .snapshots()
        .map((event) => event.docs
            .map((d) =>
                KhataEntryModel.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> deleteEntry({
    required BuildContext context,
    required String partyId,
    required String entryId,
    required KhataEntryType type,
    required double amount,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return;
      await _partiesCol(uid)
          .doc(partyId)
          .collection('entries')
          .doc(entryId)
          .delete();
      var pDoc = await _partiesCol(uid).doc(partyId).get();
      if (pDoc.exists) {
        double cur = (pDoc.data() as Map<String, dynamic>)['balance'] ?? 0;
        double newBal = type == KhataEntryType.give ? cur - amount : cur + amount;
        await _partiesCol(uid).doc(partyId).update({'balance': newBal});
      }
      showSnackBar(context: context, content: 'Entry deleted');
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  // ===== ITEMS (STOCK) =====
  Future<void> addItem({
    required BuildContext context,
    required String name,
    required String unit,
    required double salePrice,
    required double purchasePrice,
    required double quantity,
    required double lowStockThreshold,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return;
      String id = const Uuid().v1();
      ItemModel item = ItemModel(
        itemId: id,
        uid: uid,
        name: name,
        unit: unit,
        salePrice: salePrice,
        purchasePrice: purchasePrice,
        quantity: quantity,
        lowStockThreshold: lowStockThreshold,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _itemsCol(uid).doc(id).set(item.toMap());
      showSnackBar(context: context, content: 'Item added');
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Stream<List<ItemModel>> getItems() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _itemsCol(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((event) => event.docs
            .map((d) => ItemModel.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> updateStock({
    required String itemId,
    required double newQty,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _itemsCol(uid).doc(itemId).update({
      'quantity': newQty,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteItem({required String itemId}) async {
    final uid = _uid;
    if (uid == null) return;
    await _itemsCol(uid).doc(itemId).delete();
  }

  // ===== INVOICES =====
  Future<void> createInvoice({
    required BuildContext context,
    required String partyId,
    required String partyName,
    required InvoiceType type,
    required List<InvoiceLineItem> items,
    required double gstRate,
    required double discount,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return;
      String id = const Uuid().v1();
      double subTotal =
          items.fold(0, (s, i) => s + i.total);
      double gstAmount = subTotal * gstRate / 100;
      double total = subTotal + gstAmount - discount;
      InvoiceModel inv = InvoiceModel(
        invoiceId: id,
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
        isPaid: false,
        createdAt: DateTime.now(),
      );
      await _invoicesCol(uid).doc(id).set(inv.toMap());
      if (!inv.isPaid) {
        await _addEntryInternal(
          uid: uid,
          partyId: partyId,
          type: KhataEntryType.give,
          amount: total,
          note: 'Invoice ${type.name} #${id.substring(0, 8)}',
        );
        var pDoc = await _partiesCol(uid).doc(partyId).get();
        if (pDoc.exists) {
          double cur =
              (pDoc.data() as Map<String, dynamic>)['balance'] ?? 0;
          await _partiesCol(uid).doc(partyId).update({
            'balance': cur + total,
            'lastTransactionAt':
                DateTime.now().millisecondsSinceEpoch,
          });
        }
        await _invoicesCol(uid).doc(id).update({
          'linkedEntryId': id,
        });
      }
      showSnackBar(context: context, content: 'Invoice created');
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Stream<List<InvoiceModel>> getInvoices() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _invoicesCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((event) => event.docs
            .map((d) => InvoiceModel.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> markInvoicePaid({
    required String invoiceId,
    required String partyId,
    required double amount,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _invoicesCol(uid).doc(invoiceId).update({'isPaid': true});
    await _addEntryInternal(
      uid: uid,
      partyId: partyId,
      type: KhataEntryType.receive,
      amount: amount,
      note: 'Payment for invoice #${invoiceId.substring(0, 8)}',
    );
    var pDoc = await _partiesCol(uid).doc(partyId).get();
    if (pDoc.exists) {
      double cur = (pDoc.data() as Map<String, dynamic>)['balance'] ?? 0;
      await _partiesCol(uid).doc(partyId).update({
        'balance': cur - amount,
        'lastTransactionAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
}
