import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../data/models/emergency_contact_model.dart';
import '../providers/auth_providers.dart';

/// Emergency contacts screen — user adds up to 5 trusted contacts.
class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends ConsumerState<EmergencyContactsScreen> {
  final List<_ContactEntry> _contacts = [
    _ContactEntry(priority: 1, label: 'Primary Contact'),
    _ContactEntry(priority: 2, label: 'Secondary Contact'),
    _ContactEntry(priority: 3, label: 'Tertiary Contact'),
  ];
  bool _isSaving = false;

  static const _relationships = [
    'Parent',
    'Spouse',
    'Sibling',
    'Friend',
    'Colleague',
    'Relative',
    'Other',
  ];

  Future<void> _saveContacts() async {
    // Validate all contacts
    for (final c in _contacts) {
      if (c.nameController.text.trim().isEmpty ||
          c.phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please fill in all 3 emergency contacts')),
        );
        return;
      }
      if (!Validators.isValidIndianPhone(c.phoneController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Invalid phone for ${c.label}')),
        );
        return;
      }
    }

    // Check for duplicates
    final phones = _contacts.map((c) => c.phoneController.text.trim()).toList();
    if (phones.toSet().length != phones.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Each contact must have a unique phone')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(supabaseClientProvider).auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final models = _contacts
          .map((c) => EmergencyContactModel(
                userId: user.id,
                name: c.nameController.text.trim(),
                phone: c.phoneController.text.trim(),
                priority: c.priority,
                relationship: c.relationship,
              ))
          .toList();

      await ref.read(authRepositoryProvider).saveEmergencyContacts(models);
      await ref.read(authRepositoryProvider).completeOnboarding(user.id);

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save contacts: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    for (final c in _contacts) {
      c.nameController.dispose();
      c.phoneController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Emergency Contacts'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Icon(Icons.group_outlined,
                      size: 48, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Choose 3 people who will be\nnotified in emergencies',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Contact cards
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  final c = _contacts[index];
                  return _buildContactCard(c, theme);
                },
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveContacts,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('SAVE & CONTINUE',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(_ContactEntry contact, ThemeData theme) {
    final emojis = ['1️⃣', '2️⃣', '3️⃣'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${emojis[contact.priority - 1]} ${contact.label}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: contact.nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline, size: 20),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: contact.phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
                prefixText: '+91  ',
                counterText: '',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: contact.relationship,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                prefixIcon: Icon(Icons.family_restroom, size: 20),
                isDense: true,
              ),
              items: _relationships
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => contact.relationship = v),
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal helper for contact form state.
class _ContactEntry {
  final int priority;
  final String label;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String? relationship;

  _ContactEntry({required this.priority, required this.label});
}
