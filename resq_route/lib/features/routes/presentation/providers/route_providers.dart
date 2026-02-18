import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/location_service.dart';
import '../../../home/data/services/recent_searches_service.dart';
import '../../data/datasources/routes_remote_datasource.dart';
import '../../data/models/place_prediction_model.dart';
import '../../data/models/route_model.dart';
import '../../data/models/unsafe_zone_model.dart';
import '../../data/repositories/route_repository_impl.dart';
import '../../domain/repositories/route_repository.dart';
import '../../domain/usecases/fetch_routes_usecase.dart';
import '../../domain/usecases/search_places_usecase.dart';

// ── Core Providers ──

final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

final locationServiceProvider = Provider<LocationService>(
  (_) => LocationService(),
);

// ── Data Layer Providers ──

final routesDataSourceProvider = Provider<RoutesRemoteDataSource>(
  (ref) => RoutesRemoteDataSource(ref.read(supabaseClientProvider)),
);

final routeRepositoryProvider = Provider<RouteRepository>(
  (ref) => RouteRepositoryImpl(ref.read(routesDataSourceProvider)),
);

final recentSearchesServiceProvider = FutureProvider<RecentSearchesService>(
  (_) async {
    final prefs = await SharedPreferences.getInstance();
    return RecentSearchesService(prefs);
  },
);

// ── Use Case Providers ──

final fetchRoutesUseCaseProvider = Provider<FetchRoutesUseCase>(
  (ref) => FetchRoutesUseCase(ref.read(routeRepositoryProvider)),
);

final searchPlacesUseCaseProvider = Provider<SearchPlacesUseCase>(
  (ref) => SearchPlacesUseCase(ref.read(routeRepositoryProvider)),
);

// ── State Providers ──

/// Current search results from Places Autocomplete.
final searchResultsProvider =
    StateProvider<List<PlacePredictionModel>>((ref) => []);

/// Currently selected destination.
final selectedDestinationProvider =
    StateProvider<PlaceDetailsModel?>((ref) => null);

/// Fetched routes for selected destination.
final fetchedRoutesProvider = StateProvider<List<RouteModel>>((ref) => []);

/// Currently selected route ID.
final selectedRouteIdProvider = StateProvider<String?>((ref) => null);

/// Nearby unsafe zones.
final unsafeZonesProvider = StateProvider<List<UnsafeZoneModel>>((ref) => []);

/// Loading states.
final isSearchingProvider = StateProvider<bool>((ref) => false);
final isFetchingRoutesProvider = StateProvider<bool>((ref) => false);

/// Search error.
final searchErrorProvider = StateProvider<String?>((ref) => null);

/// Recent searches from local storage.
final recentSearchesProvider =
    FutureProvider<List<PlaceDetailsModel>>((ref) async {
  final service = await ref.read(recentSearchesServiceProvider.future);
  return service.getRecentSearches();
});
