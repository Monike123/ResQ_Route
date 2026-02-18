import 'package:geolocator/geolocator.dart';

/// Handles device location permissions and position retrieval.
class LocationService {
  /// Default position (Bangalore) when location is unavailable.
  static const double defaultLat = 12.9716;
  static const double defaultLng = 77.5946;

  /// Ensures location services and permissions are available.
  /// Returns true if permission is granted.
  Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  /// Gets the current device position.
  /// Falls back to default (Bangalore) if unavailable.
  Future<Position> getCurrentPosition() async {
    final hasPermission = await ensurePermission();
    if (!hasPermission) {
      return Position(
        latitude: defaultLat,
        longitude: defaultLng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Returns a stream of position updates for live tracking.
  Stream<Position> getPositionStream({
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }
}
