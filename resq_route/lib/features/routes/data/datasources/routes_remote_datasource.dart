import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_model.dart';
import '../models/unsafe_zone_model.dart';
import '../models/place_prediction_model.dart';

/// Remote data source for routes, places, and unsafe zones via Supabase.
class RoutesRemoteDataSource {
  final SupabaseClient _client;

  RoutesRemoteDataSource(this._client);

  // ── Places Search (via Edge Function) ──

  /// Search places using Google Places Autocomplete (proxied).
  Future<List<PlacePredictionModel>> searchPlaces({
    required String query,
    required double lat,
    required double lng,
  }) async {
    if (query.length < 3) return [];

    final response = await _client.functions.invoke(
      'places-autocomplete',
      body: {'query': query, 'lat': lat, 'lng': lng},
    );

    final data = response.data as Map<String, dynamic>;
    return (data['predictions'] as List<dynamic>? ?? [])
        .map((p) => PlacePredictionModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// Get place coordinates from Place ID.
  Future<PlaceDetailsModel> getPlaceDetails(String placeId) async {
    final response = await _client.functions.invoke(
      'place-details',
      body: {'placeId': placeId},
    );
    return PlaceDetailsModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Route Fetching (via Edge Function) ──

  /// Fetch 3 alternative routes between origin and destination.
  Future<List<RouteModel>> fetchRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String userId,
  }) async {
    final response = await _client.functions.invoke(
      'calculate-routes',
      body: {
        'originLat': originLat,
        'originLng': originLng,
        'destLat': destLat,
        'destLng': destLng,
        'userId': userId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return (data['routes'] as List<dynamic>? ?? [])
        .map((r) => RouteModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Select a route (update status to 'selected').
  Future<void> selectRoute(String routeId) async {
    await _client
        .from('routes')
        .update({'status': 'selected'}).eq('id', routeId);
  }

  // ── Unsafe Zones ──

  /// Fetch nearby unsafe zones using PostGIS function.
  Future<List<UnsafeZoneModel>> getNearbyUnsafeZones({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    final response = await _client.rpc('get_nearby_unsafe_zones', params: {
      'user_lat': lat,
      'user_lng': lng,
      'radius_km': radiusKm,
    });

    return (response as List<dynamic>)
        .map((z) => UnsafeZoneModel.fromJson(z as Map<String, dynamic>))
        .toList();
  }

  /// Report (flag) an unsafe zone.
  Future<void> flagUnsafeZone(UnsafeZoneModel zone) async {
    await _client.from('unsafe_zones').insert(zone.toInsertJson());
  }

  // ── Real-time Score Updates ──

  /// Stream route updates for real-time safety score changes.
  Stream<List<Map<String, dynamic>>> watchRouteUpdates(
      List<String> routeIds) {
    return _client
        .from('routes')
        .stream(primaryKey: ['id'])
        .inFilter('id', routeIds);
  }

  // ── User's recent routes ──

  /// Get the user's most recent routes.
  Future<List<RouteModel>> getRecentRoutes({
    required String userId,
    int limit = 10,
  }) async {
    final response = await _client
        .from('routes')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List<dynamic>)
        .map((r) => RouteModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
