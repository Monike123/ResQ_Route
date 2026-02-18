import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/location_service.dart';
import '../providers/route_providers.dart';
import '../widgets/safety_map.dart';
import '../widgets/search_bar_widget.dart';

/// Home screen — map view with search bar, unsafe zones, and SOS button.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  LatLng _currentPosition = const LatLng(
    LocationService.defaultLat,
    LocationService.defaultLng,
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });

    // Fetch nearby unsafe zones
    _loadUnsafeZones(position.latitude, position.longitude);
  }

  Future<void> _loadUnsafeZones(double lat, double lng) async {
    try {
      final repo = ref.read(routeRepositoryProvider);
      final zones = await repo.getNearbyUnsafeZones(lat: lat, lng: lng);
      if (!mounted) return;
      ref.read(unsafeZonesProvider.notifier).state = zones;
    } catch (_) {
      // Silently fail — zones are non-critical for home display
    }
  }

  @override
  Widget build(BuildContext context) {
    final unsafeZones = ref.watch(unsafeZonesProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Map
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            SafetyMap(
              currentPosition: _currentPosition,
              unsafeZones: unsafeZones,
            ),

          // Search bar overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: SearchBarWidget(
              onTap: () => context.push('/search'),
            ),
          ),

          // Bottom action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // SOS Button
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                // TODO: Phase 5 — SOS flow
              },
              icon: const Icon(Icons.sos, size: 20),
              label: const Text('SOS',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sosRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Safety Report
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Phase 6 — Safety Route Report
              },
              icon: const Icon(Icons.description_outlined, size: 20),
              label: const Text('SRR',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
