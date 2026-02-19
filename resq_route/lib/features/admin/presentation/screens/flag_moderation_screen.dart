import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/admin_providers.dart';

/// Queue-based moderation screen for unsafe zone flags.
class FlagModerationScreen extends ConsumerStatefulWidget {
  const FlagModerationScreen({super.key});

  @override
  ConsumerState<FlagModerationScreen> createState() =>
      _FlagModerationScreenState();
}

class _FlagModerationScreenState extends ConsumerState<FlagModerationScreen> {
  bool _operating = false;

  Future<void> _approve(String flagId) async {
    setState(() => _operating = true);
    try {
      await ref.read(flagModerationServiceProvider).approveFlag(flagId);
      ref.invalidate(pendingFlagsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flag approved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _operating = false);
    }
  }

  Future<void> _reject(String flagId) async {
    setState(() => _operating = true);
    try {
      await ref.read(flagModerationServiceProvider).rejectFlag(flagId);
      ref.invalidate(pendingFlagsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flag rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _operating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flagsAsync = ref.watch(pendingFlagsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Flag Moderation')),
      body: flagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (flags) {
          if (flags.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 64, color: AppColors.safetySafe),
                  SizedBox(height: 12),
                  Text('No pending flags!',
                      style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: flags.length,
            itemBuilder: (context, i) {
              final flag = flags[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag,
                              color: AppColors.safetyUnsafe, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Flag #${(flag['id'] as String).substring(0, 8)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Text(
                            'Severity: ${flag['severity'] ?? 'medium'}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (flag['reason'] != null)
                        Text('Reason: ${flag['reason']}'),
                      if (flag['description'] != null)
                        Text('Description: ${flag['description']}',
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed:
                                  _operating ? null : () => _approve(flag['id']),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Approve'),
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.safetySafe),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  _operating ? null : () => _reject(flag['id']),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.safetyUnsafe),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
