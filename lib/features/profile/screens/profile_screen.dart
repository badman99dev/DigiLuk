import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/cloudinary_image.dart';
import 'package:digiluk/features/auth/controller/auth_controller.dart';
import 'package:digiluk/providers/locale_provider.dart';
import 'package:digiluk/common/utils/translations.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _biometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDataAuthProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No user data'));
          }
          _biometricEnabled = user.biometricEnabled;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CloudinaryCircleAvatar(
                  imageUrl: user.profilePic,
                  radius: 50,
                  backgroundColor: digilukPrimary.withOpacity(0.1),
                  fallback: Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      color: digilukPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: digilukTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.phoneNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    color: digilukSubTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: digilukAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${user.trustIds.length} Trusts',
                    style: const TextStyle(
                      fontSize: 12,
                      color: digilukAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSettingsSection(
                  'Preferences',
                  [
                    ListTile(
                      leading: const Icon(Icons.language, color: digilukPrimary),
                      title: const Text('Language'),
                      subtitle: Text(locale == 'hi' ? 'Hindi' : 'English'),
                      trailing: Switch(
                        value: locale == 'hi',
                        activeColor: digilukPrimary,
                        onChanged: (val) {
                          ref.read(localeProvider.notifier).setLocale(
                                val ? 'hi' : 'en',
                              );
                          ref
                              .read(authControllerProvider)
                              .updateLanguagePreference(val ? 'hi' : 'en');
                        },
                      ),
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.fingerprint, color: digilukPrimary),
                      title: const Text('Biometric Lock'),
                      subtitle: const Text(
                          'Require fingerprint to open app'),
                      trailing: Switch(
                        value: _biometricEnabled,
                        activeColor: digilukPrimary,
                        onChanged: (val) async {
                          setState(() => _biometricEnabled = val);
                          await ref
                              .read(authControllerProvider)
                              .updateBiometricEnabled(val);
                          showSnackBar(
                            context: context,
                            content: val
                                ? 'Biometric lock enabled'
                                : 'Biometric lock disabled',
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsSection(
                  'Account',
                  [
                    ListTile(
                      leading: const Icon(Icons.edit, color: digilukPrimary),
                      title: const Text('Edit Profile'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showEditNameDialog(context, user.name),
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline,
                          color: digilukPrimary),
                      title: const Text('About DigiLuk'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authControllerProvider).signOut();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: digilukExpense),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: digilukExpense),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: digilukExpense),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'DigiLuk v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: digilukSubTextColor,
                  ),
                ),
              ],
            ),
          );
        },
        error: (err, trace) => Center(child: Text(err.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: digilukSubTextColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: digilukCardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: tiles
                .map((tile) => Column(
                      children: [
                        tile,
                        if (tile != tiles.last)
                          const Divider(height: 1, indent: 16),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              String newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                ref.read(authControllerProvider).updateProfileName(newName);
                Navigator.pop(context);
                showSnackBar(context: context, content: 'Name updated');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DigiLuk'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transparent Group & Committee Fund Management'),
            SizedBox(height: 8),
            Text(
              'DigiLuk helps groups, committees, and community funds manage money with full transparency. Track every paisa, every transaction, every member.',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 8),
            Text('Version: 1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
