import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_service.dart';

/// Moderation workflows for unsafe zone flags:
/// approve, reject, merge, and escalate.
class FlagModerationService {
  final SupabaseClient _client;
  final AdminService _adminService;

  FlagModerationService({
    required SupabaseClient client,
    required AdminService adminService,
  })  : _client = client,
        _adminService = adminService;

  /// Fetch all pending (unverified) flags.
  Future<List<Map<String, dynamic>>> getPendingFlags() async {
    try {
      final res = await _client
          .from('unsafe_zones')
          .select()
          .eq('verified', false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  /// Approve a flag — set verified, boost confidence.
  Future<void> approveFlag(String flagId) async {
    await _client.from('unsafe_zones').update({
      'verified': true,
      'confidence_score': 0.8,
    }).eq('id', flagId);

    await _adminService.logAction(
      action: 'approve_flag',
      targetType: 'unsafe_zone',
      targetId: flagId,
    );
  }

  /// Reject (delete) a flag.
  Future<void> rejectFlag(String flagId) async {
    await _client.from('unsafe_zones').delete().eq('id', flagId);

    await _adminService.logAction(
      action: 'reject_flag',
      targetType: 'unsafe_zone',
      targetId: flagId,
    );
  }

  /// Merge multiple flags into a primary one.
  Future<void> mergeFlags(String primaryId, List<String> mergeIds) async {
    final totalFlags = mergeIds.length + 1;
    await _client.from('unsafe_zones').update({
      'flag_count': totalFlags,
      'verified': true,
    }).eq('id', primaryId);

    for (final id in mergeIds) {
      await _client.from('unsafe_zones').delete().eq('id', id);
    }

    await _adminService.logAction(
      action: 'merge_flags',
      targetType: 'unsafe_zone',
      targetId: primaryId,
      details: {'merged': mergeIds},
    );
  }
}
