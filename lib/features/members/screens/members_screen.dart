import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/custom_button.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/trust/controller/trust_controller.dart';
import 'package:digiluk/models/trust_model.dart';

class MembersScreen extends ConsumerWidget {
  static const String routeName = '/members';
  final String trustId;
  const MembersScreen({super.key, required this.trustId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustController = ref.watch(trustControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddMemberDialog(context, ref, trustId),
          ),
        ],
      ),
      body: StreamBuilder<TrustModel>(
        stream: trustController.getTrustData(trustId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
          if (!snapshot.hasData) {
            return const EmptyState(
              title: 'No Data',
              subtitle: 'Trust not found',
              icon: Icons.error_outline,
            );
          }
          final trust = snapshot.data!;
          final currentUid = ref.watch(userDataAuthProvider).maybeWhen(
                data: (user) => user?.uid ?? '',
                orElse: () => '',
              );

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trust.members.length,
            itemBuilder: (context, index) {
              final member = trust.members[index];
              final isCurrentUser = member.uid == currentUid;
              final canManage =
                  trust.isManager(currentUid) && !isCurrentUser;

              Color roleColor;
              String roleLabel;
              switch (member.role) {
                case MemberRole.creator:
                  roleColor = digilukRoleCreator;
                  roleLabel = 'Creator';
                  break;
                case MemberRole.manager:
                  roleColor = digilukRoleManager;
                  roleLabel = 'Manager';
                  break;
                case MemberRole.member:
                  roleColor = digilukRoleMember;
                  roleLabel = 'Member';
                  break;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: roleColor.withOpacity(0.1),
                    backgroundImage: member.profilePic.isNotEmpty
                        ? NetworkImage(member.profilePic)
                        : null,
                    child: member.profilePic.isEmpty
                        ? Text(
                            member.name.isNotEmpty
                                ? member.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.name + (isCurrentUser ? ' (You)' : ''),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    member.phoneNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      color: digilukSubTextColor,
                    ),
                  ),
                  trailing: canManage
                      ? PopupMenuButton(
                          itemBuilder: (context) => [
                            if (member.role == MemberRole.member)
                              const PopupMenuItem(
                                value: 'promote',
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_upward, size: 20),
                                    SizedBox(width: 8),
                                    Text('Promote to Manager'),
                                  ],
                                ),
                              ),
                            if (member.role == MemberRole.manager)
                              const PopupMenuItem(
                                value: 'demote',
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_downward, size: 20),
                                    SizedBox(width: 8),
                                    Text('Demote to Member'),
                                  ],
                                ),
                              ),
                          ],
                          onSelected: (value) {
                            if (value == 'promote') {
                              trustController.updateMemberRole(
                                context: context,
                                trustId: trustId,
                                memberUid: member.uid,
                                newRole: MemberRole.manager,
                              );
                            } else if (value == 'demote') {
                              trustController.updateMemberRole(
                                context: context,
                                trustId: trustId,
                                memberUid: member.uid,
                                newRole: MemberRole.member,
                              );
                            }
                          },
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref, String trustId) {
    final phoneController = TextEditingController();
    String selectedRole = 'member';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                  const Text(
                    'Add Member',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Phone Number'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'e.g., +919876543210',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Role'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Member'),
                          value: 'member',
                          groupValue: selectedRole,
                          activeColor: digilukPrimary,
                          onChanged: (val) =>
                              setState(() => selectedRole = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Manager'),
                          value: 'manager',
                          groupValue: selectedRole,
                          activeColor: digilukPrimary,
                          onChanged: (val) =>
                              setState(() => selectedRole = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Note: The person must have DigiLuk installed and registered with this phone number.',
                    style: TextStyle(
                      fontSize: 12,
                      color: digilukSubTextColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Add Member',
                    onPressed: () {
                      String phone = phoneController.text.trim();
                      if (phone.isEmpty) {
                        showSnackBar(
                            context: context, content: 'Enter phone number');
                        return;
                      }
                      ref.read(trustControllerProvider).addMember(
                            context: context,
                            trustId: trustId,
                            phoneNumber: phone,
                            role: selectedRole == 'manager'
                                ? MemberRole.manager
                                : MemberRole.member,
                          );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
