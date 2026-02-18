import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_analysis_model.dart';

/// Datasource for AI crime analysis via Supabase Edge Functions.
///
/// Features:
/// - 6-hour cache lookup before calling AI
/// - Fallback response when AI is unavailable
/// - Token usage tracking
class AiAnalysisDatasource {
  final SupabaseClient _client;

  AiAnalysisDatasource(this._client);

  /// Get AI analysis for a route — checks cache first, then calls Edge Function.
  Future<AiAnalysisModel> getAnalysis({
    required String routeId,
    required Map<String, dynamic> routeData,
    required List<Map<String, dynamic>> crimeData,
  }) async {
    // 1. Check cache (6hr TTL)
    final cached = await _getCachedAnalysis(routeId);
    if (cached != null) return cached;

    // 2. Call Edge Function
    try {
      final response = await _client.functions.invoke(
        'ai-crime-analysis',
        body: {
          'routeId': routeId,
          'routeData': routeData,
          'crimeData': crimeData,
        },
      );

      final data = response.data as Map<String, dynamic>;

      // 3. Parse and validate
      final analysis = AiAnalysisModel.fromJson(data);

      // 4. Log usage (non-blocking)
      _logUsage(data);

      return analysis;
    } catch (e) {
      // AI unavailable — return statistical fallback
      return AiAnalysisModel(
        riskLevel: 'medium',
        safetyRating: 70,
        highRiskSegments: [],
        precautions: ['AI analysis unavailable — exercise general caution'],
        summary: 'Statistical fallback used. AI service was unreachable.',
        confidence: 0.3,
        isFallback: true,
      );
    }
  }

  /// Check for a cached (non-expired) analysis for this route.
  Future<AiAnalysisModel?> _getCachedAnalysis(String routeId) async {
    try {
      final response = await _client
          .from('ai_analyses')
          .select('result, is_fallback')
          .eq('route_id', routeId)
          .eq('analysis_type', 'crime_analysis')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('cached_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final result = response['result'] as Map<String, dynamic>;
      return AiAnalysisModel.fromJson(result);
    } catch (_) {
      return null;
    }
  }

  /// Log AI usage for cost tracking (fire-and-forget).
  Future<void> _logUsage(Map<String, dynamic> data) async {
    try {
      final promptTokens = data['prompt_tokens'] as int? ??
          data['usage']?['prompt_tokens'] as int? ??
          0;
      final responseTokens = data['response_tokens'] as int? ??
          data['usage']?['response_tokens'] as int? ??
          0;

      // gemini-1.5-flash pricing: $0.075/1M input, $0.30/1M output
      final estimatedCost =
          (promptTokens * 0.000000075) + (responseTokens * 0.0000003);

      await _client.from('ai_usage_log').insert({
        'model': 'gemini-1.5-flash',
        'prompt_tokens': promptTokens,
        'response_tokens': responseTokens,
        'estimated_cost': estimatedCost,
        'endpoint': 'ai-crime-analysis',
      });
    } catch (_) {
      // Non-critical — don't block the main flow
    }
  }
}
