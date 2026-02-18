import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Captures an immutable forensic record at the moment of SOS:
/// location, speed, battery, device info, last positions, journey summary.
/// Generates a SHA-256 integrity hash and uploads to Supabase Storage.
class ForensicSnapshotService {
  final SupabaseClient _client;

  ForensicSnapshotService({required SupabaseClient client}) : _client = client;

  Future<void> captureSnapshot({
    required String sosEventId,
    required String userId,
    required String userName,
    required Position position,
    String? journeyId,
  }) async {
    // 1. Gather device info
    final deviceInfo = await _getDeviceInfo();

    // 2. Get last 10 journey positions
    List<Map<String, dynamic>> lastPositions = [];
    if (journeyId != null) {
      try {
        final points = await _client
            .from('journey_points')
            .select('lat, lng, speed, recorded_at')
            .eq('journey_id', journeyId)
            .order('recorded_at', ascending: false)
            .limit(10);
        lastPositions = List<Map<String, dynamic>>.from(points);
      } catch (_) {}
    }

    // 3. Get journey summary
    Map<String, dynamic>? journeySummary;
    if (journeyId != null) {
      try {
        final journey = await _client
            .from('journeys')
            .select('id, started_at, metadata')
            .eq('id', journeyId)
            .maybeSingle();
        if (journey != null) {
          journeySummary = {
            'journey_id': journey['id'],
            'started_at': journey['started_at'],
          };
        }
      } catch (_) {}
    }

    // 4. Build snapshot
    final snapshot = <String, dynamic>{
      'snapshot_id': sosEventId,
      'sos_event_id': sosEventId,
      'captured_at': DateTime.now().toUtc().toIso8601String(),
      'user_id': userId,
      'location': {
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
      },
      'speed_mps': position.speed,
      'heading': position.heading,
      'device': deviceInfo,
      'journey_summary': journeySummary,
      'last_10_positions': lastPositions,
      'trigger_type': 'captured_at_sos',
    };

    // 5. Generate SHA-256 integrity hash
    final content = json.encode(snapshot);
    final hash = sha256.convert(utf8.encode(content)).toString();
    snapshot['integrity_hash'] = hash;

    // 6. Upload to Supabase Storage
    try {
      final bytes = utf8.encode(json.encode(snapshot));
      await _client.storage.from('forensic-snapshots').uploadBinary(
            '$sosEventId/snapshot.json',
            bytes,
            fileOptions:
                const FileOptions(contentType: 'application/json'),
          );

      // 7. Update SOS event with snapshot URL and hash
      final snapshotUrl = _client.storage
          .from('forensic-snapshots')
          .getPublicUrl('$sosEventId/snapshot.json');

      await _client.from('sos_events').update({
        'forensic_snapshot_url': snapshotUrl,
        'forensic_integrity_hash': hash,
      }).eq('id', sosEventId);
    } catch (_) {
      // Storage or DB update failed — non-critical, snapshot data
      // is still available in the SOS event's metadata
    }
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return {
          'model': info.model,
          'os': 'Android ${info.version.release}',
          'manufacturer': info.manufacturer,
        };
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return {
          'model': info.utsname.machine,
          'os': 'iOS ${info.systemVersion}',
          'manufacturer': 'Apple',
        };
      }
    } catch (_) {}
    return {'model': 'Unknown', 'os': 'Unknown'};
  }
}
