import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/features/customers/repository/customer_repository.dart';
import 'package:digiluk/models/customer_model.dart';
import 'package:digiluk/models/ledger_entry_model.dart';

final customerControllerProvider = Provider((ref) {
  final repo = ref.read(customerRepositoryProvider);
  return CustomerController(repository: repo);
});

class CustomerController {
  final CustomerRepository repository;
  CustomerController({required this.repository});

  void addCustomer({
    required BuildContext context,
    required String trustId,
    required String name,
    required String phone,
    required String email,
    required double openingBalance,
  }) {
    repository.addCustomer(
      context: context,
      trustId: trustId,
      name: name,
      phone: phone,
      email: email,
      openingBalance: openingBalance,
    );
  }

  Stream<List<CustomerModel>> getCustomers(String trustId) {
    return repository.getCustomers(trustId);
  }

  Stream<List<LedgerEntryModel>> getLedgerEntries(
      String trustId, String customerId) {
    return repository.getLedgerEntries(trustId, customerId);
  }

  void addLedgerEntry({
    required BuildContext context,
    required String trustId,
    required String customerId,
    required LedgerEntryType type,
    required double amount,
    required String note,
  }) {
    repository.addLedgerEntry(
      context: context,
      trustId: trustId,
      customerId: customerId,
      type: type,
      amount: amount,
      note: note,
    );
  }

  void deleteCustomer({
    required BuildContext context,
    required String trustId,
    required String customerId,
  }) {
    repository.deleteCustomer(
      context: context,
      trustId: trustId,
      customerId: customerId,
    );
  }
}
