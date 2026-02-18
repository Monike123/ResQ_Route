import '../datasources/routes_remote_datasource.dart';
import '../models/route_model.dart';
import '../models/unsafe_zone_model.dart';
import '../models/place_prediction_model.dart';
import '../../domain/repositories/route_repository.dart';

/// Repository implementation for route operations.
class RouteRepositoryImpl implements RouteRepository {
  final RoutesRemoteDataSource _dataSource;

  RouteRepositoryImpl(this._dataSource);

  @override
  Future<List<PlacePredictionModel>> searchPlaces({
    required String query,
    required double lat,
    required double lng,
  }) async {
    try {
      return await _dataSource.searchPlaces(
        query: query,
        lat: lat,
        lng: lng,
      );
    } catch (e) {
      throw Exception('Failed to search places: $e');
    }
  }

  @override
  Future<PlaceDetailsModel> getPlaceDetails(String placeId) async {
    try {
      return await _dataSource.getPlaceDetails(placeId);
    } catch (e) {
      throw Exception('Failed to get place details: $e');
    }
  }

  @override
  Future<List<RouteModel>> fetchRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String userId,
  }) async {
    try {
      return await _dataSource.fetchRoutes(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
        userId: userId,
      );
    } catch (e) {
      throw Exception('Failed to fetch routes: $e');
    }
  }

  @override
  Future<void> selectRoute(String routeId) async {
    try {
      await _dataSource.selectRoute(routeId);
    } catch (e) {
      throw Exception('Failed to select route: $e');
    }
  }

  @override
  Future<List<UnsafeZoneModel>> getNearbyUnsafeZones({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    try {
      return await _dataSource.getNearbyUnsafeZones(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      );
    } catch (e) {
      throw Exception('Failed to get unsafe zones: $e');
    }
  }

  @override
  Future<void> flagUnsafeZone(UnsafeZoneModel zone) async {
    try {
      await _dataSource.flagUnsafeZone(zone);
    } catch (e) {
      throw Exception('Failed to flag unsafe zone: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchRouteUpdates(
      List<String> routeIds) {
    return _dataSource.watchRouteUpdates(routeIds);
  }
}
