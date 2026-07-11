import 'package:flutter/material.dart';
import 'package:digiluk/common/utils/api_client.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/widgets/cloudinary_image.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/trust_home/screens/trust_home_screen.dart';

class PublicGroupPreviewScreen extends StatefulWidget {
  static const String routeName = '/public-group';
  final String trustId;

  const PublicGroupPreviewScreen({super.key, required this.trustId});

  @override
  State<PublicGroupPreviewScreen> createState() =>
      _PublicGroupPreviewScreenState();
}

class _PublicGroupPreviewScreenState extends State<PublicGroupPreviewScreen> {
  Map<String, dynamic>? _groupData;
  bool _isLoading = true;
  bool _isRequesting = false;
  String? _requestStatus;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    final data = await ApiClient.getPublicGroup(widget.trustId);
    if (mounted) {
      setState(() {
        _groupData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestJoin() async {
    setState(() => _isRequesting = true);
    final success = await ApiClient.requestJoinGroup(widget.trustId);
    if (mounted) {
      setState(() {
        _isRequesting = false;
        _requestStatus = success ? 'sent' : 'failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Preview')),
      body: _isLoading
          ? const Center(child: Loader())
          : _groupData == null
              ? const EmptyState(
                  title: 'Group Not Found',
                  subtitle: 'This group may be private or no longer exists.',
                  icon: Icons.lock_outline,
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final data = _groupData!;
    final name = data['name'] ?? '';
    final desc = data['description'] ?? '';
    final type = data['type'] ?? 'general';
    final balance = (data['totalBalance'] ?? 0).toDouble();
    final memberCount = data['memberCount'] ?? 0;
    final visibility = data['visibility'] ?? 'all_members';
    final isMember = data['isMember'] ?? false;
    final transactions = data['transactions'] as List?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: digilukAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.groups, color: digilukAccent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('$memberCount members · $type',
                        style: const TextStyle(
                            fontSize: 13, color: digilukSubTextColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (desc.isNotEmpty)
            Text(desc,
                style: const TextStyle(
                    fontSize: 14, color: digilukSubTextColor, height: 1.5)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: digilukPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: digilukPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Balance',
                          style: TextStyle(
                              fontSize: 12, color: digilukSubTextColor)),
                      Text(
                        '\u{20B9}${balance.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (isMember) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    TrustHomeScreen.routeName,
                    arguments: widget.trustId,
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Group'),
              ),
            ),
          ] else if (visibility == 'everyone' && transactions != null) ...[
            const Text('Recent Transactions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...transactions.take(10).map((t) => _buildTxnTile(t)),
            const SizedBox(height: 24),
            _buildJoinButton(),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(Icons.lock_outline, color: Colors.orange, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Only members can view transactions',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Request to join this group to see full details',
                    style: TextStyle(
                        fontSize: 12, color: digilukSubTextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildJoinButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildTxnTile(dynamic t) {
    final map = t as Map<String, dynamic>;
    final isIncome = map['type'] == 'income';
    final amount = (map['amount'] ?? 0).toDouble();
    final description = map['description'] ?? '';
    final category = map['category'] ?? '';
    final addedByName = map['addedByName'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (isIncome ? digilukIncome : digilukExpense).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? digilukIncome : digilukExpense,
            size: 20,
          ),
        ),
        title: Text(
          description.isNotEmpty ? description : category,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(addedByName,
            style: const TextStyle(fontSize: 12, color: digilukSubTextColor)),
        trailing: Text(
          '${isIncome ? '+' : '-'}\u{20B9}${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isIncome ? digilukIncome : digilukExpense,
          ),
        ),
      ),
    );
  }

  Widget _buildJoinButton() {
    if (_requestStatus == 'sent') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle, color: Colors.green),
          label: const Text('Request Sent!'),
        ),
      );
    }
    if (_requestStatus == 'failed') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRequesting ? null : _requestJoin,
              icon: _isRequesting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.person_add),
              label: Text(_isRequesting ? 'Sending...' : 'Request to Join'),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Failed to send request. Try again.',
              style: TextStyle(color: Colors.red, fontSize: 12)),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isRequesting ? null : _requestJoin,
        icon: _isRequesting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.person_add),
        label: Text(_isRequesting ? 'Sending...' : 'Request to Join'),
      ),
    );
  }
}
