import 'package:equatable/equatable.dart';

/// Clean domain entity for a route.
class RouteEntity extends Equatable {
  final String id;
  final double distanceKm;
  final int durationMin;
  final double? safetyScore;
  final String status;
  final int routeIndex;
  final String? startAddress;
  final String? endAddress;
  final String polylineEncoded;
  final List<Map<String, double>> waypoints;

  const RouteEntity({
    required this.id,
    required this.distanceKm,
    required this.durationMin,
    this.safetyScore,
    required this.status,
    required this.routeIndex,
    this.startAddress,
    this.endAddress,
    required this.polylineEncoded,
    required this.waypoints,
  });

  String get label {
    switch (routeIndex) {
      case 0:
        return 'Safest';
      case 1:
        return 'Balanced';
      case 2:
        return 'Shortest';
      default:
        return 'Route ${routeIndex + 1}';
    }
  }

  bool get isScored => safetyScore != null;
  bool get isCalculating => status == 'calculating';

  @override
  List<Object?> get props => [id];
}
