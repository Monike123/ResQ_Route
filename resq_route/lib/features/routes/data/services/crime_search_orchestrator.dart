import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/app_config.dart';
import 'gemini_crime_search_service.dart';
import 'perplexity_crime_search_service.dart';

/// Orchestrates dual-provider crime search (Gemini + Perplexity).
///
/// Flow:
/// 1. Check DB cache (7-day TTL) → instant if hit
/// 2. On miss: call BOTH providers in parallel
/// 3. Merge results (combine unique crime reports, pick higher confidence)
/// 4. Cache merged result in crime_data table
/// 5. Return CrimeSearchResult to caller
class CrimeSearchOrchestrator {
  final SupabaseClient _supabase;
  final GeminiCrimeSearchService _geminiService;
  final PerplexityCrimeSearchService _perplexityService;

  CrimeSearchOrchestrator(
    this._supabase, {
    GeminiCrimeSearchService? geminiService,
    PerplexityCrimeSearchService? perplexityService,
  })  : _geminiService = geminiService ?? GeminiCrimeSearchService(),
        _perplexityService =
            perplexityService ?? PerplexityCrimeSearchService();

  /// Search for crime data along a route.
  ///
  /// Returns cached data if available (< 7 days old).
  /// Otherwise calls both Gemini and Perplexity in parallel,
  /// merges results, caches them, and returns.
  Future<CrimeSearchResult> searchCrimeForRoute({
    required String routeName,
    required String city,
  }) async {
    // 1. Check DB cache
    final cached = await _getCachedResults(routeName);
    if (cached != null) return cached;

    // 2. Call both providers in parallel
    final results = await Future.wait([
      _geminiService.searchCrimeForRoute(
          routeName: routeName, city: city),
      _perplexityService.searchCrimeForRoute(
          routeName: routeName, city: city),
    ]);

    final geminiResult = results[0];
    final perplexityResult = results[1];

    // 3. Merge results from both providers
    final merged = _mergeResults(geminiResult, perplexityResult, routeName);

    // 4. Cache in DB (fire-and-forget)
    _cacheResults(merged, routeName, city);

    return merged;
  }

  /// Check for cached crime data for this route (< 7 days old).
  Future<CrimeSearchResult?> _getCachedResults(String routeName) async {
    try {
      final normalizedName = routeName.toLowerCase().trim();
      final response = await _supabase
          .from('crime_data')
          .select()
          .eq('route_name', normalizedName)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      if (data.isEmpty) return null;

      // Reconstruct CrimeSearchResult from cached rows
      final reports = data.map((row) {
        return CrimeReport(
          crimeType: row['crime_type'] as String? ?? 'unknown',
          severity: row['severity'] as String? ?? 'medium',
          approximateDate: row['occurred_at'] as String? ?? '',
          description: row['description'] as String? ?? '',
        );
      }).toList();

      // Use metadata from the first row for aggregate info
      final meta =
          data.first['metadata'] as Map<String, dynamic>? ?? {};

      return CrimeSearchResult(
        crimeReports: reports,
        overallRisk: meta['overall_risk'] as String? ?? 'medium',
        confidence: (meta['confidence'] as num?)?.toDouble() ?? 0.5,
        summary: meta['summary'] as String? ?? '',
        safetyTips: (meta['safety_tips'] as List<dynamic>?)
                ?.map((t) => t.toString())
                .toList() ??
            [],
        source: 'cache',
      );
    } catch (_) {
      return null;
    }
  }

  /// Merge results from both providers.
  ///
  /// Strategy:
  /// - Combine all unique crime reports (deduplicate by type + date)
  /// - Use the higher confidence value
  /// - Prefer the more detailed summary
  /// - Merge safety tips (unique only)
  CrimeSearchResult _mergeResults(
    CrimeSearchResult gemini,
    CrimeSearchResult perplexity,
    String routeName,
  ) {
    // Combine reports, deduplicate by crime_type + approximate_date
    final seen = <String>{};
    final allReports = <CrimeReport>[];

    for (final report in [...perplexity.crimeReports, ...gemini.crimeReports]) {
      final key =
          '${report.crimeType.toLowerCase()}_${report.approximateDate}';
      if (seen.add(key)) {
        allReports.add(report);
      }
    }

    // Pick higher confidence
    final confidence = gemini.confidence > perplexity.confidence
        ? gemini.confidence
        : perplexity.confidence;

    // Pick more detailed summary
    final summary = gemini.summary.length > perplexity.summary.length
        ? gemini.summary
        : perplexity.summary;

    // Merge safety tips (unique)
    final tipSet = <String>{};
    final mergedTips = <String>[];
    for (final tip in [...perplexity.safetyTips, ...gemini.safetyTips]) {
      if (tipSet.add(tip.toLowerCase())) {
        mergedTips.add(tip);
      }
    }

    // Pick higher risk level
    final riskOrder = {'low': 0, 'medium': 1, 'high': 2, 'critical': 3};
    final geminiRisk = riskOrder[gemini.overallRisk] ?? 1;
    final perplexityRisk = riskOrder[perplexity.overallRisk] ?? 1;
    final overallRisk =
        geminiRisk >= perplexityRisk ? gemini.overallRisk : perplexity.overallRisk;

    return CrimeSearchResult(
      crimeReports: allReports,
      overallRisk: overallRisk,
      confidence: confidence,
      summary: summary,
      safetyTips: mergedTips,
      source: 'ai_merged',
    );
  }

  /// Cache merged crime results in the DB.
  Future<void> _cacheResults(
    CrimeSearchResult result,
    String routeName,
    String city,
  ) async {
    try {
      final normalizedName = routeName.toLowerCase().trim();
      final expiresAt = DateTime.now()
          .add(Duration(days: AppConfig.crimeDataCacheDays))
          .toIso8601String();

      // Store aggregate metadata on the first row
      final metaJson = {
        'overall_risk': result.overallRisk,
        'confidence': result.confidence,
        'summary': result.summary,
        'safety_tips': result.safetyTips,
        'source': result.source,
      };

      if (result.crimeReports.isEmpty) {
        // Store a single "no data" row so cache still works
        await _supabase.from('crime_data').insert({
          'crime_type': 'none_reported',
          'severity': 'low',
          'description': result.summary,
          'source': result.source,
          'route_name': normalizedName,
          'city': city,
          'ai_confidence': result.confidence,
          'expires_at': expiresAt,
          'metadata': metaJson,
        });
      } else {
        final rows = result.crimeReports.asMap().entries.map((entry) {
          return {
            'crime_type': entry.value.crimeType,
            'severity': entry.value.severity,
            'description': entry.value.description,
            'source': result.source,
            'route_name': normalizedName,
            'city': city,
            'occurred_at': entry.value.approximateDate.isNotEmpty
                ? '${entry.value.approximateDate}-01'
                : null,
            'ai_confidence': result.confidence,
            'expires_at': expiresAt,
            'metadata': entry.key == 0 ? metaJson : <String, dynamic>{},
          };
        }).toList();

        await _supabase.from('crime_data').insert(rows);
      }
    } catch (_) {
      // Caching is non-critical — don't block the main flow
    }
  }
}
