import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'forensic_snapshot_service.dart';
import 'direct_sms_service.dart';
import 'offline_sos_queue.dart';

/// Trigger types matching the DB check constraint.
enum SOSTriggerType { button, voice, deadman, shake }

/// Orchestrates the full SOS flow:
/// 1. Create SOS event in DB
/// 2. Send SMS to emergency contacts via Edge Function
/// 3. Capture forensic snapshot
/// 4. Update journey status
/// 5. Fallback to direct SMS / offline queue on failure
class SOSService {
  final SupabaseClient _client;
  final ForensicSnapshotService _forensicService;
  final DirectSMSService _directSMS;
  final OfflineSOSQueue _offlineQueue;

  String? _currentJourneyId;
  bool _isTriggering = false;

  SOSService({
    required SupabaseClient client,
    required ForensicSnapshotService forensicService,
    required DirectSMSService directSMS,
    required OfflineSOSQueue offlineQueue,
  })  : _client = client,
        _forensicService = forensicService,
        _directSMS = directSMS,
        _offlineQueue = offlineQueue;

  /// Set active journey for SOS context.
  void setJourneyId(String? id) => _currentJourneyId = id;

  bool get isTriggering => _isTriggering;

  /// Full SOS lifecycle.
  Future<void> trigger(SOSTriggerType type) async {
    if (_isTriggering) return; // prevent double-trigger
    _isTriggering = true;

    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // 1. Get current position
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (_) {
        // Fallback: last known position
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) return;
        position = last;
      }

      // 2. Generate tracking link ID
      final trackingId = _generateTrackingId();

      // 3. Create SOS event in DB
      String? sosEventId;
      try {
        final response = await _client.from('sos_events').insert({
          'user_id': user.id,
          'journey_id': _currentJourneyId,
          'trigger_type': type.name,
          'lat': position.latitude,
          'lng': position.longitude,
          'accuracy': position.accuracy,
          'tracking_link_id': trackingId,
          'tracking_link_expires_at': DateTime.now()
              .add(const Duration(hours: 24))
              .toIso8601String(),
        }).select('id').single();
        sosEventId = response['id'] as String;
      } catch (_) {
        // DB offline — queue for later
        await _offlineQueue.queueSOS({
          'user_id': user.id,
          'journey_id': _currentJourneyId,
          'trigger_type': type.name,
          'lat': position.latitude,
          'lng': position.longitude,
          'accuracy': position.accuracy,
          'tracking_link_id': trackingId,
        });
      }

      // 4. Send SMS to emergency contacts
      final contacts = await _getEmergencyContacts(user.id);
      final userName =
          user.userMetadata?['full_name'] as String? ?? 'ResQ Route User';
      final trackingLink = 'https://resqroute.app/track/$trackingId';

      try {
        await _client.functions.invoke('send-sos-sms', body: {
          'contacts': contacts
              .map((c) => {'name': c['name'], 'phone': c['phone']})
              .toList(),
          'userName': userName,
          'lat': position.latitude,
          'lng': position.longitude,
          'trackingLink': trackingLink,
          'sosEventId': sosEventId,
        });
      } catch (_) {
        // Twilio / Edge Function failed — fallback to direct SMS
        await _directSMS.sendDirectSMS(
          contacts: contacts,
          lat: position.latitude,
          lng: position.longitude,
          userName: userName,
        );
      }

      // 5. Capture forensic snapshot
      if (sosEventId != null) {
        await _forensicService.captureSnapshot(
          sosEventId: sosEventId,
          userId: user.id,
          userName: userName,
          position: position,
          journeyId: _currentJourneyId,
        );
      }

      // 6. Update journey status to 'sos'
      if (_currentJourneyId != null) {
        try {
          await _client
              .from('journeys')
              .update({'status': 'sos'}).eq('id', _currentJourneyId!);
        } catch (_) {
          // Non-critical
        }
      }
    } finally {
      _isTriggering = false;
    }
  }

  /// Resolve an active SOS event.
  Future<void> resolve(String sosEventId, {String resolvedBy = 'user'}) async {
    try {
      await _client.from('sos_events').update({
        'status': 'resolved',
        'resolved_at': DateTime.now().toIso8601String(),
        'resolved_by': resolvedBy,
      }).eq('id', sosEventId);
    } catch (_) {
      // Non-critical
    }
  }

  /// Mark an SOS as false alarm.
  Future<void> markFalseAlarm(String sosEventId) async {
    try {
      await _client.from('sos_events').update({
        'status': 'false_alarm',
        'resolved_at': DateTime.now().toIso8601String(),
        'resolved_by': 'user',
      }).eq('id', sosEventId);
    } catch (_) {
      // Non-critical
    }
  }

  Future<List<Map<String, dynamic>>> _getEmergencyContacts(
      String userId) async {
    try {
      final response = await _client
          .from('emergency_contacts')
          .select('name, phone, relationship')
          .eq('user_id', userId)
          .order('created_at');
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  String _generateTrackingId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final random = Random.secure().nextInt(999999).toRadixString(36);
    return '$timestamp$random';
  }
}
