import '../../data/models/route_model.dart';
import '../repositories/route_repository.dart';

/// Fetches 3 alternative routes between origin and destination.
class FetchRoutesUseCase {
  final RouteRepository _repository;

  FetchRoutesUseCase(this._repository);

  Future<List<RouteModel>> execute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String userId,
  }) async {
    // Validate coordinates
    if (!_isValidLatLng(originLat, originLng)) {
      throw ArgumentError('Invalid origin coordinates');
    }
    if (!_isValidLatLng(destLat, destLng)) {
      throw ArgumentError('Invalid destination coordinates');
    }

    return _repository.fetchRoutes(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      userId: userId,
    );
  }

  bool _isValidLatLng(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }
}
