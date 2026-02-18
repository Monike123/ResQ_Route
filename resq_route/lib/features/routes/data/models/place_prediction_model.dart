import 'package:equatable/equatable.dart';

/// Model for a Google Places Autocomplete prediction.
class PlacePredictionModel extends Equatable {
  final String placeId;
  final String description;
  final String mainText;
  final String? secondaryText;

  const PlacePredictionModel({
    required this.placeId,
    required this.description,
    required this.mainText,
    this.secondaryText,
  });

  factory PlacePredictionModel.fromJson(Map<String, dynamic> json) {
    return PlacePredictionModel(
      placeId: json['placeId'] as String? ?? json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      mainText: json['mainText'] as String? ??
          json['main_text'] as String? ??
          '',
      secondaryText: json['secondaryText'] as String? ??
          json['secondary_text'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'placeId': placeId,
        'description': description,
        'mainText': mainText,
        'secondaryText': secondaryText,
      };

  @override
  List<Object?> get props => [placeId];
}

/// Resolved place details (lat/lng from Place ID).
class PlaceDetailsModel extends Equatable {
  final String placeId;
  final double lat;
  final double lng;
  final String name;
  final String address;

  const PlaceDetailsModel({
    required this.placeId,
    required this.lat,
    required this.lng,
    required this.name,
    required this.address,
  });

  factory PlaceDetailsModel.fromJson(Map<String, dynamic> json) {
    return PlaceDetailsModel(
      placeId: json['placeId'] as String? ?? json['place_id'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ??
          json['formatted_address'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toJson() => {
        'placeId': placeId,
        'lat': lat,
        'lng': lng,
        'name': name,
        'address': address,
      };

  @override
  List<Object?> get props => [placeId];
}
