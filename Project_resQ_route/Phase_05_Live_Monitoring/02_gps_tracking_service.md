# 02 — GPS Tracking Service

## Objective
Implement background GPS tracking that records user position during active journeys, handles accuracy, drift, and works reliably across Android/iOS.

---

## Service Architecture

```dart
class LocationService {
  StreamSubscription<Position>? _positionStream;
  final SupabaseClient _client;
  String? _activeJourneyId;

  Future<void> startTracking({
    required String journeyId,
    Duration interval = const Duration(seconds: 5),
  }) async {
    _activeJourneyId = journeyId;

    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,         // Min 5m movement to trigger update
      intervalDuration: interval,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: "ResQ Route is monitoring your journey for safety",
        notificationTitle: "Journey Active",
        enableWakeLock: true,
      ),
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _onNewPosition(position);
    });
  }

  Future<void> _onNewPosition(Position position) async {
    if (_activeJourneyId == null) return;

    // 1. Apply smoothing (see 06_movement_smoothing.md)
    final smoothed = MovementSmoother.smooth(position);

    // 2. Store in database
    await _client.from('journey_points').insert({
      'journey_id': _activeJourneyId,
      'location': 'POINT(${smoothed.longitude} ${smoothed.latitude})',
      'accuracy': smoothed.accuracy,
      'speed': smoothed.speed,
      'heading': smoothed.heading,
      'battery_level': await _getBatteryLevel(),
    });

    // 3. Broadcast via Realtime (for emergency contacts tracking)
    await _client.channel('journey:$_activeJourneyId').sendBroadcastMessage(
      event: 'location_update',
      payload: {
        'lat': smoothed.latitude,
        'lng': smoothed.longitude,
        'speed': smoothed.speed,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _activeJourneyId = null;
  }

  void reduceFrequency({required Duration interval}) {
    stopTracking();
    if (_activeJourneyId != null) {
      startTracking(journeyId: _activeJourneyId!, interval: interval);
    }
  }
}
```

---

## Foreground Service (Android)

Android requires a foreground service notification for persistent background location:

```kotlin
// This is handled by flutter_background_service package
// Configuration in Dart:
FlutterBackgroundService().configure(
  androidConfiguration: AndroidConfiguration(
    onStart: onStart,
    autoStart: false,
    isForegroundMode: true,
    notificationChannelId: 'resq_route_tracking',
    initialNotificationTitle: 'ResQ Route',
    initialNotificationContent: 'Journey monitoring active',
    foregroundServiceNotificationId: 888,
  ),
  iosConfiguration: IosConfiguration(
    autoStart: false,
    onForeground: onStart,
    onBackground: onIosBackground,
  ),
);
```

---

## Data Retention

Journey points are retained for **30 days** then auto-purged:

```sql
-- pg_cron job: daily cleanup
SELECT cron.schedule(
  'purge-old-journey-points',
  '0 4 * * *',  -- 4 AM daily
  $$DELETE FROM journey_points WHERE recorded_at < NOW() - INTERVAL '30 days'$$
);
```

Exception: Journey points linked to SOS events are retained for **7 years**.

---

## Verification
- [ ] GPS tracking starts on journey begin
- [ ] Points recorded at configured interval
- [ ] Foreground notification visible on Android
- [ ] Location broadcast via Supabase Realtime
- [ ] Tracking stops when journey completes
- [ ] Old points auto-purged after 30 days
