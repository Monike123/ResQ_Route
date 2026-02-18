import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/unsafe_zone_model.dart';
import '../../data/models/route_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Google Maps widget with unsafe zone circles, route polylines, and markers.
class SafetyMap extends StatefulWidget {
  final List<UnsafeZoneModel> unsafeZones;
  final LatLng? destination;
  final List<RouteModel>? routes;
  final String? selectedRouteId;
  final LatLng currentPosition;
  final Function(LatLng)? onMapTap;
  final Function(GoogleMapController)? onMapCreated;

  const SafetyMap({
    super.key,
    required this.unsafeZones,
    this.destination,
    this.routes,
    this.selectedRouteId,
    required this.currentPosition,
    this.onMapTap,
    this.onMapCreated,
  });

  @override
  State<SafetyMap> createState() => _SafetyMapState();
}

class _SafetyMapState extends State<SafetyMap> {

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // Current location
    markers.add(Marker(
      markerId: const MarkerId('current_location'),
      position: widget.currentPosition,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'You are here'),
    ));

    // Destination
    if (widget.destination != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Destination'),
      ));
    }

    // Unsafe zone markers
    for (final zone in widget.unsafeZones) {
      markers.add(Marker(
        markerId: MarkerId('unsafe_${zone.id}'),
        position: LatLng(zone.latitude, zone.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: '⚠️ ${zone.severity.toUpperCase()}',
          snippet: zone.reason,
        ),
      ));
    }

    return markers;
  }

  Set<Circle> _buildCircles() {
    return widget.unsafeZones.map((zone) {
      return Circle(
        circleId: CircleId('zone_${zone.id}'),
        center: LatLng(zone.latitude, zone.longitude),
        radius: zone.radiusMeters.toDouble(),
        fillColor: _getSeverityColor(zone.severity).withValues(alpha: _getOpacity(zone.severity)),
        strokeColor: _getSeverityColor(zone.severity),
        strokeWidth: 2,
      );
    }).toSet();
  }

  Set<Polyline> _buildPolylines() {
    if (widget.routes == null || widget.routes!.isEmpty) return {};

    return widget.routes!.map((route) {
      final isSelected = route.id == widget.selectedRouteId;
      final color = _getRouteColor(route.safetyScore);

      return Polyline(
        polylineId: PolylineId(route.id ?? 'route_${route.routeIndex}'),
        points: route.waypoints.map((w) => LatLng(w['lat']!, w['lng']!)).toList(),
        color: color,
        width: isSelected ? 6 : 3,
        patterns: isSelected ? [] : [PatternItem.dash(20), PatternItem.gap(10)],
      );
    }).toSet();
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return AppColors.sosRed;
      case 'high':
        return AppColors.safetyUnsafe;
      case 'medium':
        return AppColors.safetyModerate;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  double _getOpacity(String severity) {
    switch (severity) {
      case 'critical':
        return 0.4;
      case 'high':
        return 0.3;
      case 'medium':
        return 0.2;
      case 'low':
        return 0.15;
      default:
        return 0.15;
    }
  }

  Color _getRouteColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 80) return AppColors.safetySafe;
    if (score >= 60) return AppColors.safetyModerate;
    return AppColors.safetyUnsafe;
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.currentPosition,
        zoom: 15,
      ),
      onMapCreated: widget.onMapCreated,
      markers: _buildMarkers(),
      circles: _buildCircles(),
      polylines: _buildPolylines(),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      compassEnabled: true,
      onTap: widget.onMapTap,
    );
  }
}
