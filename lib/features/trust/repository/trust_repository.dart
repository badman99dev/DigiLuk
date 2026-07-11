import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/models/trust_model.dart';
import 'package:digiluk/models/transaction_model.dart';
import 'package:digiluk/models/audit_log_model.dart';

final trustRepositoryProvider = Provider(
  (ref) => TrustRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  ),
);

class TrustRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  TrustRepository({required this.firestore, required this.auth});

  CollectionReference get _trusts => firestore.collection('trusts');
  CollectionReference get _users => firestore.collection('users');

  Future<Map<String, dynamic>> _getUserData(String uid) async {
    var userDoc = await _users.doc(uid).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }
    return {};
  }

  Future<void> createTrust({
    required BuildContext context,
    required String name,
    required String description,
    required TrustType type,
    required TrustSettings settings,
  }) async {
    try {
      String uid = auth.currentUser!.uid;
      String phone = auth.currentUser!.phoneNumber ?? '';
      var userData = await _getUserData(uid);
      String userName = userData['name'] ?? '';

      String trustId = const Uuid().v1();

      TrustModel trust = TrustModel(
        trustId: trustId,
        name: name,
        description: description,
        type: type,
        createdBy: userName,
        createdByUid: uid,
        createdAt: DateTime.now(),
        members: [
          TrustMember(
            uid: uid,
            name: userName,
            phoneNumber: phone,
            profilePic: userData['profilePic'] ?? '',
            role: MemberRole.creator,
            joinedAt: DateTime.now(),
          ),
        ],
        settings: settings,
      );

      await _trusts.doc(trustId).set(trust.toMap());
      await _users.doc(uid).update({
        'trustIds': FieldValue.arrayUnion([trustId]),
      });

      await _addAuditLog(
        trustId: trustId,
        action: AuditAction.trustCreated,
        performedBy: uid,
        performedByName: userName,
        details: 'Group "$name" created',
      );

      showSnackBar(context: context, content: 'Group created successfully');
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Stream<List<TrustModel>> getUserTrusts(List<String> trustIds) {
    final uid = auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _trusts.where('memberUids', arrayContains: uid).snapshots().map(
          (event) => event.docs
              .map((doc) =>
                  TrustModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  Stream<TrustModel> getTrustData(String trustId) {
    return _trusts.doc(trustId).snapshots().map(
          (event) =>
              TrustModel.fromMap(event.data() as Map<String, dynamic>),
        );
  }

  Stream<List<TransactionModel>> getTransactions(String trustId) {
    return _trusts
        .doc(trustId)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (event) => event.docs
              .map((doc) => TransactionModel.fromMap(
                  doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  Stream<List<AuditLogModel>> getAuditLogs(String trustId) {
    return _trusts
        .doc(trustId)
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (event) => event.docs
              .map((doc) => AuditLogModel.fromMap(
                  doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  Future<void> addTransaction({
    required BuildContext context,
    required String trustId,
    required TransactionType type,
    required double amount,
    required String description,
    required String category,
    required PaymentMethod paymentMethod,
    required List<String> proofUrls,
  }) async {
    try {
      String uid = auth.currentUser!.uid;
      var userData = await _getUserData(uid);
      String userName = userData['name'] ?? '';

      var trustDoc = await _trusts.doc(trustId).get();
      TrustModel trust =
          TrustModel.fromMap(trustDoc.data() as Map<String, dynamic>);
      bool requireApproval = trust.settings.requireApproval;

      String txnId = const Uuid().v1();

      TransactionModel txn = TransactionModel(
        transactionId: txnId,
        trustId: trustId,
        type: type,
        amount: amount,
        description: description,
        category: category,
        proofUrls: proofUrls,
        status: requireApproval && type == TransactionType.expense
            ? TransactionStatus.pending
            : TransactionStatus.approved,
        addedBy: uid,
        addedByName: userName,
        paymentMethod: paymentMethod,
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _trusts
          .doc(trustId)
          .collection('transactions')
          .doc(txnId)
          .set(txn.toMap());

      if (txn.status == TransactionStatus.approved) {
        await _updateTrustBalance(trustId, type, amount);
      }

      await _addAuditLog(
        trustId: trustId,
        action: AuditAction.transactionAdded,
        performedBy: uid,
        performedByName: userName,
        details: '${type.name}: \u{20B9}$amount - $description',
        targetDoc: txnId,
      );

      showSnackBar(context: context, content: 'Transaction added successfully');
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Future<void> approveTransaction({
    required BuildContext context,
    required String trustId,
    required String txnId,
  }) async {
    try {
      String uid = auth.currentUser!.uid;
      var userData = await _getUserData(uid);
      String userName = userData['name'] ?? '';

      var txnDoc = await _trusts
          .doc(trustId)
          .collection('transactions')
          .doc(txnId)
          .get();
      TransactionModel txn =
          TransactionModel.fromMap(txnDoc.data() as Map<String, dynamic>);

      await _trusts.doc(trustId).collection('transactions').doc(txnId).update({
        'status': TransactionStatus.approved.name,
        'approvedBy': uid,
        'approvedAt': DateTime.now().millisecondsSinceEpoch,
      });

      await _updateTrustBalance(trustId, txn.type, txn.amount);

      await _addAuditLog(
        trustId: trustId,
        action: AuditAction.transactionApproved,
        performedBy: uid,
        performedByName: userName,
        details: 'Approved: \u{20B9}${txn.amount} - ${txn.description}',
        targetDoc: txnId,
      );

      showSnackBar(context: context, content: 'Transaction approved');
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Future<void> rejectTransaction({
    required BuildContext context,
    required String trustId,
    required String txnId,
  }) async {
    try {
      String uid = auth.currentUser!.uid;
      var userData = await _getUserData(uid);
      String userName = userData['name'] ?? '';

      await _trusts.doc(trustId).collection('transactions').doc(txnId).update({
        'status': TransactionStatus.rejected.name,
        'approvedBy': uid,
        'approvedAt': DateTime.now().millisecondsSinceEpoch,
      });

      await _addAuditLog(
        trustId: trustId,
        action: AuditAction.transactionRejected,
        performedBy: uid,
        performedByName: userName,
        details: 'Rejected transaction $txnId',
        targetDoc: txnId,
      );

      showSnackBar(context: context, content: 'Transaction rejected');
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Future<Map<String, dynamic>?> searchUserByEmail(String email) async {
    try {
      var query = await _users.where('email', isEqualTo: email).limit(1).get();
      if (query.docs.isEmpty) return null;
      return query.docs[0].data() as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Search user error: $e');
      return null;
    }
  }

  Future<void> addMemberByEmail({
    required BuildContext context,
    required String trustId,
    required String email,
    required MemberRole role,
  }) async {
    try {
      String uid = auth.currentUser!.uid;
      var userData = await _getUserData(uid);
      String userName = userData['name'] ?? '';

      var userQuery = await _users
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        showSnackBar(
          context: context,
          content: 'User not found. Ask them to install DigiLuk first.',
        );
        return;
      }

      var newUserData =
          userQuery.docs[0].data() as Map<String, dynamic>;
      String newUid = newUserData['uid'] ?? '';
      String newName = newUserData['name'] ?? '';
      String newPic = newUserData['profilePic'] ?? '';
      String newEmail = newUserData['email'] ?? '';
      String newPhone = newUserData['phoneNumber'] ?? '';

      var trustDoc = await _trusts.doc(trustId).get();
      TrustModel trust =
          TrustModel.fromMap(trustDoc.data() as Map<String, dynamic>);

      if (trust.members.any((m) => m.uid == newUid)) {
        showSnackBar(context: context, content: 'User is already a member');
        return;
      }

      TrustMember newMember = TrustMember(
        uid: newUid,
        name: newName,
        email: newEmail,
        phoneNumber: newPhone,
        profilePic: newPic,
        role: role,
        joinedAt: DateTime.now(),
      );

      List<Map<String, dynamic>> membersMap =
          trust.members.map((m) => m.toMap()).toList();
      membersMap.add(newMember.toMap());

      final memberUids = [...trust.memberUids, newUid];
      final managerUids = role == MemberRole.manager
          ? [...trust.managerUids, newUid]
          : trust.managerUids;

      await _trusts.doc(trustId).update({
        'members': membersMap,
        'memberUids': memberUids,
        'managerUids': managerUids,
      });
      await _users.doc(newUid).update({
        'trustIds': FieldValue.arrayUnion([trustId]),
      });

      await _addAuditLog(
        trustId: trustId,
        action: AuditAction.memberAdded,
        performedBy: uid,
        performedByName: userName,
        details: 'Added $newName as ${role.name}',
      );

      showSnackBar(context: context, content: 'Member added successfully');
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Future<void> updateMemberRole({
    required BuildContext context,
    required String trustId,
    required String memberUid,
    required MemberRole newRole,
  }) async {
    try {
      String uid = auth.currentUser!.uid;
      var userData = await _getUserData(uid);
      String userName = userData['name'] ?? '';

      var trustDoc = await _trusts.doc(trustId).get();
      TrustModel trust =
          TrustModel.fromMap(trustDoc.data() as Map<String, dynamic>);

      List<Map<String, dynamic>> membersMap = trust.members.map((m) {
        if (m.uid == memberUid) {
          return TrustMember(
            uid: m.uid,
            name: m.name,
            phoneNumber: m.phoneNumber,
            profilePic: m.profilePic,
            role: newRole,
            joinedAt: m.joinedAt,
          ).toMap();
        }
        return m.toMap();
      }).toList();

      var managerUids = trust.managerUids;
      if (newRole == MemberRole.manager && !managerUids.contains(memberUid)) {
        managerUids = [...managerUids, memberUid];
      } else if (newRole == MemberRole.member && managerUids.contains(memberUid)) {
        managerUids = managerUids.where((uid) => uid != memberUid).toList();
      }

      await _trusts.doc(trustId).update({
        'members': membersMap,
        'managerUids': managerUids,
      });

      await _addAuditLog(
        trustId: trustId,
        action: newRole == MemberRole.manager
            ? AuditAction.memberPromoted
            : AuditAction.memberDemoted,
        performedBy: uid,
        performedByName: userName,
        details: 'Role changed to ${newRole.name}',
      );

      showSnackBar(context: context, content: 'Role updated');
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Future<void> updateTrustSettings({
    required BuildContext context,
    required String trustId,
    required TrustSettings settings,
  }) async {
    try {
      String uid = auth.currentUser!.uid;
      var userData = await _getUserData(uid);
      String userName = userData['name'] ?? '';

      await _trusts.doc(trustId).update({'settings': settings.toMap()});

      await _addAuditLog(
        trustId: trustId,
        action: AuditAction.settingsUpdated,
        performedBy: uid,
        performedByName: userName,
        details: 'Group settings updated',
      );

      showSnackBar(context: context, content: 'Settings updated');
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Future<void> _updateTrustBalance(
    String trustId,
    TransactionType type,
    double amount,
  ) async {
    var trustDoc = await _trusts.doc(trustId).get();
    if (trustDoc.exists) {
      Map<String, dynamic> data = trustDoc.data() as Map<String, dynamic>;
      double currentBalance = (data['totalBalance'] ?? 0).toDouble();
      double newBalance = type == TransactionType.income
          ? currentBalance + amount
          : currentBalance - amount;
      await _trusts.doc(trustId).update({'totalBalance': newBalance});
    }
  }

  Future<void> _addAuditLog({
    required String trustId,
    required AuditAction action,
    required String performedBy,
    required String performedByName,
    String targetDoc = '',
    String details = '',
  }) async {
    String logId = const Uuid().v1();
    AuditLogModel log = AuditLogModel(
      logId: logId,
      trustId: trustId,
      action: action,
      performedBy: performedBy,
      performedByName: performedByName,
      timestamp: DateTime.now(),
      targetDoc: targetDoc,
      details: details,
    );
    await _trusts.doc(trustId).collection('logs').doc(logId).set(log.toMap());
  }
}
