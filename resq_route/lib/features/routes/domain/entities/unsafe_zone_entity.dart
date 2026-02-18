import 'package:equatable/equatable.dart';

/// Clean domain entity for an unsafe zone.
class UnsafeZoneEntity extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final String reason;
  final String severity;
  final double confidenceScore;
  final bool verified;
  final int flagCount;
  final double? distanceKm;

  const UnsafeZoneEntity({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.reason,
    required this.severity,
    required this.confidenceScore,
    required this.verified,
    required this.flagCount,
    this.distanceKm,
  });

  bool get isCritical => severity == 'critical';
  bool get isHigh => severity == 'high';

  @override
  List<Object?> get props => [id];
}
