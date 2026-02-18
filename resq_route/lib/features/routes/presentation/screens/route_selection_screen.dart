import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/route_providers.dart';
import '../widgets/safety_map.dart';
import '../widgets/route_card.dart';

/// Route selection screen — shows 3 route cards over a map with polylines.
class RouteSelectionScreen extends ConsumerStatefulWidget {
  const RouteSelectionScreen({super.key});

  @override
  ConsumerState<RouteSelectionScreen> createState() =>
      _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends ConsumerState<RouteSelectionScreen> {
  LatLng _currentPosition = const LatLng(
    LocationService.defaultLat,
    LocationService.defaultLng,
  );
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    final destination = ref.read(selectedDestinationProvider);
    if (destination == null) {
      setState(() {
        _error = 'No destination selected';
        _isLoading = false;
      });
      return;
    }

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      final user =
          ref.read(supabaseClientProvider).auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      final routes = await ref.read(fetchRoutesUseCaseProvider).execute(
            originLat: position.latitude,
            originLng: position.longitude,
            destLat: destination.lat,
            destLng: destination.lng,
            userId: user.id,
          );

      if (!mounted) return;
      ref.read(fetchedRoutesProvider.notifier).state = routes;
      if (routes.isNotEmpty) {
        ref.read(selectedRouteIdProvider.notifier).state = routes.first.id;
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to fetch routes: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routes = ref.watch(fetchedRoutesProvider);
    final selectedId = ref.watch(selectedRouteIdProvider);
    final destination = ref.watch(selectedDestinationProvider);
    final unsafeZones = ref.watch(unsafeZonesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Map (top half)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafetyMap(
                    currentPosition: _currentPosition,
                    unsafeZones: unsafeZones,
                    destination: destination != null
                        ? LatLng(destination.lat, destination.lng)
                        : null,
                    routes: routes,
                    selectedRouteId: selectedId,
                  ),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.surface,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
          ),

          // Route cards (bottom sheet)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.58,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Select Your Route',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (destination != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'To: ${destination.name}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Error state
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline,
                              color: AppColors.error, size: 48),
                          const SizedBox(height: 8),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.error)),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _error = null;
                              });
                              _fetchRoutes();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),

                  // Route cards
                  if (!_isLoading && _error == null)
                    Flexible(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shrinkWrap: true,
                        itemCount: routes.length,
                        itemBuilder: (context, index) {
                          final route = routes[index];
                          return RouteCard(
                            route: route,
                            isSelected: route.id == selectedId,
                            onTap: () {
                              ref
                                  .read(selectedRouteIdProvider.notifier)
                                  .state = route.id;
                            },
                          );
                        },
                      ),
                    ),

                  // Loading state
                  if (_isLoading && _error == null)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Finding the safest routes...'),
                        ],
                      ),
                    ),

                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
