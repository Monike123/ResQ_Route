import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Result of a deviation check.
enum DeviationResult { onRoute, warning, alert }

/// Detects when a user strays from the planned route.
///
/// Triggers after 3 consecutive readings > 100 m from the nearest
/// route segment.
class RouteDeviationDetector {
  static const double deviationThresholdMeters = 100;
  static const int consecutiveDeviationsForAlert = 3;

  List<LatLng> _routeWaypoints = [];
  int _consecutiveDeviations = 0;
  double _lastDeviationMeters = 0;

  /// Load waypoints for the selected route.
  void setRoute(List<LatLng> waypoints) {
    _routeWaypoints = waypoints;
    _consecutiveDeviations = 0;
    _lastDeviationMeters = 0;
  }

  double get lastDeviationMeters => _lastDeviationMeters;

  /// Check if current position deviates from route.
  DeviationResult checkDeviation(Position currentPosition) {
    if (_routeWaypoints.length < 2) return DeviationResult.onRoute;

    double minDistance = double.infinity;

    // Find closest distance from position to any route segment
    for (int i = 0; i < _routeWaypoints.length - 1; i++) {
      final dist = _distanceToSegment(
        LatLng(currentPosition.latitude, currentPosition.longitude),
        _routeWaypoints[i],
        _routeWaypoints[i + 1],
      );
      if (dist < minDistance) minDistance = dist;
    }

    _lastDeviationMeters = minDistance;

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

  /// Reset counter (e.g. after recalculating route).
  void reset() {
    _consecutiveDeviations = 0;
    _lastDeviationMeters = 0;
  }

  // ── Geometry helpers ──

  /// Distance from point P to line segment AB (in meters).
  double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final ap = _toMeters(a, p);
    final ab = _toMeters(a, b);

    final abLen2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLen2 == 0) {
      // A and B are the same point
      return Geolocator.distanceBetween(
          p.latitude, p.longitude, a.latitude, a.longitude);
    }

    // Project P onto line AB, clamped to segment
    double t = (ap.dx * ab.dx + ap.dy * ab.dy) / abLen2;
    t = t.clamp(0.0, 1.0);

    final closestLat = a.latitude + t * (b.latitude - a.latitude);
    final closestLng = a.longitude + t * (b.longitude - a.longitude);

    return Geolocator.distanceBetween(
        p.latitude, p.longitude, closestLat, closestLng);
  }

  /// Convert lat/lng difference to approximate meters offset.
  _Offset _toMeters(LatLng from, LatLng to) {
    final dx = Geolocator.distanceBetween(
            from.latitude, from.longitude, from.latitude, to.longitude) *
        (to.longitude >= from.longitude ? 1 : -1);
    final dy = Geolocator.distanceBetween(
            from.latitude, from.longitude, to.latitude, from.longitude) *
        (to.latitude >= from.latitude ? 1 : -1);
    return _Offset(dx, dy);
  }
}

class _Offset {
  final double dx;
  final double dy;
  const _Offset(this.dx, this.dy);
}
