import 'package:equatable/equatable.dart';

/// Model for an unsafe zone with severity and geospatial data.
class UnsafeZoneModel extends Equatable {
  final String? id;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final String reason;
  final String severity; // 'low', 'medium', 'high', 'critical'
  final double confidenceScore;
  final String? reportedBy;
  final bool verified;
  final int flagCount;
  final String? photoUrl;
  final double? distanceKm;

  const UnsafeZoneModel({
    this.id,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200,
    required this.reason,
    this.severity = 'medium',
    this.confidenceScore = 0.5,
    this.reportedBy,
    this.verified = false,
    this.flagCount = 1,
    this.photoUrl,
    this.distanceKm,
  });

  factory UnsafeZoneModel.fromJson(Map<String, dynamic> json) {
    return UnsafeZoneModel(
      id: json['id'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num?)?.toInt() ?? 200,
      reason: json['reason'] as String? ?? 'Unknown',
      severity: json['severity'] as String? ?? 'medium',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.5,
      reportedBy: json['reported_by'] as String?,
      verified: json['verified'] as bool? ?? false,
      flagCount: (json['flag_count'] as num?)?.toInt() ?? 1,
      photoUrl: json['photo_url'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'location': 'POINT($longitude $latitude)',
        'radius_meters': radiusMeters,
        'reason': reason,
        'severity': severity,
        'reported_by': reportedBy,
      };

  @override
  List<Object?> get props => [id, latitude, longitude];
}
