import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/khata/controller/khata_controller.dart';
import 'package:digiluk/models/item_model.dart';

class StockScreen extends ConsumerStatefulWidget {
  static const String routeName = '/stock';
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  void _showAddItemSheet({ItemModel? edit}) {
    final nameCtrl = TextEditingController(text: edit?.name ?? '');
    final unitCtrl = TextEditingController(text: edit?.unit ?? 'pcs');
    final saleCtrl = TextEditingController(
        text: edit != null ? edit.salePrice.toStringAsFixed(0) : '');
    final purCtrl = TextEditingController(
        text: edit != null ? edit.purchasePrice.toStringAsFixed(0) : '');
    final qtyCtrl = TextEditingController(
        text: edit != null ? edit.quantity.toStringAsFixed(0) : '0');
    final lowCtrl = TextEditingController(
        text: edit != null ? edit.lowStockThreshold.toStringAsFixed(0) : '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(edit == null ? 'Add Item' : 'Edit Item',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Item name *')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                      controller: unitCtrl,
                      decoration: const InputDecoration(labelText: 'Unit')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Quantity')),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                      controller: saleCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Sale Price', prefixText: '\u{20B9} ')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                      controller: purCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Purchase Price', prefixText: '\u{20B9} ')),
                ),
              ]),
              const SizedBox(height: 10),
              TextField(
                  controller: lowCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Low stock alert at (qty)')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) {
                      showSnackBar(context: context, content: 'Enter name');
                      return;
                    }
                    if (edit != null) {
                      ref
                          .read(khataControllerProvider)
                          .deleteItem(edit.itemId);
                    }
                    ref.read(khataControllerProvider).addItem(
                          context: context,
                          name: nameCtrl.text.trim(),
                          unit: unitCtrl.text.trim(),
                          salePrice: double.tryParse(saleCtrl.text) ?? 0,
                          purchasePrice: double.tryParse(purCtrl.text) ?? 0,
                          quantity: double.tryParse(qtyCtrl.text) ?? 0,
                          lowStockThreshold: double.tryParse(lowCtrl.text) ?? 0,
                        );
                  },
                  child: Text(edit == null ? 'Add Item' : 'Update Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(khataControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock / Inventory'),
        actions: [
          StreamBuilder<List<ItemModel>>(
            stream: ctrl.getItems(),
            builder: (context, snap) {
              final low = (snap.data ?? []).where((i) => i.isLowStock).length;
              if (low == 0) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(right: 12, top: 14),
                child: Text('$low low',
                    style: const TextStyle(
                        color: digilukExpense, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ItemModel>>(
        stream: ctrl.getItems(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No Items',
              subtitle: 'Add stock items to track inventory',
              icon: Icons.inventory_2_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final it = items[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: it.isLowStock
                        ? digilukExpense.withOpacity(0.1)
                        : digilukPrimary.withOpacity(0.1),
                    child: Icon(it.isLowStock ? Icons.warning : Icons.inventory_2,
                        color: it.isLowStock ? digilukExpense : digilukPrimary),
                  ),
                  title: Text(it.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      'Qty: ${it.quantity} ${it.unit} \u00b7 Sale \u{20B9}${it.salePrice} \u00b7 Buy \u{20B9}${it.purchasePrice}',
                      style: const TextStyle(
                          fontSize: 12, color: digilukSubTextColor)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: () => ctrl.updateStock(
                            it.itemId, it.quantity - 1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: () => ctrl.updateStock(
                            it.itemId, it.quantity + 1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _showAddItemSheet(edit: it),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemSheet(),
        backgroundColor: digilukPrimary,
        child: const Icon(Icons.add, color: digilukWhite),
      ),
    );
  }
}
