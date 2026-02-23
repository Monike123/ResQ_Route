import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import 'gemini_crime_search_service.dart';

/// Perplexity-based crime search provider.
///
/// Uses Perplexity's Sonar model for web-grounded crime search.
/// Perplexity excels at real-time web search with citations,
/// making it ideal for finding recent crime news articles.
class PerplexityCrimeSearchService {
  final http.Client _httpClient;

  PerplexityCrimeSearchService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Search for crime reports along a route using Perplexity AI.
  Future<CrimeSearchResult> searchCrimeForRoute({
    required String routeName,
    required String city,
  }) async {
    final prompt = _buildPrompt(routeName, city);

    try {
      final response = await _httpClient.post(
        Uri.parse('${AppConfig.perplexityBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.perplexityApiKey}',
        },
        body: jsonEncode({
          'model': AppConfig.perplexityModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a crime intelligence analyst for an Indian women\'s safety app. '
                      'Search the web for crime reports and safety concerns. '
                      'Always respond with valid JSON only, no markdown.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': 2048,
          'temperature': 0.2,
          'search_recency_filter': 'year',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Perplexity API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseResponse(data);
    } catch (e) {
      return _fallbackResult(routeName);
    }
  }

  String _buildPrompt(String routeName, String city) {
    return '''Search the web for crime incidents reported along or near "$routeName" in $city, India.

Look for: kidnapping, rape, sexual assault, missing persons, robbery, chain snatching, eve teasing, stalking, murder, acid attacks, harassment.

Respond in this EXACT JSON format (no markdown, no explanation):
{
  "area_name": "$routeName",
  "incidents_found": <number>,
  "crime_reports": [
    {
      "crime_type": "<type>",
      "severity": "<critical|high|medium|low>",
      "approximate_date": "<YYYY-MM or YYYY>",
      "description": "<one line from news source>"
    }
  ],
  "overall_risk": "<low|medium|high|critical>",
  "confidence": <0 to 1>,
  "summary": "<one paragraph assessment>",
  "safety_tips": ["<tip1>", "<tip2>"],
  "sources": ["<url1>", "<url2>"]
}

Severity: critical=murder/rape/kidnapping, high=robbery/assault, medium=theft/stalking, low=harassment/petty crime.
If no specific incidents found, set incidents_found: 0 and confidence < 0.3.''';
  }

  CrimeSearchResult _parseResponse(Map<String, dynamic> data) {
    try {
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw Exception('No choices in response');
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String? ?? '';

      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) throw Exception('No JSON in response');

      final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

      final reports = (parsed['crime_reports'] as List<dynamic>?)
              ?.map((r) => CrimeReport.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [];

      // Extract citation URLs if available
      final citations = data['citations'] as List<dynamic>?;
      final _ = (parsed['sources'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          citations?.map((c) => c.toString()).toList() ??
          [];

      return CrimeSearchResult(
        crimeReports: reports,
        overallRisk: parsed['overall_risk'] as String? ?? 'medium',
        confidence: (parsed['confidence'] as num?)?.toDouble() ?? 0.5,
        summary: parsed['summary'] as String? ?? '',
        safetyTips: (parsed['safety_tips'] as List<dynamic>?)
                ?.map((t) => t.toString())
                .toList() ??
            [],
        source: 'ai_perplexity',
      );
    } catch (_) {
      return _fallbackResult('unknown');
    }
  }

  CrimeSearchResult _fallbackResult(String routeName) {
    return CrimeSearchResult(
      crimeReports: [],
      overallRisk: 'medium',
      confidence: 0.2,
      summary:
          'Perplexity search unavailable for $routeName. Exercise general caution.',
      safetyTips: ['Stay alert and aware of surroundings'],
      source: 'ai_perplexity',
    );
  }
}
