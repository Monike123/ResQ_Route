import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/place_prediction_model.dart';
import '../providers/route_providers.dart';

/// Search screen — autocomplete, saved places, and recent searches.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().length < 3) {
      ref.read(searchResultsProvider.notifier).state = [];
      return;
    }

    ref.read(isSearchingProvider.notifier).state = true;

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      final results = await ref.read(searchPlacesUseCaseProvider).execute(
            query: query,
            lat: position.latitude,
            lng: position.longitude,
          );
      if (!mounted) return;
      ref.read(searchResultsProvider.notifier).state = results;
    } catch (_) {
      // Silently handle — show empty results
    } finally {
      if (mounted) ref.read(isSearchingProvider.notifier).state = false;
    }
  }

  Future<void> _onPlaceSelected(PlacePredictionModel prediction) async {
    try {
      final details =
          await ref.read(routeRepositoryProvider).getPlaceDetails(
                prediction.placeId,
              );

      // Save to recent searches
      final recentService =
          await ref.read(recentSearchesServiceProvider.future);
      await recentService.addSearch(details);

      if (!mounted) return;

      ref.read(selectedDestinationProvider.notifier).state = details;
      context.push('/route-selection');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get place details: $e')),
        );
      }
    }
  }

  Future<void> _onRecentSelected(PlaceDetailsModel place) async {
    ref.read(selectedDestinationProvider.notifier).state = place;
    if (mounted) context.push('/route-selection');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchResults = ref.watch(searchResultsProvider);
    final isSearching = ref.watch(isSearchingProvider);
    final recentSearches = ref.watch(recentSearchesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search destination...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          style: theme.textTheme.bodyLarge,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(searchResultsProvider.notifier).state = [];
              },
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loading indicator
          if (isSearching)
            const LinearProgressIndicator(),

          // Search results
          if (searchResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'SUGGESTIONS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final place = searchResults[index];
                  return ListTile(
                    leading: Icon(Icons.location_on_outlined,
                        color: AppColors.primary),
                    title: Text(place.mainText),
                    subtitle: place.secondaryText != null
                        ? Text(place.secondaryText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)
                        : null,
                    onTap: () => _onPlaceSelected(place),
                  );
                },
              ),
            ),
          ],

          // No search yet — show recents
          if (searchResults.isEmpty && !isSearching) ...[
            // Saved places (static for now)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'SAVED PLACES',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              subtitle: const Text('Not set'),
              enabled: false,
            ),
            ListTile(
              leading: const Icon(Icons.work_outline),
              title: const Text('Work'),
              subtitle: const Text('Not set'),
              enabled: false,
            ),

            const Divider(indent: 16, endIndent: 16),

            // Recent searches
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'RECENT',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: recentSearches.when(
                data: (recents) {
                  if (recents.isEmpty) {
                    return Center(
                      child: Text(
                        'No recent searches',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: recents.length,
                    itemBuilder: (context, index) {
                      final place = recents[index];
                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(place.name),
                        subtitle: Text(
                          place.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _onRecentSelected(place),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Error')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
