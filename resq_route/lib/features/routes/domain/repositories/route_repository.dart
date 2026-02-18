import '../../data/models/route_model.dart';
import '../../data/models/unsafe_zone_model.dart';
import '../../data/models/place_prediction_model.dart';

/// Abstract repository for route operations — domain boundary.
abstract class RouteRepository {
  /// Search places via Google Places Autocomplete.
  Future<List<PlacePredictionModel>> searchPlaces({
    required String query,
    required double lat,
    required double lng,
  });

  /// Get coordinates from place ID.
  Future<PlaceDetailsModel> getPlaceDetails(String placeId);

  /// Fetch 3 alternative routes.
  Future<List<RouteModel>> fetchRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String userId,
  });

  /// Mark a route as selected.
  Future<void> selectRoute(String routeId);

  /// Get nearby unsafe zones via PostGIS.
  Future<List<UnsafeZoneModel>> getNearbyUnsafeZones({
    required double lat,
    required double lng,
    double radiusKm = 5,
  });

  /// Flag (report) an unsafe zone.
  Future<void> flagUnsafeZone(UnsafeZoneModel zone);

  /// Stream real-time route score updates.
  Stream<List<Map<String, dynamic>>> watchRouteUpdates(List<String> routeIds);
}
