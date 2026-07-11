import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/party_message_templates.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/features/auth/controller/auth_controller.dart';
import 'package:digiluk/features/parties/screens/edit_party_screen.dart';
import 'package:digiluk/models/party_model.dart';

class NotifyPartyBottomSheet extends ConsumerStatefulWidget {
  final PartyModel party;

  const NotifyPartyBottomSheet({super.key, required this.party});

  @override
  ConsumerState<NotifyPartyBottomSheet> createState() => _NotifyPartyBottomSheetState();
}

class _NotifyPartyBottomSheetState extends ConsumerState<NotifyPartyBottomSheet> {
  late final _messageCtrl = TextEditingController();
  late PartyMessageTemplate _selectedTemplate;
  String _businessName = '';

  @override
  void initState() {
    super.initState();
    final templates = PartyMessageTemplates.templatesFor(widget.party);
    _selectedTemplate = templates.first;
    _updateMessage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.watch(userDataAuthProvider).value;
    _businessName = user?.businessName ?? user?.name ?? 'DigiLuk';
    _updateMessage();
  }

  void _updateMessage() {
    final amount = widget.party.balance.abs().toStringAsFixed(0);
    _messageCtrl.text = PartyMessageTemplates.fillTemplate(
      _selectedTemplate.template,
      name: widget.party.name,
      amount: amount,
      businessName: _businessName,
      date: formatDate(DateTime.now()),
    );
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  String get _phone {
    return widget.party.phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  bool get _hasPhone => _phone.isNotEmpty;
  bool get _hasEmail => widget.party.email.isNotEmpty;

  String get _whatsappPhone {
    var digits = _phone;
    if (digits.length == 10) return '91$digits';
    if (digits.length > 10 && digits.startsWith('91')) return digits;
    if (digits.length > 10 && digits.startsWith('0')) return '91${digits.substring(1)}';
    return digits;
  }

  Future<void> _sendWhatsApp() async {
    if (!_hasPhone) return _shareGeneric();
    final msg = _messageCtrl.text.trim();
    final url = 'https://wa.me/$_whatsappPhone?text=${Uri.encodeComponent(msg)}';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      debugPrint('WhatsApp launch error: $e');
    }
    await _shareGeneric();
  }

  Future<void> _sendSMS() async {
    if (!_hasPhone) return _shareGeneric();
    final msg = _messageCtrl.text.trim();
    final uri = Uri.parse('sms:$_phone?body=${Uri.encodeComponent(msg)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (e) {
      debugPrint('SMS launch error: $e');
    }
    await _shareGeneric();
  }

  Future<void> _sendEmail() async {
    if (!_hasEmail) return _shareGeneric();
    final body = _messageCtrl.text.trim();
    final subject = 'Payment Reminder - \u{20B9}${widget.party.balance.abs().toStringAsFixed(0)}';
    final uri = Uri.parse(
      'mailto:${widget.party.email}?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (e) {
      debugPrint('Email launch error: $e');
    }
    await _shareGeneric();
  }

  Future<void> _shareGeneric() async {
    await Share.share(_messageCtrl.text.trim());
  }

  void _addPhoneNumber() {
    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      EditPartyScreen.routeName,
      arguments: widget.party,
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = PartyMessageTemplates.templatesFor(widget.party);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Notify ${widget.party.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: digilukPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: digilukPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.party.balance > 0
                            ? widget.party.resolvedCategory.receiveTitle
                            : widget.party.resolvedCategory.payTitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: digilukSubTextColor,
                        ),
                      ),
                      Text(
                        '\u{20B9}${widget.party.balance.abs().toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose Template',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: templates.length,
              itemBuilder: (context, i) {
                final t = templates[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t.displayName),
                    selected: _selectedTemplate.id == t.id,
                    selectedColor: digilukPrimary,
                    labelStyle: TextStyle(
                      color: _selectedTemplate.id == t.id
                          ? digilukWhite
                          : digilukTextColor,
                    ),
                    onSelected: (v) {
                      if (v) {
                        setState(() {
                          _selectedTemplate = t;
                          _updateMessage();
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Edit message if needed',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          if (!_hasPhone) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add customer mobile number for WhatsApp and SMS options.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addPhoneNumber,
                icon: const Icon(Icons.phone, color: digilukPrimary),
                label: const Text('Add Mobile Number'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_hasPhone) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendWhatsApp,
                icon: const Icon(Icons.chat, color: digilukWhite),
                label: const Text('Send via WhatsApp',
                    style: TextStyle(color: digilukWhite)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _sendSMS,
                icon: const Icon(Icons.sms, color: digilukPrimary),
                label: const Text('Send via SMS'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _hasEmail ? _sendEmail : null,
              icon: const Icon(Icons.email, color: digilukPrimary),
              label: Text(_hasEmail ? 'Send via Email' : 'Email not available'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _shareGeneric,
              icon: const Icon(Icons.share, color: digilukPrimary),
              label: const Text('Share via other apps'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
