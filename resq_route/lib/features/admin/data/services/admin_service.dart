import 'package:supabase_flutter/supabase_flutter.dart';

/// Core admin service: role checks, audit logging, user management.
class AdminService {
  final SupabaseClient _client;

  AdminService({required SupabaseClient client}) : _client = client;

  // ── Role checks ──

  /// Returns the admin role for the current user, or `null` if not an admin.
  Future<String?> getAdminRole() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final result = await _client
          .from('admin_users')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      return result?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Check if current user is any kind of admin.
  Future<bool> isAdmin() async {
    final role = await getAdminRole();
    return role != null;
  }

  // ── Audit logging ──

  /// Log an admin action for the audit trail.
  Future<void> logAction({
    required String action,
    required String targetType,
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('admin_audit_log').insert({
      'admin_id': userId,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'details': details ?? {},
    });
  }

  /// Get recent audit log entries.
  Future<List<Map<String, dynamic>>> getAuditLog({int limit = 50}) async {
    try {
      final res = await _client
          .from('admin_audit_log')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  // ── User management ──

  /// Fetch all user profiles (admin access).
  Future<List<Map<String, dynamic>>> getUsers({int limit = 100}) async {
    try {
      final res = await _client
          .from('user_profiles')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  /// Suspend or unsuspend a user account.
  Future<void> setUserSuspended(String userId, bool suspended) async {
    await _client.from('user_profiles').update({
      'is_suspended': suspended,
    }).eq('id', userId);

    await logAction(
      action: suspended ? 'suspend_user' : 'unsuspend_user',
      targetType: 'user',
      targetId: userId,
    );
  }

  // ── Dashboard stats ──

  /// Fetch summary stats for the admin dashboard.
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);

      final usersResult = await _client
          .from('user_profiles')
          .select('id')
          .limit(10000);
      final totalUsers = (usersResult as List).length;

      final todayJourneys = await _client
          .from('journeys')
          .select('id')
          .gte('started_at', '${today}T00:00:00Z');
      final journeysToday = (todayJourneys as List).length;

      final sosToday = await _client
          .from('sos_events')
          .select('id')
          .gte('created_at', '${today}T00:00:00Z');
      final sosCount = (sosToday as List).length;

      final pendingFlags = await _client
          .from('unsafe_zones')
          .select('id')
          .eq('verified', false);
      final flagCount = (pendingFlags as List).length;

      return {
        'total_users': totalUsers,
        'journeys_today': journeysToday,
        'sos_today': sosCount,
        'pending_flags': flagCount,
      };
    } catch (_) {
      return {
        'total_users': 0,
        'journeys_today': 0,
        'sos_today': 0,
        'pending_flags': 0,
      };
    }
  }
}
