import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routes/data/models/place_prediction_model.dart';

/// Stores and retrieves recent searches using SharedPreferences.
class RecentSearchesService {
  static const _key = 'recent_searches';
  static const _maxRecent = 10;

  final SharedPreferences _prefs;

  RecentSearchesService(this._prefs);

  /// Add a search result to recent history (deduplicates by placeId).
  Future<void> addSearch(PlaceDetailsModel place) async {
    final searches = await getRecentSearches();
    searches.removeWhere((s) => s.placeId == place.placeId);
    searches.insert(0, place);
    if (searches.length > _maxRecent) searches.removeLast();
    await _prefs.setString(
      _key,
      json.encode(searches.map((s) => s.toJson()).toList()),
    );
  }

  /// Get the list of recent searches.
  Future<List<PlaceDetailsModel>> getRecentSearches() async {
    final data = _prefs.getString(_key);
    if (data == null) return [];
    try {
      return (json.decode(data) as List<dynamic>)
          .map((j) => PlaceDetailsModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Clear all recent searches.
  Future<void> clearRecentSearches() async {
    await _prefs.remove(_key);
  }
}
