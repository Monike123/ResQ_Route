import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'movement_smoother.dart';

/// Background GPS tracking service for active journeys.
///
/// Records smoothed positions to `journey_points` and broadcasts
/// live location via Supabase Realtime channels.
class GpsTrackingService {
  final SupabaseClient _client;
  final MovementSmoother _smoother = MovementSmoother();

  StreamSubscription<Position>? _positionStream;
  String? _activeJourneyId;
  Duration _interval = const Duration(seconds: 5);

  /// Called whenever a new smoothed position is available.
  void Function(Position position)? onPositionUpdate;

  GpsTrackingService({
    required SupabaseClient client,
    this.onPositionUpdate,
  }) : _client = client;

  bool get isTracking => _positionStream != null;

  /// Start tracking with optional interval override.
  Future<void> startTracking({
    required String journeyId,
    Duration? interval,
  }) async {
    _activeJourneyId = journeyId;
    _interval = interval ?? const Duration(seconds: 5);
    _smoother.reset();

    await _positionStream?.cancel();

    final settings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // min 5 m movement
      intervalDuration: _interval,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: 'ResQ Route is monitoring your journey for safety',
        notificationTitle: 'Journey Active',
        enableWakeLock: true,
      ),
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(_onRawPosition);
  }

  /// Adjust GPS frequency (e.g. battery-aware).
  Future<void> changeInterval(Duration newInterval) async {
    if (_activeJourneyId == null) return;
    _interval = newInterval;
    // Restart stream with new interval
    await startTracking(
      journeyId: _activeJourneyId!,
      interval: newInterval,
    );
  }

  /// Reduce frequency for paused state.
  Future<void> reduceFrequency() async {
    if (_activeJourneyId == null) return;
    await changeInterval(const Duration(seconds: 30));
  }

  Future<void> _onRawPosition(Position raw) async {
    if (_activeJourneyId == null) return;

    // 1. Smooth & filter
    final smoothed = _smoother.smooth(raw);
    if (smoothed == null) return; // anomaly — discard

    // 2. Notify listeners (deadman switch, deviation detector, UI)
    onPositionUpdate?.call(smoothed);

    // 3. Store in database
    try {
      await _client.from('journey_points').insert({
        'journey_id': _activeJourneyId,
        'lat': smoothed.latitude,
        'lng': smoothed.longitude,
        'accuracy': smoothed.accuracy,
        'speed': smoothed.speed,
        'heading': smoothed.heading,
        'battery_level': null, // filled by BatteryService
      });
    } catch (_) {
      // Offline — points will be retried or lost
    }

    // 4. Broadcast via Realtime channel
    try {
      await _client
          .channel('journey:$_activeJourneyId')
          .sendBroadcastMessage(
            event: 'location_update',
            payload: {
              'lat': smoothed.latitude,
              'lng': smoothed.longitude,
              'speed': smoothed.speed,
              'heading': smoothed.heading,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
    } catch (_) {
      // Non-critical
    }
  }

  /// Stop tracking entirely.
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _activeJourneyId = null;
  }

  void dispose() {
    _positionStream?.cancel();
  }
}
