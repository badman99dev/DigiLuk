import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/widgets/balance_card.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/common/widgets/transaction_tile.dart';
import 'package:digiluk/features/auth/controller/auth_controller.dart';
import 'package:digiluk/features/trust/controller/trust_controller.dart';
import 'package:digiluk/features/add_transaction/screens/add_transaction_screen.dart';
import 'package:digiluk/features/transactions/screens/transactions_screen.dart';
import 'package:digiluk/features/members/screens/members_screen.dart';
import 'package:digiluk/features/customers/screens/customers_list_screen.dart';
import 'package:digiluk/features/trust_settings/screens/trust_settings_screen.dart';
import 'package:digiluk/features/audit_log/screens/audit_log_screen.dart';
import 'package:digiluk/models/transaction_model.dart';
import 'package:digiluk/models/trust_model.dart';

class TrustHomeScreen extends ConsumerWidget {
  static const String routeName = '/trust-home';
  final String trustId;
  const TrustHomeScreen({super.key, required this.trustId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustController = ref.watch(trustControllerProvider);
    final userAsync = ref.watch(userDataAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Details'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'audit',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20),
                    SizedBox(width: 8),
                    Text('Audit Log'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.pushNamed(
                  context,
                  TrustSettingsScreen.routeName,
                  arguments: trustId,
                );
              } else if (value == 'audit') {
                Navigator.pushNamed(
                  context,
                  AuditLogScreen.routeName,
                  arguments: trustId,
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<TrustModel>(
        stream: trustController.getTrustData(trustId),
        builder: (context, trustSnapshot) {
          if (trustSnapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
          if (!trustSnapshot.hasData) {
            return const EmptyState(
              title: 'Group Not Found',
              subtitle: 'This group may have been deleted.',
              icon: Icons.error_outline,
            );
          }
          final trust = trustSnapshot.data!;

          return StreamBuilder<List<TransactionModel>>(
            stream: trustController.getTransactions(trustId),
            builder: (context, txnSnapshot) {
              double totalIncome = 0;
              double totalExpense = 0;
              List<TransactionModel> txns = txnSnapshot.data ?? [];

              for (var txn in txns) {
                if (txn.status == TransactionStatus.approved) {
                  if (txn.type == TransactionType.income) {
                    totalIncome += txn.amount;
                  } else {
                    totalExpense += txn.amount;
                  }
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BalanceCard(
                      balance: trust.totalBalance,
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                      trustName: trust.name,
                    ),
                    const SizedBox(height: 20),
                    _buildQuickActions(context, trust),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: digilukTextColor,
                          ),
                        ),
                        if (txns.isNotEmpty)
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              TransactionsScreen.routeName,
                              arguments: trustId,
                            ),
                            child: const Text('See All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (txns.isEmpty)
                      const EmptyState(
                        title: 'No Transactions',
                        subtitle: 'Add your first income or expense',
                        icon: Icons.receipt_long_outlined,
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: digilukCardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: txns
                              .take(5)
                              .map((txn) => TransactionTile(
                                    transaction: txn,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      TransactionsScreen.routeName,
                                      arguments: trustId,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildMembersPreview(context, trust),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, TrustModel trust) {
    bool isBusinessType = trust.type == TrustType.business ||
        trust.type == TrustType.tuition ||
        trust.type == TrustType.gym;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      childAspectRatio: 1,
      children: [
        _buildActionItem(
          context,
          Icons.add_circle_outline,
          'Add Income',
          digilukIncome,
          () => Navigator.pushNamed(
            context,
            AddTransactionScreen.routeName,
            arguments: {
              'trustId': trust.trustId,
              'type': TransactionType.income,
            },
          ),
        ),
        _buildActionItem(
          context,
          Icons.remove_circle_outline,
          'Add Expense',
          digilukExpense,
          () => Navigator.pushNamed(
            context,
            AddTransactionScreen.routeName,
            arguments: {
              'trustId': trust.trustId,
              'type': TransactionType.expense,
            },
          ),
        ),
        if (isBusinessType)
          _buildActionItem(
            context,
            Icons.people_outline,
            'Customers',
            digilukAccent,
            () => Navigator.pushNamed(
              context,
              CustomersListScreen.routeName,
              arguments: trust.trustId,
            ),
          )
        else
          _buildActionItem(
            context,
            Icons.people_outline,
            'Members',
            digilukPrimary,
            () => Navigator.pushNamed(
              context,
              MembersScreen.routeName,
              arguments: trust.trustId,
            ),
          ),
        _buildActionItem(
          context,
          Icons.history,
          'Audit Log',
          digilukRoleCreator,
          () => Navigator.pushNamed(
            context,
            AuditLogScreen.routeName,
            arguments: trust.trustId,
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: digilukTextColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildMembersPreview(BuildContext context, TrustModel trust) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: digilukCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Members',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: digilukTextColor,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  MembersScreen.routeName,
                  arguments: trust.trustId,
                ),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: trust.members.length,
              itemBuilder: (context, index) {
                final member = trust.members[index];
                Color roleColor;
                switch (member.role) {
                  case MemberRole.creator:
                    roleColor = digilukRoleCreator;
                    break;
                  case MemberRole.manager:
                    roleColor = digilukRoleManager;
                    break;
                  case MemberRole.member:
                    roleColor = digilukRoleMember;
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: roleColor.withOpacity(0.1),
                        backgroundImage: member.profilePic.isNotEmpty
                            ? NetworkImage(member.profilePic)
                            : null,
                        child: member.profilePic.isEmpty
                            ? Text(
                                member.name.isNotEmpty
                                    ? member.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(color: roleColor),
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.name.split(' ').first,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
