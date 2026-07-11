import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/features/khata/repository/khata_repository.dart';
import 'package:digiluk/models/party_model.dart';
import 'package:digiluk/models/party_audit_log_model.dart';
import 'package:digiluk/models/khata_entry_model.dart';
import 'package:digiluk/models/item_model.dart';
import 'package:digiluk/models/invoice_model.dart';

final khataControllerProvider = Provider((ref) {
  final repo = ref.read(khataRepositoryProvider);
  return KhataController(repository: repo);
});

class KhataController {
  final KhataRepository repository;
  KhataController({required this.repository});

  void addParty({
    required BuildContext context,
    required PartyType type,
    required String name,
    required String phone,
    required String email,
    required double openingBalance,
    String? photoUrl,
    String category = 'shopkeeper',
    String customCategoryName = '',
    String giveLabel = '',
    String receiveLabel = '',
  }) {
    repository.addParty(
      context: context,
      type: type,
      name: name,
      phone: phone,
      email: email,
      openingBalance: openingBalance,
      photoUrl: photoUrl,
      category: category,
      customCategoryName: customCategoryName,
      giveLabel: giveLabel,
      receiveLabel: receiveLabel,
    );
  }

  void updateParty({
    required BuildContext context,
    required PartyModel oldParty,
    required String name,
    required String phone,
    required String email,
    String? photoUrl,
    required String category,
    required String customCategoryName,
    required String giveLabel,
    required String receiveLabel,
    required String editedByName,
  }) {
    repository.updateParty(
      context: context,
      oldParty: oldParty,
      name: name,
      phone: phone,
      email: email,
      photoUrl: photoUrl,
      category: category,
      customCategoryName: customCategoryName,
      giveLabel: giveLabel,
      receiveLabel: receiveLabel,
      editedByName: editedByName,
    );
  }

  Stream<List<PartyModel>> getParties(PartyType? typeFilter) =>
      repository.getParties(typeFilter);

  Stream<PartyModel> partyStream(String partyId) =>
      repository.partyStream(partyId);

  void deleteParty(BuildContext context, String partyId, String partyName, String editedByName) =>
      repository.deleteParty(
        context: context,
        partyId: partyId,
        partyName: partyName,
        editedByName: editedByName,
      );

  Stream<List<PartyAuditLogModel>> getPartyAuditLogs(String partyId) =>
      repository.getPartyAuditLogs(partyId);

  void addEntry({
    required BuildContext context,
    required String partyId,
    required KhataEntryType type,
    required double amount,
    required String note,
    String? billUrl,
  }) {
    repository.addEntry(
      context: context,
      partyId: partyId,
      type: type,
      amount: amount,
      note: note,
      billUrl: billUrl,
    );
  }

  Stream<List<KhataEntryModel>> getEntries(String partyId) =>
      repository.getEntries(partyId);

  void deleteEntry(
    BuildContext context,
    String partyId,
    String entryId,
    KhataEntryType type,
    double amount,
  ) {
    repository.deleteEntry(
      context: context,
      partyId: partyId,
      entryId: entryId,
      type: type,
      amount: amount,
    );
  }

  void addItem({
    required BuildContext context,
    required String name,
    required String unit,
    required double salePrice,
    required double purchasePrice,
    required double quantity,
    required double lowStockThreshold,
  }) {
    repository.addItem(
      context: context,
      name: name,
      unit: unit,
      salePrice: salePrice,
      purchasePrice: purchasePrice,
      quantity: quantity,
      lowStockThreshold: lowStockThreshold,
    );
  }

  Stream<List<ItemModel>> getItems() => repository.getItems();

  Future<void> updateStock(String itemId, double newQty) =>
      repository.updateStock(itemId: itemId, newQty: newQty);

  Future<void> deleteItem(String itemId) =>
      repository.deleteItem(itemId: itemId);

  void createInvoice({
    required BuildContext context,
    required String partyId,
    required String partyName,
    required InvoiceType type,
    required List<InvoiceLineItem> items,
    required double gstRate,
    required double discount,
  }) {
    repository.createInvoice(
      context: context,
      partyId: partyId,
      partyName: partyName,
      type: type,
      items: items,
      gstRate: gstRate,
      discount: discount,
    );
  }

  Stream<List<InvoiceModel>> getInvoices() => repository.getInvoices();

  Future<void> markInvoicePaid(
          String invoiceId, String partyId, double amount) =>
      repository.markInvoicePaid(
          invoiceId: invoiceId, partyId: partyId, amount: amount);
}
