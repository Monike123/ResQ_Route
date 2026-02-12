# 07 — Battery Optimization

## Objective
Minimize battery drain during active journeys by adapting GPS frequency, managing background services, and providing battery-aware behavior.

---

## Adaptive GPS Strategy

| Battery Level | GPS Interval | Accuracy | Voice Listening |
|---------------|-------------|----------|-----------------|
| > 50% | 5 seconds | High | Active |
| 30-50% | 10 seconds | Balanced | Active |
| 15-30% | 20 seconds | Low | Paused |
| < 15% | 30 seconds | Low | Paused |
| < 5% | 60 seconds | Lowest | Paused (save-mode SMS fallback) |

```dart
class BatteryAwareLocationService {
  void adjustSettingsForBattery(int batteryLevel) {
    if (batteryLevel > 50) {
      _setInterval(Duration(seconds: 5), LocationAccuracy.high);
    } else if (batteryLevel > 30) {
      _setInterval(Duration(seconds: 10), LocationAccuracy.medium);
    } else if (batteryLevel > 15) {
      _setInterval(Duration(seconds: 20), LocationAccuracy.low);
      _voiceService.pause();  // Save battery
    } else {
      _setInterval(Duration(seconds: 30), LocationAccuracy.lowest);
      _showLowBatteryWarning();
    }
  }
}
```

## Low Battery Warning

```
⚠️ Low Battery (12%)
Your safety monitoring may be affected.
Consider plugging in or ending your journey.

[SEND LOCATION TO CONTACTS NOW]
```

At < 5%, auto-send last known location to emergency contacts as SMS precaution.

---

## Verification
- [ ] GPS interval increases as battery drops
- [ ] Voice recognition paused below 30%
- [ ] Low battery warning displayed
- [ ] Emergency contacts alerted at < 5%
