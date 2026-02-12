# 06 — Movement Smoothing

## Objective
Filter GPS noise and drift to provide stable position data for tracking, deviation detection, and deadman switch.

---

## Kalman Filter Implementation

```dart
class MovementSmoother {
  double _lat = 0, _lng = 0;
  double _variance = -1;        // Initially unknown
  static const double minAccuracy = 1.0;

  Position smooth(Position raw) {
    final accuracy = raw.accuracy < minAccuracy ? minAccuracy : raw.accuracy;
    
    if (_variance < 0) {
      // First reading
      _lat = raw.latitude;
      _lng = raw.longitude;
      _variance = accuracy * accuracy;
    } else {
      // Kalman gain
      final k = _variance / (_variance + accuracy * accuracy);
      _lat += k * (raw.latitude - _lat);
      _lng += k * (raw.longitude - _lng);
      _variance = (1 - k) * _variance;
    }

    return Position(
      latitude: _lat,
      longitude: _lng,
      accuracy: math.sqrt(_variance),
      speed: raw.speed,
      heading: raw.heading,
      timestamp: raw.timestamp,
      altitudeAccuracy: raw.altitudeAccuracy,
      headingAccuracy: raw.headingAccuracy,
      altitude: raw.altitude,
      speedAccuracy: raw.speedAccuracy,
    );
  }
}
```

## Speed Anomaly Detection
- If speed > 150 km/h for a walking journey → discard point (GPS teleport)
- If sudden jump > 500m in < 5 seconds → discard point

---

## Verification
- [ ] GPS drift smoothed out
- [ ] Speed anomalies filtered
- [ ] Smooth position updates on map
