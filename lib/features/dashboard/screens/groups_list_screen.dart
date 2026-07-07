import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/auth/controller/auth_controller.dart';
import 'package:digiluk/features/trust/controller/trust_controller.dart';
import 'package:digiluk/features/trust/screens/create_trust_screen.dart';
import 'package:digiluk/features/trust_home/screens/trust_home_screen.dart';
import 'package:digiluk/models/trust_model.dart';

class GroupsListScreen extends ConsumerWidget {
  static const String routeName = '/dashboard-trusts';
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userDataAuthProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: user.when(
        data: (userData) {
          if (userData == null) {
            return const EmptyState(
              title: 'No User Data',
              subtitle: 'Please login again',
              icon: Icons.person_off,
            );
          }
          return StreamBuilder<List<TrustModel>>(
            stream: ref
                .watch(trustControllerProvider)
                .getUserTrusts(userData.trustIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Loader();
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return EmptyState(
                  title: 'No Groups Yet',
                  subtitle:
                      'Create your first group to start managing funds transparently.',
                  icon: Icons.account_balance_outlined,
                  onAction: () {
                    Navigator.pushNamed(context, CreateTrustScreen.routeName);
                  },
                  actionLabel: 'Create Group',
                );
              }
              final trusts = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trusts.length,
                itemBuilder: (context, index) {
                  final trust = trusts[index];
                  return _buildGroupCard(context, trust);
                },
              );
            },
          );
        },
        error: (err, trace) => Center(child: Text(err.toString())),
        loading: () => const Loader(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, CreateTrustScreen.routeName),
        backgroundColor: digilukPrimary,
        child: const Icon(Icons.add, color: digilukWhite),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, TrustModel trust) {
    IconData typeIcon;
    switch (trust.type) {
      case TrustType.general:
        typeIcon = Icons.account_balance;
        break;
      case TrustType.committee:
        typeIcon = Icons.groups;
        break;
      case TrustType.ngo:
        typeIcon = Icons.volunteer_activism;
        break;
      case TrustType.kitty:
        typeIcon = Icons.celebration;
        break;
      case TrustType.business:
        typeIcon = Icons.store;
        break;
      case TrustType.tuition:
        typeIcon = Icons.school;
        break;
      case TrustType.gym:
        typeIcon = Icons.fitness_center;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(
            context,
            TrustHomeScreen.routeName,
            arguments: trust.trustId,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: digilukPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: digilukPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trust.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: digilukTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trust.members.length} members \u00b7 ${trust.type.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: digilukSubTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\u{20B9}${trust.totalBalance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: digilukPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: digilukAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${trust.members.where((m) => m.role == MemberRole.creator || m.role == MemberRole.manager).length} Admins',
                      style: const TextStyle(
                        fontSize: 10,
                        color: digilukAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
