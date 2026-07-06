import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/custom_button.dart';
import 'package:digiluk/features/trust/controller/trust_controller.dart';
import 'package:digiluk/models/trust_model.dart';

class CreateTrustScreen extends ConsumerStatefulWidget {
  static const String routeName = '/create-trust';
  const CreateTrustScreen({super.key});

  @override
  ConsumerState<CreateTrustScreen> createState() => _CreateTrustScreenState();
}

class _CreateTrustScreenState extends ConsumerState<CreateTrustScreen> {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  TrustType _selectedType = TrustType.general;
  String _visibility = 'all_members';
  bool _requireApproval = false;
  int? _autoDeleteDays;
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    super.dispose();
  }

  void _createTrust() {
    String name = nameController.text.trim();
    String desc = descController.text.trim();

    if (name.isEmpty) {
      showSnackBar(context: context, content: 'Please enter trust name');
      return;
    }

    setState(() => _isLoading = true);

    ref.read(trustControllerProvider).createTrust(
          context: context,
          name: name,
          description: desc,
          type: _selectedType,
          settings: TrustSettings(
            visibility: _visibility,
            requireApproval: _requireApproval,
            autoDeleteDays: _autoDeleteDays,
          ),
        );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trust'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trust Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: digilukTextColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'e.g., Sharma Family Trust',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Description (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: digilukTextColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What is this trust for?',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Trust Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: digilukTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TrustType.values.map((type) {
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getTypeIcon(type), size: 16),
                      const SizedBox(width: 4),
                      Text(_getTypeLabel(type)),
                    ],
                  ),
                  selected: _selectedType == type,
                  selectedColor: digilukPrimary,
                  labelStyle: TextStyle(
                    color: _selectedType == type
                        ? digilukWhite
                        : digilukTextColor,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Who can view transactions?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: digilukTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('All Members'),
                    value: 'all_members',
                    groupValue: _visibility,
                    activeColor: digilukPrimary,
                    onChanged: (val) => setState(() => _visibility = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Managers Only'),
                    value: 'managers_only',
                    groupValue: _visibility,
                    activeColor: digilukPrimary,
                    onChanged: (val) => setState(() => _visibility = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Require approval for expenses'),
              subtitle: const Text(
                'Managers must approve expenses before they are finalized',
              ),
              value: _requireApproval,
              activeTrackColor: digilukPrimary.withOpacity(0.3),
              onChanged: (val) => setState(() => _requireApproval = val),
            ),
            const SizedBox(height: 20),
            const Text(
              'Auto-Delete Timer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: digilukTextColor,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _autoDeleteDays,
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
            const SizedBox(height: 32),
            CustomButton(
              text: 'Create Trust',
              onPressed: _createTrust,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(TrustType type) {
    switch (type) {
      case TrustType.general:
        return Icons.account_balance;
      case TrustType.committee:
        return Icons.groups;
      case TrustType.ngo:
        return Icons.volunteer_activism;
      case TrustType.kitty:
        return Icons.celebration;
    }
  }

  String _getTypeLabel(TrustType type) {
    switch (type) {
      case TrustType.general:
        return 'General';
      case TrustType.committee:
        return 'Committee';
      case TrustType.ngo:
        return 'NGO';
      case TrustType.kitty:
        return 'Kitty';
    }
  }
}
