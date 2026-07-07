import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/widgets/custom_button.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/trust/controller/trust_controller.dart';
import 'package:digiluk/models/trust_model.dart';

class TrustSettingsScreen extends ConsumerStatefulWidget {
  static const String routeName = '/trust-settings';
  final String trustId;
  const TrustSettingsScreen({super.key, required this.trustId});

  @override
  ConsumerState<TrustSettingsScreen> createState() =>
      _TrustSettingsScreenState();
}

class _TrustSettingsScreenState extends ConsumerState<TrustSettingsScreen> {
  String _visibility = 'all_members';
  bool _requireApproval = false;
  int? _autoDeleteDays;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final trustController = ref.watch(trustControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Settings'),
      ),
      body: StreamBuilder<TrustModel>(
        stream: trustController.getTrustData(widget.trustId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Group not found'));
          }
          final trust = snapshot.data!;
          final settings = trust.settings;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Visibility'),
                RadioListTile<String>(
                  title: const Text('All Members'),
                  subtitle: const Text(
                      'Everyone can see all transactions'),
                  value: 'all_members',
                  groupValue: _visibility.isNotEmpty ? _visibility : settings.visibility,
                  activeColor: digilukPrimary,
                  onChanged: (val) => setState(() => _visibility = val!),
                ),
                RadioListTile<String>(
                  title: const Text('Managers Only'),
                  subtitle: const Text(
                      'Only managers can see transactions'),
                  value: 'managers_only',
                  groupValue: _visibility.isNotEmpty ? _visibility : settings.visibility,
                  activeColor: digilukPrimary,
                  onChanged: (val) => setState(() => _visibility = val!),
                ),
                const Divider(height: 32),
                _buildSectionTitle('Approval Workflow'),
                SwitchListTile(
                  title: const Text('Require approval for expenses'),
                  subtitle: const Text(
                      'Expenses need manager approval before being finalized'),
                  value: _requireApproval,
                  activeTrackColor: digilukPrimary.withOpacity(0.3),
                  onChanged: (val) =>
                      setState(() => _requireApproval = val),
                ),
                const Divider(height: 32),
                _buildSectionTitle('Auto-Delete Timer'),
                const Text(
                  'Automatically delete group data after a specified period.',
                  style: TextStyle(
                    fontSize: 12,
                    color: digilukSubTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: _autoDeleteDays ?? settings.autoDeleteDays,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Never')),
                    DropdownMenuItem(value: 30, child: Text('30 Days')),
                    DropdownMenuItem(value: 60, child: Text('60 Days')),
                    DropdownMenuItem(value: 90, child: Text('90 Days')),
                    DropdownMenuItem(value: 180, child: Text('180 Days')),
                    DropdownMenuItem(value: 365, child: Text('365 Days')),
                  ],
                  onChanged: (val) => setState(() => _autoDeleteDays = val),
                ),
                const Divider(height: 32),
                _buildSectionTitle('Group Info'),
                _buildInfoRow('Group Name', trust.name),
                _buildInfoRow('Type', trust.type.name),
                _buildInfoRow('Members', '${trust.members.length}'),
                _buildInfoRow('Created By', trust.createdBy),
                _buildInfoRow(
                  'Created On',
                  '${trust.createdAt.day}/${trust.createdAt.month}/${trust.createdAt.year}',
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Save Settings',
                  onPressed: () {
                    setState(() => _isLoading = true);
                    trustController.updateTrustSettings(
                      context: context,
                      trustId: widget.trustId,
                      settings: TrustSettings(
                        visibility: _visibility,
                        requireApproval: _requireApproval,
                        autoDeleteDays: _autoDeleteDays,
                        customCategories: settings.customCategories,
                      ),
                    );
                    setState(() => _isLoading = false);
                  },
                  isLoading: _isLoading,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: digilukTextColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: digilukSubTextColor)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
