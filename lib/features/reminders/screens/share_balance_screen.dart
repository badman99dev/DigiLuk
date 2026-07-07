import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/khata/controller/khata_controller.dart';
import 'package:digiluk/models/party_model.dart';

class ShareBalanceScreen extends ConsumerWidget {
  static const String routeName = '/share-balance';
  final String partyId;
  const ShareBalanceScreen({super.key, required this.partyId});

  String _buildMessage(PartyModel party) {
    String dir;
    if (party.balance > 0) {
      dir = party.type == PartyType.customer
          ? 'You have to pay me'
          : 'I have to pay you';
    } else if (party.balance < 0) {
      dir = party.type == PartyType.customer
          ? 'I have to pay you'
          : 'You have to pay me';
    } else {
      dir = 'Our accounts are settled';
    }
    return 'Dear ${party.name}, as per my records on ${formatDate(DateTime.now())}, '
        '$dir \u{20B9}${party.balance.abs().toStringAsFixed(0)}. '
        '- DigiLuk';
  }

  Future<void> _shareWhatsApp(PartyModel party) async {
    final msg = _buildMessage(party);
    final phone = party.phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isNotEmpty) {
      final url = 'https://wa.me/91$phone?text=${Uri.encodeComponent(msg)}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } else {
      Share.share(msg);
    }
  }

  Future<void> _shareSMS(PartyModel party) async {
    final msg = _buildMessage(party);
    final phone = party.phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isNotEmpty) {
      final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(msg)}');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } else {
      Share.share(msg);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.watch(khataControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Share Balance')),
      body: StreamBuilder<PartyModel>(
        stream: ctrl.partyStream(partyId),
        builder: (context, snap) {
          if (!snap.hasData) return const Loader();
          final party = snap.data!;
          final msg = _buildMessage(party);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: digilukCardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(msg, style: const TextStyle(fontSize: 15, height: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _shareWhatsApp(party),
                  icon: const Icon(Icons.chat, color: digilukWhite),
                  label: const Text('Send via WhatsApp',
                      style: TextStyle(color: digilukWhite, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _shareSMS(party),
                  icon: const Icon(Icons.sms, color: digilukPrimary),
                  label: const Text('Send via SMS',
                      style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Share.share(msg),
                  icon: const Icon(Icons.share, color: digilukPrimary),
                  label: const Text('Share via other apps',
                      style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BulkRemindersScreen extends ConsumerWidget {
  static const String routeName = '/bulk-reminders';
  const BulkRemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.watch(khataControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Reminders'),
        actions: [
          StreamBuilder<List<PartyModel>>(
            stream: ctrl.getParties(null),
            builder: (context, snap) {
              final due = (snap.data ?? [])
                  .where((p) => p.balance > 0 && p.type == PartyType.customer)
                  .toList();
              if (due.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.send),
                tooltip: 'Send all',
                onPressed: () async {
                  int sent = 0;
                  for (final p in due) {
                    final msg =
                        'Dear ${p.name}, as per my records on ${formatDate(DateTime.now())}, '
                        'You have to pay me \u{20B9}${p.balance.abs().toStringAsFixed(0)}. - DigiLuk';
                    final phone = p.phone.replaceAll(RegExp(r'[^0-9]'), '');
                    if (phone.isNotEmpty) {
                      final url =
                          'https://wa.me/91$phone?text=${Uri.encodeComponent(msg)}';
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                      await Future.delayed(const Duration(milliseconds: 800));
                      sent++;
                    }
                  }
                  if (context.mounted) {
                    showSnackBar(
                        context: context,
                        content: 'Opened WhatsApp for $sent/${due.length} customers');
                  }
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<PartyModel>>(
        stream: ctrl.getParties(null),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
          final due = (snap.data ?? [])
              .where((p) => p.balance > 0 && p.type == PartyType.customer)
              .toList();
          if (due.isEmpty) {
            return const EmptyState(
              title: 'No Pending Dues',
              subtitle: 'All customers are settled \u{1F389}',
              icon: Icons.check_circle_outline,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: due.length,
            itemBuilder: (context, i) {
              final p = due[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                      backgroundColor: digilukExpense.withOpacity(0.1),
                      child: const Icon(Icons.person, color: digilukExpense)),
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(p.phone.isNotEmpty ? p.phone : 'No phone'),
                  trailing: Text(formatCurrency(p.balance),
                      style: const TextStyle(
                          color: digilukExpense, fontWeight: FontWeight.bold)),
                  onTap: () {
                    final msg =
                        'Dear ${p.name}, as per my records on ${formatDate(DateTime.now())}, '
                        'You have to pay me \u{20B9}${p.balance.abs().toStringAsFixed(0)}. - DigiLuk';
                    final phone = p.phone.replaceAll(RegExp(r'[^0-9]'), '');
                    if (phone.isNotEmpty) {
                      launchUrl(
                          Uri.parse(
                              'https://wa.me/91$phone?text=${Uri.encodeComponent(msg)}'),
                          mode: LaunchMode.externalApplication);
                    } else {
                      Share.share(msg);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
