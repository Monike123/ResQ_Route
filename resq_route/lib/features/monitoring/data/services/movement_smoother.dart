import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

/// Kalman-filter-based GPS smoother to remove noise and drift.
///
/// Also filters speed anomalies (teleportation) that occur when
/// GPS locks shift suddenly.
class MovementSmoother {
  double _lat = 0;
  double _lng = 0;
  double _variance = -1; // < 0 signals "uninitialised"
  Position? _lastSmoothed;
  DateTime? _lastTimestamp;

  static const double _minAccuracy = 1.0;
  static const double _maxSpeedKmh = 150; // walking/driving cap
  static const double _maxJumpMeters = 500; // reject GPS teleport

  /// Smooth a raw GPS reading. Returns corrected [Position] or `null`
  /// if the reading should be discarded (speed anomaly / teleport).
  Position? smooth(Position raw) {
    final accuracy =
        raw.accuracy < _minAccuracy ? _minAccuracy : raw.accuracy;

    // ── Speed anomaly check ──
    if (_lastSmoothed != null && _lastTimestamp != null) {
      final elapsed =
          raw.timestamp.difference(_lastTimestamp!).inMilliseconds / 1000.0;
      if (elapsed > 0) {
        final dist = Geolocator.distanceBetween(
          _lastSmoothed!.latitude,
          _lastSmoothed!.longitude,
          raw.latitude,
          raw.longitude,
        );
        // Reject if > 500 m jump in < 5 seconds
        if (dist > _maxJumpMeters && elapsed < 5) return null;
        // Reject if speed > 150 km/h
        final speedKmh = (dist / elapsed) * 3.6;
        if (speedKmh > _maxSpeedKmh) return null;
      }
    }

    // ── Kalman filter ──
    if (_variance < 0) {
      // First reading — initialise
      _lat = raw.latitude;
      _lng = raw.longitude;
      _variance = accuracy * accuracy;
    } else {
      final k = _variance / (_variance + accuracy * accuracy);
      _lat += k * (raw.latitude - _lat);
      _lng += k * (raw.longitude - _lng);
      _variance = (1 - k) * _variance;
    }

    final smoothed = Position(
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

    _lastSmoothed = smoothed;
    _lastTimestamp = raw.timestamp;
    return smoothed;
  }

  /// Reset filter state (e.g. on new journey start).
  void reset() {
    _lat = 0;
    _lng = 0;
    _variance = -1;
    _lastSmoothed = null;
    _lastTimestamp = null;
  }
}
