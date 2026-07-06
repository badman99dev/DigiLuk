import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/models/customer_model.dart';
import 'package:digiluk/models/ledger_entry_model.dart';

final customerRepositoryProvider = Provider(
  (ref) => CustomerRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  ),
);

class CustomerRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  CustomerRepository({required this.firestore, required this.auth});

  CollectionReference get _trusts => firestore.collection('trusts');

  Future<Map<String, dynamic>> _getUserData(String uid) async {
    var userDoc = await firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }
    return {};
  }

  Future<void> addCustomer({
    required BuildContext context,
    required String trustId,
    required String name,
    required String phone,
    required String email,
    required double openingBalance,
  }) async {
    try {
      String customerId = const Uuid().v1();
      CustomerModel customer = CustomerModel(
        customerId: customerId,
        trustId: trustId,
        name: name,
        phone: phone,
        email: email,
        balance: openingBalance,
        createdAt: DateTime.now(),
        lastTransactionAt: DateTime.now(),
      );

      await _trusts
          .doc(trustId)
          .collection('customers')
          .doc(customerId)
          .set(customer.toMap());

      if (openingBalance != 0) {
        await _addLedgerEntry(
          trustId: trustId,
          customerId: customerId,
          type: openingBalance > 0
              ? LedgerEntryType.udhaar
              : LedgerEntryType.payment,
          amount: openingBalance.abs(),
          note: 'Opening balance',
        );
      }

      showSnackBar(context: context, content: 'Customer added successfully');
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Stream<List<CustomerModel>> getCustomers(String trustId) {
    return _trusts
        .doc(trustId)
        .collection('customers')
        .orderBy('lastTransactionAt', descending: true)
        .snapshots()
        .map(
          (event) => event.docs
              .map((doc) =>
                  CustomerModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  Stream<List<LedgerEntryModel>> getLedgerEntries(
      String trustId, String customerId) {
    return _trusts
        .doc(trustId)
        .collection('customers')
        .doc(customerId)
        .collection('entries')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (event) => event.docs
              .map((doc) => LedgerEntryModel.fromMap(
                  doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  Future<void> addLedgerEntry({
    required BuildContext context,
    required String trustId,
    required String customerId,
    required LedgerEntryType type,
    required double amount,
    required String note,
  }) async {
    try {
      await _addLedgerEntry(
        trustId: trustId,
        customerId: customerId,
        type: type,
        amount: amount,
        note: note,
      );

      var custDoc = await _trusts
          .doc(trustId)
          .collection('customers')
          .doc(customerId)
          .get();
      if (custDoc.exists) {
        Map<String, dynamic> data = custDoc.data() as Map<String, dynamic>;
        double currentBalance = (data['balance'] ?? 0).toDouble();
        double newBalance = type == LedgerEntryType.udhaar
            ? currentBalance + amount
            : currentBalance - amount;
        await _trusts
            .doc(trustId)
            .collection('customers')
            .doc(customerId)
            .update({
          'balance': newBalance,
          'lastTransactionAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      showSnackBar(context: context, content: 'Entry added successfully');
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Future<void> _addLedgerEntry({
    required String trustId,
    required String customerId,
    required LedgerEntryType type,
    required double amount,
    required String note,
  }) async {
    String uid = auth.currentUser!.uid;
    var userData = await _getUserData(uid);
    String userName = userData['name'] ?? '';

    String entryId = const Uuid().v1();
    LedgerEntryModel entry = LedgerEntryModel(
      entryId: entryId,
      customerId: customerId,
      trustId: trustId,
      type: type,
      amount: amount,
      note: note,
      date: DateTime.now(),
      addedBy: uid,
      addedByName: userName,
    );

    await _trusts
        .doc(trustId)
        .collection('customers')
        .doc(customerId)
        .collection('entries')
        .doc(entryId)
        .set(entry.toMap());
  }

  Future<void> deleteCustomer({
    required BuildContext context,
    required String trustId,
    required String customerId,
  }) async {
    try {
      var entries = await _trusts
          .doc(trustId)
          .collection('customers')
          .doc(customerId)
          .collection('entries')
          .get();
      for (var doc in entries.docs) {
        await doc.reference.delete();
      }
      await _trusts
          .doc(trustId)
          .collection('customers')
          .doc(customerId)
          .delete();
      showSnackBar(context: context, content: 'Customer deleted');
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }
}
