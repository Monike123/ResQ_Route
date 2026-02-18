import 'dart:math' as math;

/// Geospatial utility functions.
class GeoUtils {
  GeoUtils._();

  /// Calculate distance between two lat/lng points in meters (Haversine formula).
  static double distanceInMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Convert degrees to radians.
  static double _toRadians(double degrees) => degrees * math.pi / 180;

  /// Check if a point is within a given radius of another point.
  static bool isWithinRadius(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
    double radiusMeters,
  ) {
    return distanceInMeters(lat1, lng1, lat2, lng2) <= radiusMeters;
  }
}
