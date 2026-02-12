# 01 — SOS Trigger Mechanisms

## Objective
Implement multiple SOS trigger methods — button press, voice, deadman switch, shake — with false-trigger prevention.

---

## Trigger Methods

### 1. SOS Button (Primary)

```
┌─────────────────────────────────┐
│         JOURNEY ACTIVE          │
│                                 │
│         [Map View]              │
│                                 │
│  ┌─────────────────────────┐    │
│  │    🆘 HOLD FOR SOS      │    │
│  │    ████████░░░░ 2s       │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

**Interaction**: Hold button for 3 seconds OR double-tap rapidly.

```dart
class SOSButton extends StatefulWidget {
  @override
  _SOSButtonState createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> {
  bool _isHolding = false;
  double _holdProgress = 0;
  Timer? _holdTimer;
  DateTime? _lastTap;
  static const holdDuration = Duration(seconds: 3);

  void _onTapDown(TapDownDetails _) {
    // Check for double-tap
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) < Duration(milliseconds: 500)) {
      _triggerSOS();
      return;
    }
    _lastTap = now;

    // Start hold
    setState(() => _isHolding = true);
    _holdTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      setState(() {
        _holdProgress += 50 / holdDuration.inMilliseconds;
        if (_holdProgress >= 1.0) {
          timer.cancel();
          _triggerSOS();
        }
      });
    });
  }

  void _onTapUp(TapUpDetails _) {
    _holdTimer?.cancel();
    setState(() { _isHolding = false; _holdProgress = 0; });
  }

  void _triggerSOS() {
    HapticFeedback.heavyImpact();
    // Delegate to SOS service
    context.read(sosServiceProvider).trigger(SOSTriggerType.button);
  }
}
```

### 2. Voice Trigger
Handled by `VoiceRecognitionService` (Phase 5, file 04).

### 3. Deadman Switch
Handled by `DeadmanSwitchService` (Phase 5, file 03).

### 4. Shake Trigger (Optional)
```dart
class ShakeDetector {
  static const double _shakeThreshold = 15.0; // m/s²
  static const int _shakeCountTrigger = 4;
  static const Duration _shakeWindow = Duration(seconds: 2);
  
  int _shakeCount = 0;
  DateTime? _firstShake;

  void onAccelerometerEvent(AccelerometerEvent event) {
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    
    if (magnitude > _shakeThreshold) {
      _shakeCount++;
      _firstShake ??= DateTime.now();
      
      if (DateTime.now().difference(_firstShake!) > _shakeWindow) {
        _shakeCount = 1;
        _firstShake = DateTime.now();
      }
      
      if (_shakeCount >= _shakeCountTrigger) {
        _triggerSOS();
        _reset();
      }
    }
  }
}
```

---

## SOS Service

```dart
class SOSService {
  final SupabaseClient _client;
  final TwilioService _twilioService;
  final LocationService _locationService;
  final ForensicService _forensicService;

  Future<void> trigger(SOSTriggerType type) async {
    final user = _client.auth.currentUser!;
    final position = await Geolocator.getCurrentPosition();
    
    // 1. Create SOS event
    final trackingId = _generateTrackingId();
    final { data: sosEvent } = await _client.from('sos_events').insert({
      'user_id': user.id,
      'journey_id': _currentJourneyId,
      'trigger_type': type.name,
      'location': 'POINT(${position.longitude} ${position.latitude})',
      'tracking_link_id': trackingId,
      'tracking_link_expires_at': DateTime.now().add(Duration(hours: 24)).toIso8601String(),
    }).select().single();

    // 2. Send SMS to emergency contacts (parallel)
    final contacts = await _getEmergencyContacts(user.id);
    await Future.wait(contacts.map((c) => _twilioService.sendSMS(
      to: c.phone,
      userName: user.userMetadata?['full_name'] ?? 'ResQ Route User',
      lat: position.latitude,
      lng: position.longitude,
      trackingLink: 'https://resqroute.app/track/$trackingId',
    )));

    // 3. Capture forensic snapshot
    await _forensicService.captureSnapshot(sosEvent['id'], position);

    // 4. Switch journey state to SOS
    await _client.from('journeys')
        .update({'status': 'sos'})
        .eq('id', _currentJourneyId);
  }

  String _generateTrackingId() {
    return DateTime.now().millisecondsSinceEpoch.toRadixString(36) +
           Random.secure().nextInt(999999).toRadixString(36);
  }
}
```

---

## Verification
- [ ] SOS button requires 3-second hold or double-tap
- [ ] Voice trigger calls SOS service
- [ ] Deadman switch auto-triggers SOS
- [ ] Shake trigger fires after 4 rapid shakes
- [ ] SOS event created in database
- [ ] SMS sent to all 3 contacts
- [ ] Forensic snapshot captured
- [ ] Tracking link generated
