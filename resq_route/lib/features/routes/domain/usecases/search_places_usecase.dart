import 'dart:async';
import '../../data/models/place_prediction_model.dart';
import '../repositories/route_repository.dart';

/// Debounced places search use case.
class SearchPlacesUseCase {
  final RouteRepository _repository;
  Timer? _debounceTimer;

  SearchPlacesUseCase(this._repository);

  /// Search with 500ms debounce to prevent API spam.
  Future<List<PlacePredictionModel>> execute({
    required String query,
    required double lat,
    required double lng,
  }) async {
    if (query.trim().length < 3) return [];

    // Cancel any pending debounce
    _debounceTimer?.cancel();

    final completer = Completer<List<PlacePredictionModel>>();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await _repository.searchPlaces(
          query: query.trim(),
          lat: lat,
          lng: lng,
        );
        if (!completer.isCompleted) completer.complete(results);
      } catch (e) {
        if (!completer.isCompleted) completer.completeError(e);
      }
    });

    return completer.future;
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
