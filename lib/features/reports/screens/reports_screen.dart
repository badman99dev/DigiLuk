import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/khata/controller/khata_controller.dart';
import 'package:digiluk/models/party_model.dart';
import 'package:digiluk/models/khata_entry_model.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  static const String routeName = '/reports';
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
        start: DateTime(now.year, now.month, 1), end: now);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(khataControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final r = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: _range,
                      );
                      if (r != null) setState(() => _range = r);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: digilukDividerColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.date_range, color: digilukPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${formatDate(_range!.start)} - ${formatDate(_range!.end)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down,
                            color: digilukSubTextColor),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _exportPdf(ctrl),
                  icon: const Icon(Icons.picture_as_pdf, color: digilukWhite),
                  label: const Text('PDF',
                      style: TextStyle(color: digilukWhite)),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PartyModel>>(
              stream: ctrl.getParties(null),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Loader();
                }
                final parties = snap.data ?? [];
                if (parties.isEmpty) {
                  return const EmptyState(
                    title: 'No Data',
                    subtitle: 'Add parties and transactions to see reports',
                    icon: Icons.bar_chart_outlined,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: parties.length,
                  itemBuilder: (context, i) {
                    final p = parties[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                            backgroundColor: digilukPrimary.withOpacity(0.1),
                            child: Text(
                                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: digilukPrimary))),
                        title: Text(p.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(formatCurrency(p.balance),
                            style: TextStyle(
                                fontSize: 12,
                                color: p.balance > 0
                                    ? digilukIncome
                                    : (p.balance < 0 ? digilukExpense : digilukSubTextColor))),
                        children: [
                          StreamBuilder<List<KhataEntryModel>>(
                            stream: ctrl.getEntries(p.partyId),
                            builder: (context, eSnap) {
                              final entries = (eSnap.data ?? [])
                                  .where((e) =>
                                      !e.date.isBefore(_range!.start) &&
                                      !e.date.isAfter(_range!.end
                                          .add(const Duration(days: 1))))
                                  .toList();
                              if (entries.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No entries in this range',
                                      style: TextStyle(
                                          color: digilukSubTextColor,
                                          fontSize: 13)),
                                );
                              }
                              double give = 0, receive = 0;
                              for (var e in entries) {
                                if (e.type == KhataEntryType.give) {
                                  give += e.amount;
                                } else {
                                  receive += e.amount;
                                }
                              }
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Row(
                                      children: [
                                        _miniStat('Gave', give, digilukExpense),
                                        const SizedBox(width: 10),
                                        _miniStat('Got', receive, digilukIncome),
                                      ],
                                    ),
                                  ),
                                  ...entries.map((e) {
                                    final isGive =
                                        e.type == KhataEntryType.give;
                                    final color = isGive
                                        ? digilukExpense
                                        : digilukIncome;
                                    return ListTile(
                                      dense: true,
                                      leading: Icon(
                                          isGive
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          color: color,
                                          size: 18),
                                      title: Text(
                                          '${isGive ? '+' : '-'}\u{20B9}${e.amount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.w600)),
                                      subtitle: Text(e.note.isEmpty ? 'No note' : e.note,
                                          style: const TextStyle(fontSize: 12)),
                                      trailing: Text(formatDate(e.date),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: digilukSubTextColor)),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: digilukSubTextColor)),
            Text(formatCurrency(val),
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf(KhataController ctrl) async {
    final parties = await ctrl.getParties(null).first;
    final doc = pw.Document();
    double totalGive = 0, totalReceive = 0;

    final rows = <List<String>>[];
    for (var p in parties) {
      final entries = await ctrl.getEntries(p.partyId).first;
      final filtered = entries
          .where((e) =>
              !e.date.isBefore(_range!.start) &&
              !e.date.isAfter(_range!.end.add(const Duration(days: 1))))
          .toList();
      for (var e in filtered) {
        if (e.type == KhataEntryType.give) {
          totalGive += e.amount;
        } else {
          totalReceive += e.amount;
        }
        rows.add([
          p.name,
          e.type == KhataEntryType.give ? 'Gave' : 'Got',
          '\u{20B9}${e.amount.toStringAsFixed(0)}',
          e.note.isEmpty ? '-' : e.note,
          formatDate(e.date),
        ]);
      }
    }

    doc.addPage(
      pw.Page(
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('DigiLuk Report',
                style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(
                'Period: ${formatDate(_range!.start)} to ${formatDate(_range!.end)}',
                style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                pw.Expanded(
                    child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        color: PdfColors.green50,
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Total Gave',
                                  style: const pw.TextStyle(fontSize: 10)),
                              pw.Text('\u{20B9}${totalGive.toStringAsFixed(0)}',
                                  style: pw.TextStyle(
                                      fontSize: 16,
                                      fontWeight: pw.FontWeight.bold)),
                            ]))),
                pw.SizedBox(width: 8),
                pw.Expanded(
                    child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        color: PdfColors.red50,
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Total Got',
                                  style: const pw.TextStyle(fontSize: 10)),
                              pw.Text('\u{20B9}${totalReceive.toStringAsFixed(0)}',
                                  style: pw.TextStyle(
                                      fontSize: 16,
                                      fontWeight: pw.FontWeight.bold)),
                            ]))),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Party', 'Type', 'Amount', 'Note', 'Date'],
              data: rows,
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(6),
            ),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/digiluk_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await doc.save());
    Share.shareXFiles([XFile(file.path)], text: 'DigiLuk Report');
  }
}
