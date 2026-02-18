import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to obtain a static map snapshot for embedding in the SRR PDF.
///
/// Attempts to call the `generate-map-snapshot` Edge Function.
/// Falls back to returning `null` if unavailable (report is generated
/// without the map in that case).
class MapSnapshotService {
  final SupabaseClient _client;

  MapSnapshotService({required SupabaseClient client}) : _client = client;

  /// Fetch a map snapshot for the given journey/route.
  /// Returns PNG bytes or `null` on failure.
  Future<Uint8List?> captureSnapshot({
    required String journeyId,
    String? routeId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'generate-map-snapshot',
        body: {
          'journeyId': journeyId,
          'routeId': routeId,
        },
      );

      final data = response.data;
      if (data is Uint8List) return data;
      if (data is List<int>) return Uint8List.fromList(data);
      return null;
    } catch (_) {
      // Edge Function unavailable — report will be generated without map
      return null;
    }
  }
}
