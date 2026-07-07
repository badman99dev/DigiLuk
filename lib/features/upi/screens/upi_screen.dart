import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/khata/controller/khata_controller.dart';
import 'package:digiluk/features/auth/controller/auth_controller.dart';
import 'package:digiluk/models/party_model.dart';

class UPIScreen extends ConsumerStatefulWidget {
  static const String routeName = '/upi';
  final String partyId;
  const UPIScreen({super.key, required this.partyId});

  @override
  ConsumerState<UPIScreen> createState() => _UPIScreenState();
}

class _UPIScreenState extends ConsumerState<UPIScreen> {
  final _upiIdCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _upiIdCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _buildUpiUrl(String upiId, double amount, String note, String name) {
    return 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(name)}'
        '&am=${amount.toStringAsFixed(2)}&tn=${Uri.encodeComponent(note)}';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(khataControllerProvider);
    final userAsync = ref.watch(userDataAuthProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('UPI Payment')),
      body: userAsync.when(
        data: (user) {
          return StreamBuilder<PartyModel>(
            stream: ctrl.partyStream(widget.partyId),
            builder: (context, snap) {
              if (!snap.hasData) return const Loader();
              final party = snap.data!;
              final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
              final note = _noteCtrl.text.trim().isEmpty
                  ? 'DigiLuk payment to ${party.name}'
                  : _noteCtrl.text.trim();
              final upiId = _upiIdCtrl.text.trim();
              final upiUrl = upiId.isNotEmpty
                  ? _buildUpiUrl(upiId, amount, note, user?.name ?? 'DigiLuk')
                  : '';
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: digilukPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          const Text('Receive from',
                              style: TextStyle(
                                  fontSize: 12, color: digilukSubTextColor)),
                          const SizedBox(height: 4),
                          Text(party.name,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          if (party.balance > 0)
                            Text(
                                'Pending: \u{20B9}${party.balance.toStringAsFixed(0)}',
                                style: const TextStyle(color: digilukIncome)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _upiIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Your UPI ID',
                        hintText: 'name@bank',
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\u{20B9} ',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        prefixIcon: Icon(Icons.note),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (upiUrl.isNotEmpty) ...[
                      const Text('Show this QR to collect:',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: digilukWhite,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: digilukDividerColor),
                          ),
                          child: QrImageView(
                            data: upiUrl,
                            size: 200,
                            backgroundColor: digilukWhite,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(upiUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.send, color: digilukWhite),
                        label: const Text('Open UPI App',
                            style: TextStyle(color: digilukWhite)),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        if (party.phone.isNotEmpty) {
                          final payUrl =
                              'upi://pay?pa=${party.phone}@okaxis&pn=${Uri.encodeComponent(party.name)}';
                          launchUrl(Uri.parse(payUrl),
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('Or scan their QR to pay'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        error: (e, t) => Center(child: Text(e.toString())),
        loading: () => const Loader(),
      ),
    );
  }
}
