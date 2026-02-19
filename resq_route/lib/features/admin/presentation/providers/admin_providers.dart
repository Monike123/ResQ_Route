import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes/presentation/providers/route_providers.dart';
import '../../data/services/admin_service.dart';
import '../../data/services/flag_moderation_service.dart';
import '../../data/services/score_tuning_service.dart';

// ── Services ──

final adminServiceProvider = Provider<AdminService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AdminService(client: client);
});

final flagModerationServiceProvider = Provider<FlagModerationService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final adminService = ref.watch(adminServiceProvider);
  return FlagModerationService(client: client, adminService: adminService);
});

final scoreTuningServiceProvider = Provider<ScoreTuningService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final adminService = ref.watch(adminServiceProvider);
  return ScoreTuningService(client: client, adminService: adminService);
});

// ── State ──

/// Current admin role (null if not admin).
final adminRoleProvider = FutureProvider<String?>((ref) async {
  return ref.watch(adminServiceProvider).getAdminRole();
});

/// Dashboard stats.
final dashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(adminServiceProvider).getDashboardStats();
});

/// Pending flags list.
final pendingFlagsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(flagModerationServiceProvider).getPendingFlags();
});

/// Current score weights.
final scoreWeightsProvider =
    FutureProvider<Map<String, double>>((ref) async {
  return ref.watch(scoreTuningServiceProvider).getWeights();
});
