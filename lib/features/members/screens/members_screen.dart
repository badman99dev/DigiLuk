import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/custom_button.dart';
import 'package:digiluk/common/widgets/cloudinary_image.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/auth/controller/auth_controller.dart';
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
              subtitle: 'Group not found',
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
                  leading: CloudinaryCircleAvatar(
                    imageUrl: member.profilePic,
                    radius: 24,
                    backgroundColor: roleColor.withOpacity(0.1),
                    fallback: Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
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
                    member.email.isNotEmpty ? member.email : member.phoneNumber,
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
    final emailController = TextEditingController();
    bool isSearching = false;
    Map<String, dynamic>? searchResult;
    bool userNotFound = false;
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
                  const Text('Email Address'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'user@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: isSearching
                            ? null
                            : () async {
                                String email = emailController.text.trim();
                                if (email.isEmpty) {
                                  showSnackBar(
                                      context: context,
                                      content: 'Enter email address');
                                  return;
                                }
                                if (!email.contains('@') ||
                                    !email.contains('.')) {
                                  showSnackBar(
                                      context: context,
                                      content: 'Enter valid email');
                                  return;
                                }
                                setState(() {
                                  isSearching = true;
                                  searchResult = null;
                                  userNotFound = false;
                                });
                                final result = await ref
                                    .read(trustControllerProvider)
                                    .searchUserByEmail(email);
                                setState(() {
                                  isSearching = false;
                                  if (result != null) {
                                    searchResult = result;
                                    userNotFound = false;
                                  } else {
                                    searchResult = null;
                                    userNotFound = true;
                                  }
                                });
                              },
                      ),
                    ),
                    onSubmitted: (value) async {
                      String email = value.trim();
                      if (email.isEmpty || !email.contains('@')) return;
                      setState(() {
                        isSearching = true;
                        searchResult = null;
                        userNotFound = false;
                      });
                      final result = await ref
                          .read(trustControllerProvider)
                          .searchUserByEmail(email);
                      setState(() {
                        isSearching = false;
                        if (result != null) {
                          searchResult = result;
                          userNotFound = false;
                        } else {
                          searchResult = null;
                          userNotFound = true;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  if (isSearching)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Loader()),
                    ),

                  if (searchResult != null) ...[
                    _buildUserCard(searchResult!),
                    const SizedBox(height: 16),
                    const Text('Select Role'),
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
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Confirm & Add',
                      onPressed: () {
                        ref.read(trustControllerProvider).addMemberByEmail(
                              context: context,
                              trustId: trustId,
                              email: emailController.text.trim(),
                              role: selectedRole == 'manager'
                                  ? MemberRole.manager
                                  : MemberRole.member,
                            );
                      },
                    ),
                  ],

                  if (userNotFound)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: digilukExpense.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: digilukExpense.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_search_outlined,
                              color: digilukExpense, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'No user found',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No DigiLuk user with this email. Ask them to install DigiLuk and sign in first.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: digilukSubTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!isSearching &&
                      searchResult == null &&
                      !userNotFound)
                    const Text(
                      'Enter the email address of the person you want to add. They must have DigiLuk installed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: digilukSubTextColor,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData) {
    String name = userData['name'] ?? 'Unknown';
    String email = userData['email'] ?? '';
    String profilePic = userData['profilePic'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: digilukPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: digilukPrimary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CloudinaryCircleAvatar(
            imageUrl: profilePic,
            radius: 28,
            backgroundColor: digilukPrimary.withOpacity(0.1),
            fallback: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: digilukPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: digilukTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: digilukSubTextColor,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: digilukIncome, size: 28),
        ],
      ),
    );
  }
}
