import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/cloudinary_image.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/auth/controller/auth_controller.dart';
import 'package:digiluk/features/khata/controller/khata_controller.dart';
import 'package:digiluk/features/parties/screens/add_party_screen.dart';
import 'package:digiluk/features/parties/screens/party_detail_screen.dart';
import 'package:digiluk/features/trust/screens/create_trust_screen.dart';
import 'package:digiluk/features/trust_home/screens/trust_home_screen.dart';
import 'package:digiluk/features/trust/controller/trust_controller.dart';
import 'package:digiluk/models/party_model.dart';
import 'package:digiluk/models/trust_model.dart';

class KhataHomeScreen extends ConsumerStatefulWidget {
  static const String routeName = '/khata-home';
  const KhataHomeScreen({super.key});

  @override
  ConsumerState<KhataHomeScreen> createState() => _KhataHomeScreenState();
}

class _KhataHomeScreenState extends ConsumerState<KhataHomeScreen> {
  String _searchQuery = '';
  PartyType? _filter = PartyType.customer;

  void _showAddChoiceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: digilukDividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: digilukPrimary.withOpacity(0.1),
                child: const Icon(Icons.person_add, color: digilukPrimary),
              ),
              title: const Text('Add Customer',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Track udhaar / payments for a person'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AddPartyScreen.routeName,
                    arguments: PartyType.customer);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: digilukAccent.withOpacity(0.1),
                child: const Icon(Icons.groups, color: digilukAccent),
              ),
              title: const Text('Create Group',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Manage funds with members transparently'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, CreateTrustScreen.routeName);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final khataCtrl = ref.watch(khataControllerProvider);
    final trustCtrl = ref.watch(trustControllerProvider);
    final userAsync = ref.watch(userDataAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DigiLuk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _PartySearchDelegate(khataCtrl),
              );
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (userData) {
          if (userData == null) {
            return const EmptyState(
              title: 'No User Data',
              subtitle: 'Please login again',
              icon: Icons.person_off,
            );
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildSummaryCards(khataCtrl)),
              SliverToBoxAdapter(child: _buildGroupsStrip(trustCtrl, userData.trustIds)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const Text('Customers & Suppliers',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      _filterChip('All', null),
                      const SizedBox(width: 6),
                      _filterChip('Cust', PartyType.customer),
                      const SizedBox(width: 6),
                      _filterChip('Supp', PartyType.supplier),
                    ],
                  ),
                ),
              ),
              StreamBuilder<List<PartyModel>>(
                stream: khataCtrl.getParties(_filter),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Loader());
                  }
                  var parties = snapshot.data ?? [];
                  if (_searchQuery.isNotEmpty) {
                    parties = parties
                        .where((p) => p.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                        .toList();
                  }
                  if (parties.isEmpty) {
                    return SliverFillRemaining(
                      child: EmptyState(
                        title: 'No Parties Yet',
                        subtitle:
                            'Tap + to add your first customer or supplier.',
                        icon: Icons.people_outline,
                        onAction: () => _showAddChoiceSheet(),
                        actionLabel: 'Add Party',
                      ),
                    );
                  }
                  return SliverList.builder(
                    itemCount: parties.length,
                    itemBuilder: (context, index) {
                      final p = parties[index];
                      return _partyTile(p);
                    },
                  );
                },
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        },
        error: (e, t) => Center(child: Text(e.toString())),
        loading: () => const Loader(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddChoiceSheet,
        backgroundColor: digilukPrimary,
        child: const Icon(Icons.add, color: digilukWhite),
      ),
    );
  }

  Widget _filterChip(String label, PartyType? type) {
    final selected = _filter == type;
    return GestureDetector(
      onTap: () => setState(() => _filter = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? digilukPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? digilukPrimary : digilukDividerColor),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: selected ? digilukWhite : digilukSubTextColor,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSummaryCards(KhataController ctrl) {
    return StreamBuilder<List<PartyModel>>(
      stream: ctrl.getParties(null),
      builder: (context, snapshot) {
        double receivable = 0, payable = 0;
        for (var p in (snapshot.data ?? [])) {
          if (p.balance > 0) {
            if (p.type == PartyType.customer) {
              receivable += p.balance;
            } else {
              payable += p.balance;
            }
          } else if (p.balance < 0) {
            if (p.type == PartyType.customer) {
              payable += p.balance.abs();
            } else {
              receivable += p.balance.abs();
            }
          }
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _summaryCard(
                  'You\'ll Receive',
                  receivable,
                  digilukIncome,
                  Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  'You\'ll Pay',
                  payable,
                  digilukExpense,
                  Icons.arrow_upward,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryCard(
      String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: digilukSubTextColor)),
          const SizedBox(height: 4),
          Text(formatCurrency(amount),
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildGroupsStream(TrustController trustCtrl, List<String> trustIds) {
    if (trustIds.isEmpty) {
      return const SizedBox(
          height: 90,
          child: Center(
              child: Text('No Groups yet',
                  style: TextStyle(color: digilukSubTextColor, fontSize: 12))));
    }
    return StreamBuilder<List<TrustModel>>(
      stream: trustCtrl.getUserTrusts(trustIds),
      builder: (context, snapshot) {
        final trusts = snapshot.data ?? [];
        if (trusts.isEmpty) {
          return const SizedBox(
              height: 90,
              child: Center(child: Loader()));
        }
        return SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: trusts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final t = trusts[index];
              IconData icon = Icons.groups;
              return GestureDetector(
                onTap: () => Navigator.pushNamed(
                    context, TrustHomeScreen.routeName,
                    arguments: t.trustId),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: digilukCardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: digilukDividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                              radius: 14,
                              backgroundColor: digilukAccent.withOpacity(0.15),
                              child: Icon(icon,
                                  size: 14, color: digilukAccent)),
                          const Spacer(),
                          Text('\u{20B9}${t.totalBalance.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: digilukPrimary)),
                        ],
                      ),
                      Text(t.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${t.members.length} members \u00b7 ${t.type.name}',
                          style: const TextStyle(
                              fontSize: 10, color: digilukSubTextColor)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGroupsStrip(trustCtrl, List<String> trustIds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              const Text('Your Groups',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, CreateTrustScreen.routeName),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New',
                    style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    foregroundColor: digilukPrimary, padding: EdgeInsets.zero),
              ),
            ],
          ),
        ),
        _buildGroupsStream(trustCtrl, trustIds),
      ],
    );
  }

  Widget _partyTile(PartyModel p) {
    final isReceive = p.balance > 0 && p.type == PartyType.customer ||
        p.balance < 0 && p.type == PartyType.supplier;
    final color = isReceive ? digilukIncome : digilukExpense;
    final initial =
        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CloudinaryCircleAvatar(
          imageUrl: p.photoUrl,
          radius: 20,
          backgroundColor: digilukPrimary.withOpacity(0.12),
          fallback: Text(initial,
              style: const TextStyle(
                  color: digilukPrimary, fontWeight: FontWeight.bold)),
        ),
        title: Text(p.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${p.type == PartyType.customer ? 'Customer' : 'Supplier'}${p.phone.isNotEmpty ? ' \u00b7 ${p.phone}' : ''}',
          style: const TextStyle(fontSize: 12, color: digilukSubTextColor),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(formatCurrency(p.balance),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Text(isReceive ? 'Receive' : 'Pay',
                style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
        onTap: () => Navigator.pushNamed(context, PartyDetailScreen.routeName,
            arguments: {'partyId': p.partyId, 'partyName': p.name}),
      ),
    );
  }
}

class _PartySearchDelegate extends SearchDelegate {
  final KhataController ctrl;
  _PartySearchDelegate(this.ctrl);

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder<List<PartyModel>>(
      stream: ctrl.getParties(null),
      builder: (context, snapshot) {
        var parties = (snapshot.data ?? [])
            .where((p) =>
                p.name.toLowerCase().contains(query.toLowerCase()) ||
                p.phone.contains(query))
            .toList();
        if (parties.isEmpty) {
          return const EmptyState(
              title: 'No results', subtitle: '', icon: Icons.search_off);
        }
        return ListView.builder(
          itemCount: parties.length,
          itemBuilder: (context, i) {
            final p = parties[i];
            return ListTile(
              leading: CircleAvatar(
                  backgroundColor: digilukPrimary.withOpacity(0.12),
                  child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: digilukPrimary))),
              title: Text(p.name),
              subtitle: Text(p.phone),
              trailing: Text(formatCurrency(p.balance),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                close(context, null);
                Navigator.pushNamed(context, PartyDetailScreen.routeName,
                    arguments: {'partyId': p.partyId, 'partyName': p.name});
              },
            );
          },
        );
      },
    );
  }
}
