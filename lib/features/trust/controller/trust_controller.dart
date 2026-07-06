import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/features/trust/repository/trust_repository.dart';
import 'package:digiluk/models/trust_model.dart';
import 'package:digiluk/models/transaction_model.dart';
import 'package:digiluk/models/audit_log_model.dart';

final trustControllerProvider = Provider((ref) {
  final trustRepository = ref.read(trustRepositoryProvider);
  return TrustController(trustRepository: trustRepository);
});

class TrustController {
  final TrustRepository trustRepository;
  TrustController({required this.trustRepository});

  void createTrust({
    required BuildContext context,
    required String name,
    required String description,
    required TrustType type,
    required TrustSettings settings,
  }) {
    trustRepository.createTrust(
      context: context,
      name: name,
      description: description,
      type: type,
      settings: settings,
    );
  }

  Stream<List<TrustModel>> getUserTrusts(List<String> trustIds) {
    return trustRepository.getUserTrusts(trustIds);
  }

  Stream<TrustModel> getTrustData(String trustId) {
    return trustRepository.getTrustData(trustId);
  }

  Stream<List<TransactionModel>> getTransactions(String trustId) {
    return trustRepository.getTransactions(trustId);
  }

  Stream<List<AuditLogModel>> getAuditLogs(String trustId) {
    return trustRepository.getAuditLogs(trustId);
  }

  void addTransaction({
    required BuildContext context,
    required String trustId,
    required TransactionType type,
    required double amount,
    required String description,
    required String category,
    required PaymentMethod paymentMethod,
    required List<String> proofUrls,
  }) {
    trustRepository.addTransaction(
      context: context,
      trustId: trustId,
      type: type,
      amount: amount,
      description: description,
      category: category,
      paymentMethod: paymentMethod,
      proofUrls: proofUrls,
    );
  }

  void approveTransaction({
    required BuildContext context,
    required String trustId,
    required String txnId,
  }) {
    trustRepository.approveTransaction(
      context: context,
      trustId: trustId,
      txnId: txnId,
    );
  }

  void rejectTransaction({
    required BuildContext context,
    required String trustId,
    required String txnId,
  }) {
    trustRepository.rejectTransaction(
      context: context,
      trustId: trustId,
      txnId: txnId,
    );
  }

  void addMember({
    required BuildContext context,
    required String trustId,
    required String phoneNumber,
    required MemberRole role,
  }) {
    trustRepository.addMember(
      context: context,
      trustId: trustId,
      phoneNumber: phoneNumber,
      role: role,
    );
  }

  void updateMemberRole({
    required BuildContext context,
    required String trustId,
    required String memberUid,
    required MemberRole newRole,
  }) {
    trustRepository.updateMemberRole(
      context: context,
      trustId: trustId,
      memberUid: memberUid,
      newRole: newRole,
    );
  }

  void updateTrustSettings({
    required BuildContext context,
    required String trustId,
    required TrustSettings settings,
  }) {
    trustRepository.updateTrustSettings(
      context: context,
      trustId: trustId,
      settings: settings,
    );
  }
}
