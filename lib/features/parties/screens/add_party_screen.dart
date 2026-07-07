import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/features/khata/controller/khata_controller.dart';
import 'package:digiluk/models/party_model.dart';

class AddPartyScreen extends ConsumerStatefulWidget {
  static const String routeName = '/add-party';
  final PartyType initialType;
  const AddPartyScreen({super.key, this.initialType = PartyType.customer});

  @override
  ConsumerState<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends ConsumerState<AddPartyScreen> {
  late PartyType _type = widget.initialType;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  File? _photo;
  bool _openingReceive = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showSnackBar(context: context, content: 'Enter name');
      return;
    }
    double bal = double.tryParse(_balanceCtrl.text.trim()) ?? 0;
    double signed = _openingReceive ? bal.abs() : -bal.abs();
    ref.read(khataControllerProvider).addParty(
          context: context,
          type: _type,
          name: name,
          phone: _phoneCtrl.text.trim(),
          openingBalance: signed,
          photo: _photo,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_type == PartyType.customer ? 'Add Customer' : 'Add Supplier'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Customer'),
                    selected: _type == PartyType.customer,
                    selectedColor: digilukPrimary,
                    labelStyle: TextStyle(
                        color: _type == PartyType.customer
                            ? digilukWhite
                            : digilukTextColor),
                    onSelected: (v) => setState(() => _type = PartyType.customer),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Supplier'),
                    selected: _type == PartyType.supplier,
                    selectedColor: digilukAccent,
                    labelStyle: TextStyle(
                        color: _type == PartyType.supplier
                            ? digilukWhite
                            : digilukTextColor),
                    onSelected: (v) => setState(() => _type = PartyType.supplier),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () async {
                  final img = await pickImageFromGallery(context);
                  if (img != null) setState(() => _photo = img);
                },
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: digilukPrimary.withOpacity(0.12),
                  backgroundImage: _photo != null ? FileImage(_photo!) : null,
                  child: _photo == null
                      ? const Icon(Icons.camera_alt, color: digilukPrimary)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'Enter name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                hintText: 'Enter phone number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _balanceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Opening Balance (optional)',
                hintText: '0',
                prefixText: '\u{20B9} ',
                prefixStyle: const TextStyle(
                    fontWeight: FontWeight.bold, color: digilukPrimary),
              ),
            ),
            const SizedBox(height: 12),
            if ((_balanceCtrl.text.trim().isNotEmpty) &&
                double.tryParse(_balanceCtrl.text.trim()) != null &&
                double.parse(_balanceCtrl.text.trim()) > 0)
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(_type == PartyType.customer
                          ? 'They owe me'
                          : 'I owe them'),
                      selected: _openingReceive,
                      selectedColor: digilukIncome,
                      labelStyle: TextStyle(
                          color: _openingReceive
                              ? digilukWhite
                              : digilukTextColor),
                      onSelected: (v) =>
                          setState(() => _openingReceive = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(_type == PartyType.customer
                          ? 'I owe them'
                          : 'They owe me'),
                      selected: !_openingReceive,
                      selectedColor: digilukExpense,
                      labelStyle: TextStyle(
                          color: !_openingReceive
                              ? digilukWhite
                              : digilukTextColor),
                      onSelected: (v) =>
                          setState(() => _openingReceive = false),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('Save',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
