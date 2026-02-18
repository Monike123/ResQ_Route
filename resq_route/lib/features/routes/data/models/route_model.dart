import 'package:equatable/equatable.dart';

/// Model for a computed route with waypoints and safety data.
class RouteModel extends Equatable {
  final String? id;
  final String userId;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final List<Map<String, double>> waypoints;
  final String polylineEncoded;
  final double distanceKm;
  final int durationMin;
  final double? safetyScore;
  final String status; // 'calculating', 'scored', 'selected', 'error'
  final int routeIndex;
  final Map<String, dynamic>? safetyBreakdown;
  final String? startAddress;
  final String? endAddress;
  final DateTime? createdAt;

  const RouteModel({
    this.id,
    required this.userId,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    required this.waypoints,
    required this.polylineEncoded,
    required this.distanceKm,
    required this.durationMin,
    this.safetyScore,
    this.status = 'calculating',
    this.routeIndex = 0,
    this.safetyBreakdown,
    this.startAddress,
    this.endAddress,
    this.createdAt,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      originLat: (json['origin_lat'] as num?)?.toDouble() ?? 0,
      originLng: (json['origin_lng'] as num?)?.toDouble() ?? 0,
      destLat: (json['dest_lat'] as num?)?.toDouble() ?? 0,
      destLng: (json['dest_lng'] as num?)?.toDouble() ?? 0,
      waypoints: (json['waypoints'] as List<dynamic>?)
              ?.map((w) => {
                    'lat': (w['lat'] as num).toDouble(),
                    'lng': (w['lng'] as num).toDouble(),
                  })
              .toList() ??
          [],
      polylineEncoded: json['polyline_encoded'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      durationMin: (json['duration_min'] as num?)?.toInt() ?? 0,
      safetyScore: (json['safety_score'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'calculating',
      routeIndex: (json['route_index'] as num?)?.toInt() ?? 0,
      safetyBreakdown: json['safety_breakdown'] as Map<String, dynamic>?,
      startAddress: json['start_address'] as String?,
      endAddress: json['end_address'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'origin_lat': originLat,
        'origin_lng': originLng,
        'dest_lat': destLat,
        'dest_lng': destLng,
        'waypoints': waypoints,
        'polyline_encoded': polylineEncoded,
        'distance_km': distanceKm,
        'duration_min': durationMin,
        'safety_score': safetyScore,
        'status': status,
        'route_index': routeIndex,
        'safety_breakdown': safetyBreakdown,
        'start_address': startAddress,
        'end_address': endAddress,
      };

  /// Label for display (Safest / Balanced / Shortest).
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

  RouteModel copyWith({
    String? id,
    double? safetyScore,
    String? status,
    Map<String, dynamic>? safetyBreakdown,
  }) {
    return RouteModel(
      id: id ?? this.id,
      userId: userId,
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      waypoints: waypoints,
      polylineEncoded: polylineEncoded,
      distanceKm: distanceKm,
      durationMin: durationMin,
      safetyScore: safetyScore ?? this.safetyScore,
      status: status ?? this.status,
      routeIndex: routeIndex,
      safetyBreakdown: safetyBreakdown ?? this.safetyBreakdown,
      startAddress: startAddress,
      endAddress: endAddress,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, routeIndex];
}
