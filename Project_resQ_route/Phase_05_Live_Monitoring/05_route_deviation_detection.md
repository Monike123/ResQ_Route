# 05 — Route Deviation Detection

## Objective
Detect when a user deviates from their selected route and alert them with re-routing options.

---

## Detection Logic

```dart
class RouteDeviationDetector {
  static const double deviationThresholdMeters = 100;
  static const int consecutiveDeviationsForAlert = 3;
  
  List<LatLng> _routeWaypoints = [];
  int _consecutiveDeviations = 0;

  void setRoute(List<LatLng> waypoints) {
    _routeWaypoints = waypoints;
    _consecutiveDeviations = 0;
  }

  DeviationResult checkDeviation(Position currentPosition) {
    double minDistance = double.infinity;
    
    // Find closest point on route
    for (int i = 0; i < _routeWaypoints.length - 1; i++) {
      final dist = _distanceToSegment(
        LatLng(currentPosition.latitude, currentPosition.longitude),
        _routeWaypoints[i],
        _routeWaypoints[i + 1],
      );
      if (dist < minDistance) minDistance = dist;
    }

    if (minDistance > deviationThresholdMeters) {
      _consecutiveDeviations++;
      if (_consecutiveDeviations >= consecutiveDeviationsForAlert) {
        return DeviationResult.alert;
      }
      return DeviationResult.warning;
    } else {
      _consecutiveDeviations = 0;
      return DeviationResult.onRoute;
    }
  }
}
```

## Alert UI

```
┌────────────────────────────────┐
│  🔔 Route Deviation Detected   │
│                                │
│  You are 150m off your         │
│  planned route.                │
│                                │
│  [ RECALCULATE ROUTE ]         │
│  [ DISMISS ]                   │
└────────────────────────────────┘
```

---

## Verification
- [ ] Deviation detected when > 100m from route
- [ ] Alert after 3 consecutive deviation points
- [ ] Recalculate option fetches new routes
- [ ] On-route resets deviation counter
