import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Offline queue for SOS events — stores unsent SOS data in
/// SharedPreferences and retries when connectivity returns.
class OfflineSOSQueue {
  static const _queueKey = 'offline_sos_queue';

  final SharedPreferences _prefs;
  final SupabaseClient _client;

  OfflineSOSQueue({
    required SharedPreferences prefs,
    required SupabaseClient client,
  })  : _prefs = prefs,
        _client = client;

  /// Queue an SOS event for later submission.
  Future<void> queueSOS(Map<String, dynamic> sosData) async {
    final queue = _getQueue();
    sosData['queued_at'] = DateTime.now().toIso8601String();
    queue.add(sosData);
    await _prefs.setString(_queueKey, json.encode(queue));
  }

  /// Process all queued SOS events — call when connectivity returns.
  Future<int> processQueue() async {
    final queue = _getQueue();
    if (queue.isEmpty) return 0;

    int sent = 0;
    final remaining = <Map<String, dynamic>>[];

    for (final sos in queue) {
      try {
        await _client.from('sos_events').insert({
          'user_id': sos['user_id'],
          'journey_id': sos['journey_id'],
          'trigger_type': sos['trigger_type'],
          'lat': sos['lat'],
          'lng': sos['lng'],
          'accuracy': sos['accuracy'],
          'tracking_link_id': sos['tracking_link_id'],
          'tracking_link_expires_at': DateTime.now()
              .add(const Duration(hours: 24))
              .toIso8601String(),
          'metadata': {'queued_at': sos['queued_at'], 'sent_late': true},
        });
        sent++;
      } catch (_) {
        remaining.add(sos); // Still offline, keep in queue
      }
    }

    await _prefs.setString(_queueKey, json.encode(remaining));
    return sent;
  }

  /// Check if there are pending SOS events.
  bool get hasPending => _getQueue().isNotEmpty;

  int get pendingCount => _getQueue().length;

  /// Clear all queued events (e.g. after manual resolution).
  Future<void> clearQueue() async {
    await _prefs.remove(_queueKey);
  }

  List<Map<String, dynamic>> _getQueue() {
    final raw = _prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
