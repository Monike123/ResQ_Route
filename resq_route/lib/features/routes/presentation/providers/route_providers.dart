import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/location_service.dart';
import '../../../home/data/services/recent_searches_service.dart';
import '../../data/datasources/routes_remote_datasource.dart';
import '../../data/datasources/ai_analysis_datasource.dart';
import '../../data/models/place_prediction_model.dart';
import '../../data/models/route_model.dart';
import '../../data/models/unsafe_zone_model.dart';
import '../../data/models/ai_analysis_model.dart';
import '../../data/repositories/route_repository_impl.dart';
import '../../data/services/safety_score_service.dart';
import '../../data/services/route_ranking_service.dart';
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

// ── Phase 4: Safety Scoring Providers ──

final safetyScoreServiceProvider = Provider<SafetyScoreService>(
  (_) => SafetyScoreService(),
);

final aiAnalysisDatasourceProvider = Provider<AiAnalysisDatasource>(
  (ref) => AiAnalysisDatasource(ref.read(supabaseClientProvider)),
);

final routeRankingServiceProvider = Provider<RouteRankingService>(
  (_) => RouteRankingService(),
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

// ── Phase 4: AI State Providers ──

/// AI analysis per route ID.
final aiAnalysisMapProvider =
    StateProvider<Map<String, AiAnalysisModel>>((ref) => {});

/// Safety breakdown per route ID (from scoring service).
final safetyBreakdownMapProvider =
    StateProvider<Map<String, SafetyResult>>((ref) => {});

/// Whether safety scoring is in progress.
final isScoringProvider = StateProvider<bool>((ref) => false);
