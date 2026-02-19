import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_service.dart';

/// Service for reading/updating safety score weights
/// and previewing the impact on sample routes.
class ScoreTuningService {
  final SupabaseClient _client;
  final AdminService _adminService;

  ScoreTuningService({
    required SupabaseClient client,
    required AdminService adminService,
  })  : _client = client,
        _adminService = adminService;

  /// Fetch current score weights from safety_config.
  Future<Map<String, double>> getWeights() async {
    try {
      final result = await _client
          .from('safety_config')
          .select('config_value')
          .eq('config_key', 'score_weights')
          .single();

      final raw = result['config_value'] as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      // Return defaults if table not ready
      return {
        'crime_density': 0.35,
        'user_flags': 0.25,
        'commercial': 0.20,
        'lighting': 0.10,
        'population': 0.10,
      };
    }
  }

  /// Preview the impact of new weights on sample routes.
  Future<List<Map<String, dynamic>>> previewWeightChange(
      Map<String, double> newWeights) async {
    try {
      final routes = await _client
          .from('routes')
          .select('id, safety_breakdown')
          .not('safety_breakdown', 'is', null)
          .limit(10);

      final previews = <Map<String, dynamic>>[];
      for (final r in routes) {
        final breakdown = r['safety_breakdown'] as Map<String, dynamic>?;
        if (breakdown == null) continue;

        final components =
            breakdown['components'] as Map<String, dynamic>? ?? {};
        final oldScore = (breakdown['overall_score'] as num?)?.toDouble() ?? 0;

        final newScore =
            ((components['crime_density_score'] as num?)?.toDouble() ?? 0) *
                    (newWeights['crime_density'] ?? 0.35) +
                ((components['user_flag_score'] as num?)?.toDouble() ?? 0) *
                    (newWeights['user_flags'] ?? 0.25) +
                ((components['commercial_factor'] as num?)?.toDouble() ?? 0) *
                    (newWeights['commercial'] ?? 0.20) +
                ((components['lighting_factor'] as num?)?.toDouble() ?? 0) *
                    (newWeights['lighting'] ?? 0.10) +
                ((components['population_density'] as num?)?.toDouble() ?? 0) *
                    (newWeights['population'] ?? 0.10);

        previews.add({
          'route_id': r['id'],
          'old_score': oldScore,
          'new_score': newScore,
        });
      }
      return previews;
    } catch (_) {
      return [];
    }
  }

  /// Apply new weights to safety_config.
  Future<void> applyWeights(Map<String, double> weights) async {
    final userId = _client.auth.currentUser?.id;

    await _client.from('safety_config').update({
      'config_value': weights,
      'updated_by': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('config_key', 'score_weights');

    await _adminService.logAction(
      action: 'update_score_weights',
      targetType: 'safety_config',
      details: weights.map((k, v) => MapEntry(k, v)),
    );
  }
}
