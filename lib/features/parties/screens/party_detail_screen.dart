import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/cloudinary_image.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/khata/controller/khata_controller.dart';
import 'package:digiluk/features/parties/widgets/add_entry_sheet.dart';
import 'package:digiluk/features/reminders/screens/share_balance_screen.dart';
import 'package:digiluk/features/upi/screens/upi_screen.dart';
import 'package:digiluk/features/billing/screens/create_invoice_screen.dart';
import 'package:digiluk/models/khata_entry_model.dart';
import 'package:digiluk/models/party_model.dart';

class PartyDetailScreen extends ConsumerStatefulWidget {
  static const String routeName = '/party-detail';
  final String partyId;
  final String partyName;
  const PartyDetailScreen({
    super.key,
    required this.partyId,
    required this.partyName,
  });

  @override
  ConsumerState<PartyDetailScreen> createState() =>
      _PartyDetailScreenState();
}

class _PartyDetailScreenState extends ConsumerState<PartyDetailScreen> {
  void _showAddEntrySheet(KhataEntryType defaultType, PartyModel party) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddEntrySheet(
        party: party,
        partyId: widget.partyId,
        defaultType: defaultType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(khataControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.partyName),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Create Bill',
            onPressed: () => Navigator.pushNamed(
                context, CreateInvoiceScreen.routeName,
                arguments: {'partyId': widget.partyId, 'partyName': widget.partyName}),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Balance',
            onPressed: () => Navigator.pushNamed(
                context, ShareBalanceScreen.routeName,
                arguments: {'partyId': widget.partyId}),
          ),
          PopupMenuButton(
            itemBuilder: (c) => [
              const PopupMenuItem(
                value: 'upi',
                child: Row(children: [
                  Icon(Icons.qr_code, size: 20),
                  SizedBox(width: 8),
                  Text('UPI Payment'),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete, size: 20, color: digilukExpense),
                  SizedBox(width: 8),
                  Text('Delete Party',
                      style: TextStyle(color: digilukExpense)),
                ]),
              ),
            ],
            onSelected: (v) {
              if (v == 'upi') {
                Navigator.pushNamed(context, UPIScreen.routeName,
                    arguments: {'partyId': widget.partyId});
              } else if (v == 'delete') {
                ctrl.deleteParty(context, widget.partyId);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<PartyModel>(
        stream: ctrl.partyStream(widget.partyId),
        builder: (context, pSnap) {
          if (!pSnap.hasData) return const Loader();
          final party = pSnap.data!;
          final isReceive = (party.balance > 0 &&
                  party.type == PartyType.customer) ||
              (party.balance < 0 && party.type == PartyType.supplier);
          final color = isReceive ? digilukIncome : digilukExpense;
          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CloudinaryCircleAvatar(
                          imageUrl: party.photoUrl,
                          radius: 22,
                          backgroundColor: Colors.white24,
                          tapForFullScreen: true,
                          fallback: Text(
                              party.name.isNotEmpty
                                  ? party.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: digilukWhite,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        Text(party.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: digilukWhite)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isReceive ? 'You\'ll Receive' : 'You\'ll Pay',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(party.balance.abs()),
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: digilukWhite),
                    ),
                    if (party.phone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(party.phone,
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<KhataEntryModel>>(
                  stream: ctrl.getEntries(widget.partyId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Loader();
                    }
                    final entries = snap.data ?? [];
                    if (entries.isEmpty) {
                      return const EmptyState(
                        title: 'No Transactions',
                        subtitle: 'Tap Gave / Got to add entries',
                        icon: Icons.receipt_long_outlined,
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        final eIsGive = e.type == KhataEntryType.give;
                        final eColor = eIsGive ? digilukExpense : digilukIncome;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: eColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                  eIsGive ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: eColor,
                                  size: 20),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  '${eIsGive ? '+' : '-'}\u{20B9}${e.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                      color: eColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: eColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    eIsGive ? 'GAVE' : 'GOT',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: eColor),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (e.note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(e.note,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: digilukSubTextColor)),
                                  ),
                                if (e.billUrl.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(children: [
                                      const Icon(Icons.image, size: 14, color: digilukPrimary),
                                      const SizedBox(width: 4),
                                      SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: CloudinaryImage(
                                          imageUrl: e.billUrl,
                                          width: 48,
                                          height: 48,
                                          borderRadius: BorderRadius.circular(8),
                                          tapForFullScreen: true,
                                        ),
                                      ),
                                    ]),
                                  ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatDate(e.date),
                                    style: const TextStyle(
                                        fontSize: 11, color: digilukSubTextColor)),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => ctrl.deleteEntry(
                                    context,
                                    widget.partyId,
                                    e.entryId,
                                    e.type,
                                    e.amount,
                                  ),
                                  child: const Icon(Icons.delete_outline,
                                      size: 16, color: digilukSubTextColor),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'got',
            backgroundColor: digilukIncome,
            tooltip: 'Got \u{20B9}',
            onPressed: () {
              final p = ref.read(khataControllerProvider);
              p.partyStream(widget.partyId).first.then((party) {
                if (mounted) _showAddEntrySheet(KhataEntryType.receive, party);
              });
            },
            child: const Icon(Icons.add, color: digilukWhite),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            heroTag: 'gave',
            backgroundColor: digilukExpense,
            tooltip: 'Gave \u{20B9}',
            onPressed: () {
              final p = ref.read(khataControllerProvider);
              p.partyStream(widget.partyId).first.then((party) {
                if (mounted) _showAddEntrySheet(KhataEntryType.give, party);
              });
            },
            child: const Icon(Icons.remove, color: digilukWhite),
          ),
        ],
      ),
    );
  }
}
