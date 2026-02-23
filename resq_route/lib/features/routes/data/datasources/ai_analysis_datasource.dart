import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_analysis_model.dart';
import '../services/crime_search_orchestrator.dart';

/// Datasource for AI-powered route crime analysis.
///
/// Uses dual-provider crime search (Gemini + Perplexity)
/// to find crime history along route areas, then returns
/// a structured AiAnalysisModel for the safety scoring engine.
///
/// Features:
/// - 7-day cache via CrimeSearchOrchestrator
/// - Dual-provider parallel search
/// - Fallback response when both AIs unavailable
/// - Token usage tracking
class AiAnalysisDatasource {
  final SupabaseClient _client;
  late final CrimeSearchOrchestrator _orchestrator;

  AiAnalysisDatasource(this._client) {
    _orchestrator = CrimeSearchOrchestrator(_client);
  }

  /// Get AI analysis for a route.
  ///
  /// Extracts route name and city from [routeData], queries both
  /// Gemini and Perplexity for crime data, and returns a structured
  /// analysis result.
  Future<AiAnalysisModel> getAnalysis({
    required String routeId,
    required Map<String, dynamic> routeData,
  }) async {
    // Extract route name and city from route data
    final routeName = _extractRouteName(routeData);
    final city = _extractCity(routeData);

    try {
      // Search for crime data using dual-provider orchestrator
      final crimeResult = await _orchestrator.searchCrimeForRoute(
        routeName: routeName,
        city: city,
      );

      // Convert CrimeSearchResult → AiAnalysisModel
      final highRiskSegments = crimeResult.crimeReports
          .where((r) =>
              r.severity == 'critical' || r.severity == 'high')
          .map((r) => HighRiskSegment(
                lat: routeData['originLat'] as double? ?? 0,
                lng: routeData['originLng'] as double? ?? 0,
                reason: '${r.crimeType}: ${r.description}',
                severity: r.severity,
              ))
          .toList();

      // Map overall_risk to safety_rating (inverse)
      final safetyRating = _riskToRating(crimeResult.overallRisk);

      final analysis = AiAnalysisModel(
        riskLevel: crimeResult.overallRisk,
        safetyRating: safetyRating,
        highRiskSegments: highRiskSegments,
        precautions: crimeResult.safetyTips,
        summary: crimeResult.summary,
        confidence: crimeResult.confidence,
      );

      // Log usage (non-blocking)
      _logUsage(routeId, crimeResult.source);

      return analysis;
    } catch (e) {
      // Both providers failed — return statistical fallback
      return AiAnalysisModel(
        riskLevel: 'medium',
        safetyRating: 70,
        highRiskSegments: [],
        precautions: ['AI analysis unavailable — exercise general caution'],
        summary: 'Both AI providers unreachable. Using default safety score.',
        confidence: 0.2,
        isFallback: true,
      );
    }
  }

  /// Convert CrimeSearchResult to CrimeDataPoints for SafetyScoreService.
  Future<List<CrimeDataPointFromAi>> getCrimeDataPoints({
    required String routeName,
    required String city,
  }) async {
    final result = await _orchestrator.searchCrimeForRoute(
      routeName: routeName,
      city: city,
    );

    return result.crimeReports.map((report) {
      return CrimeDataPointFromAi(
        severity: report.severity,
        crimeType: report.crimeType,
        description: report.description,
        approximateDate: report.approximateDate,
      );
    }).toList();
  }

  /// Extract a meaningful route name from route data.
  String _extractRouteName(Map<String, dynamic> routeData) {
    // Try start_address or end_address first
    final startAddr = routeData['start_address'] as String?;
    final endAddr = routeData['end_address'] as String?;

    if (startAddr != null && endAddr != null) {
      return '$startAddr to $endAddr';
    }

    // Fallback: use step instructions
    final steps = routeData['steps'] as List<dynamic>?;
    if (steps != null && steps.isNotEmpty) {
      final roadNames = steps
          .map((s) => (s as Map<String, dynamic>)['instruction'] as String?)
          .where((i) => i != null && i.isNotEmpty)
          .take(3)
          .join(', ');
      if (roadNames.isNotEmpty) return roadNames;
    }

    // Last resort: coordinates
    return '${routeData['originLat']},${routeData['originLng']} to '
        '${routeData['destLat']},${routeData['destLng']}';
  }

  /// Extract city from route data.
  String _extractCity(Map<String, dynamic> routeData) {
    final endAddr = routeData['end_address'] as String?;
    if (endAddr != null) {
      // Try to extract city from address (usually last 2-3 parts)
      final parts = endAddr.split(',');
      if (parts.length >= 2) {
        return parts[parts.length - 2].trim();
      }
      return endAddr;
    }
    return 'India';
  }

  /// Map risk level to numeric safety rating (0-100, higher = safer).
  double _riskToRating(String riskLevel) {
    switch (riskLevel) {
      case 'critical':
        return 20.0;
      case 'high':
        return 40.0;
      case 'medium':
        return 65.0;
      case 'low':
        return 85.0;
      default:
        return 70.0;
    }
  }

  /// Log AI usage for cost tracking (fire-and-forget).
  Future<void> _logUsage(String routeId, String source) async {
    try {
      await _client.from('ai_usage_log').insert({
        'model': source,
        'prompt_tokens': 0,
        'response_tokens': 0,
        'estimated_cost': 0.0,
        'endpoint': 'crime-search-$source',
      });
    } catch (_) {
      // Non-critical
    }
  }
}

/// Crime data point from AI analysis — for feeding into SafetyScoreService.
class CrimeDataPointFromAi {
  final String severity;
  final String crimeType;
  final String description;
  final String approximateDate;

  const CrimeDataPointFromAi({
    required this.severity,
    required this.crimeType,
    required this.description,
    required this.approximateDate,
  });
}
