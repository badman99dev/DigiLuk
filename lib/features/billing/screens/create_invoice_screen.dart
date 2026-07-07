import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/khata/controller/khata_controller.dart';
import 'package:digiluk/models/party_model.dart';
import 'package:digiluk/models/invoice_model.dart';
import 'package:digiluk/models/item_model.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  static const String routeName = '/create-invoice';
  final String partyId;
  final String partyName;
  const CreateInvoiceScreen({
    super.key,
    required this.partyId,
    required this.partyName,
  });

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  InvoiceType _type = InvoiceType.kacha;
  double _gstRate = 0;
  double _discount = 0;
  final List<InvoiceLineItem> _items = [];

  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();

  void _addItem() {
    final name = _nameCtrl.text.trim();
    final qty = double.tryParse(_qtyCtrl.text.trim());
    final rate = double.tryParse(_rateCtrl.text.trim());
    if (name.isEmpty || qty == null || rate == null || qty <= 0 || rate < 0) {
      showSnackBar(context: context, content: 'Enter valid item details');
      return;
    }
    setState(() {
      _items.add(InvoiceLineItem(
          itemId: '', name: name, quantity: qty, rate: rate, total: qty * rate));
      _nameCtrl.clear();
      _qtyCtrl.clear();
      _rateCtrl.clear();
    });
  }

  double get _subTotal => _items.fold(0, (s, i) => s + i.total);
  double get _gstAmount => _subTotal * _gstRate / 100;
  double get _total => _subTotal + _gstAmount - _discount;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _items.isEmpty
                ? null
                : () => ref.read(khataControllerProvider).createInvoice(
                      context: context,
                      partyId: widget.partyId,
                      partyName: widget.partyName,
                      type: _type,
                      items: _items,
                      gstRate: _gstRate,
                      discount: _discount,
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Party: ${widget.partyName}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: InvoiceType.values.map((t) {
                return ChoiceChip(
                  label: Text(_typeLabel(t)),
                  selected: _type == t,
                  selectedColor: digilukPrimary,
                  labelStyle: TextStyle(
                      color: _type == t ? digilukWhite : digilukTextColor),
                  onSelected: (v) => setState(() => _type = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Add Item',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(hintText: 'Item name'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: 'Qty'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _rateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: 'Rate', prefixText: '\u{20B9}'),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.add_circle, color: digilukPrimary),
                    onPressed: _addItem),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<ItemModel>>(
              stream: ref.read(khataControllerProvider).getItems(),
              builder: (context, snap) {
                final items = snap.data ?? [];
                if (items.isEmpty) return const SizedBox();
                return SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (c, i) {
                      final it = items[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text('${it.name} (\u{20B9}${it.salePrice})'),
                          onPressed: () {
                            setState(() {
                              _items.add(InvoiceLineItem(
                                  itemId: it.itemId,
                                  name: it.name,
                                  quantity: 1,
                                  rate: it.salePrice,
                                  total: it.salePrice));
                            });
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._items.asMap().entries.map((e) {
                final i = e.key;
                final it = e.value;
                return ListTile(
                  dense: true,
                  title: Text(it.name),
                  subtitle: Text(
                      '${it.quantity} x \u{20B9}${it.rate} = \u{20B9}${it.total}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _items.removeAt(i)),
                  ),
                );
              }),
              const Divider(),
              if (_type == InvoiceType.gst) ...[
                Row(
                  children: [
                    const Text('GST %: '),
                    Expanded(
                      child: Slider(
                        value: _gstRate,
                        min: 0,
                        max: 28,
                        divisions: 28,
                        label: '${_gstRate.round()}%',
                        onChanged: (v) => setState(() => _gstRate = v),
                      ),
                    ),
                    Text('${_gstRate.round()}%'),
                  ],
                ),
              ],
              Row(
                children: [
                  const Text('Discount: '),
                  Expanded(
                    child: TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(prefixText: '\u{20B9} '),
                      onChanged: (v) =>
                          setState(() => _discount = double.tryParse(v) ?? 0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _row('Subtotal', _subTotal),
              if (_gstAmount > 0) _row('GST (${_gstRate.round()}%)', _gstAmount),
              if (_discount > 0) _row('Discount', -_discount),
              const Divider(),
              _row('Total', _total, bold: true),
            ],
          ],
        ),
      ),
    );
  }

  String _typeLabel(InvoiceType t) {
    switch (t) {
      case InvoiceType.kacha:
        return 'Kacha Bill';
      case InvoiceType.pakka:
        return 'Pakka Bill';
      case InvoiceType.gst:
        return 'GST Bill';
      case InvoiceType.nonGst:
        return 'Non-GST';
    }
  }

  Widget _row(String label, double val, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(formatCurrency(val),
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 17 : 15,
                  color: bold ? digilukPrimary : digilukTextColor)),
        ],
      ),
    );
  }
}

class InvoiceListScreen extends ConsumerWidget {
  static const String routeName = '/invoices';
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.watch(khataControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: StreamBuilder<List<InvoiceModel>>(
        stream: ctrl.getInvoices(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const EmptyState(
              title: 'No Invoices',
              subtitle: 'Create invoices from party detail screen',
              icon: Icons.receipt_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final inv = list[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: inv.isPaid
                        ? digilukIncome.withOpacity(0.1)
                        : digilukExpense.withOpacity(0.1),
                    child: Icon(inv.isPaid ? Icons.check : Icons.pending,
                        color: inv.isPaid ? digilukIncome : digilukExpense),
                  ),
                  title: Text('${inv.partyName} \u00b7 ${inv.type.name}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${formatDate(inv.createdAt)} \u00b7 ${inv.items.length} items',
                      style: const TextStyle(
                          fontSize: 12, color: digilukSubTextColor)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatCurrency(inv.total),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      if (!inv.isPaid)
                        GestureDetector(
                          onTap: () => ctrl.markInvoicePaid(
                              inv.invoiceId, inv.partyId, inv.total),
                          child: const Text('Mark Paid',
                              style: TextStyle(
                                  fontSize: 11, color: digilukIncome)),
                        )
                      else
                        const Text('PAID',
                            style:
                                TextStyle(fontSize: 11, color: digilukIncome)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
