# 03 — Battery Verification

## Objective
Verify that battery consumption during active journeys stays within acceptable limits.

---

## Battery Targets

| Mode | Target Drain/Hour | Measurement |
|------|-------------------|-------------|
| Active journey (GPS + voice) | < 5% | Device battery API |
| Active journey (GPS only) | < 3% | Device battery API |
| Background (paused) | < 1% | Device battery API |
| Idle (no journey) | < 0.5% | Device battery API |

## Test Protocol

1. Charge device to 100%
2. Start ResQ Route with a test journey
3. Walk for 1 hour on a known route
4. Record battery level every 15 minutes
5. Compare against targets

### Battery Logging

```dart
import 'package:battery_plus/battery_plus.dart';

class BatteryMonitor {
  final Battery _battery = Battery();
  final List<BatteryReading> _readings = [];

  Future<void> logReading() async {
    final level = await _battery.batteryLevel;
    _readings.add(BatteryReading(
      level: level,
      timestamp: DateTime.now(),
      gpsActive: _locationService.isTracking,
      voiceActive: _voiceService.isListening,
    ));
  }

  double calculateDrainPerHour() {
    if (_readings.length < 2) return 0;
    final first = _readings.first;
    final last = _readings.last;
    final hours = last.timestamp.difference(first.timestamp).inMinutes / 60;
    return (first.level - last.level) / hours;
  }
}
```

## Optimization Verification

Confirm Phase 5's adaptive GPS strategy works:
- Battery > 50%: GPS every 5s ✓
- Battery 30-50%: GPS every 10s ✓
- Battery 15-30%: GPS every 20s, voice paused ✓
- Battery < 15%: GPS every 30s, warning shown ✓

---

## Verification
- [ ] Battery drain measured on physical device
- [ ] Active journey < 5%/hour
- [ ] Adaptive GPS intervals confirmed
- [ ] Low battery warning triggers correctly
