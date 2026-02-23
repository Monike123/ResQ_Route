import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';

/// Result of an AI crime search for a route area.
class CrimeSearchResult {
  final List<CrimeReport> crimeReports;
  final String overallRisk;  // low, medium, high, critical
  final double confidence;   // 0-1
  final String summary;
  final List<String> safetyTips;
  final String source;       // 'ai_gemini', 'ai_perplexity'

  const CrimeSearchResult({
    required this.crimeReports,
    required this.overallRisk,
    required this.confidence,
    required this.summary,
    required this.safetyTips,
    required this.source,
  });
}

/// A single crime report parsed from AI response.
class CrimeReport {
  final String crimeType;
  final String severity;     // critical, high, medium, low
  final String approximateDate;
  final String description;

  const CrimeReport({
    required this.crimeType,
    required this.severity,
    required this.approximateDate,
    required this.description,
  });

  factory CrimeReport.fromJson(Map<String, dynamic> json) {
    return CrimeReport(
      crimeType: json['crime_type'] as String? ?? 'unknown',
      severity: json['severity'] as String? ?? 'medium',
      approximateDate: json['approximate_date'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

/// Gemini-based crime search provider.
///
/// Calls Gemini API directly with a structured prompt to analyze
/// crime history for a given route/area name.
class GeminiCrimeSearchService {
  final http.Client _httpClient;

  GeminiCrimeSearchService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Search for crime reports along a route using Gemini AI.
  Future<CrimeSearchResult> searchCrimeForRoute({
    required String routeName,
    required String city,
  }) async {
    final prompt = _buildPrompt(routeName, city);

    try {
      final response = await _httpClient.post(
        Uri.parse(
          '${AppConfig.geminiBaseUrl}/models/${AppConfig.geminiModel}:generateContent?key=${AppConfig.geminiApiKey}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 2048,
            'responseMimeType': 'application/json',
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Gemini API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseResponse(data);
    } catch (e) {
      // Return fallback on any error
      return _fallbackResult(routeName);
    }
  }

  String _buildPrompt(String routeName, String city) {
    return '''You are a crime intelligence analyst for an Indian women's safety navigation app called ResQ Route.

TASK: Research and analyze crime incidents reported along or near the following route/area in India.

ROUTE/AREA: $routeName
CITY/REGION: $city

Search for incidents including: kidnapping, rape, sexual assault, missing persons, robbery, chain snatching, eve teasing, stalking, murder, acid attacks, harassment.

For each incident you can identify or infer for this area, provide details.

RESPOND IN THIS EXACT JSON FORMAT:
{
  "area_name": "$routeName",
  "incidents_found": <number>,
  "crime_reports": [
    {
      "crime_type": "<type e.g. kidnapping, robbery>",
      "severity": "<critical|high|medium|low>",
      "approximate_date": "<YYYY-MM or YYYY>",
      "description": "<one line description>"
    }
  ],
  "overall_risk": "<low|medium|high|critical>",
  "confidence": <number between 0 and 1>,
  "summary": "<one paragraph safety assessment of this route/area>",
  "safety_tips": ["<tip1>", "<tip2>"]
}

SEVERITY GUIDE:
- critical: murder, rape, kidnapping, acid attack
- high: armed robbery, assault, sexual harassment
- medium: chain snatching, theft, stalking
- low: eve teasing, verbal harassment, petty crime

If you have no information about this specific area, return incidents_found: 0 with overall_risk: "medium" and confidence < 0.3.''';
  }

  CrimeSearchResult _parseResponse(Map<String, dynamic> data) {
    try {
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No candidates in response');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw Exception('No parts in response');
      }

      final text = parts[0]['text'] as String;

      // Parse JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) throw Exception('No JSON in response');

      final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

      final reports = (parsed['crime_reports'] as List<dynamic>?)
              ?.map((r) => CrimeReport.fromJson(r as Map<String, dynamic>))
              .toList() ??
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
        source: 'ai_gemini',
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
          'Gemini AI analysis unavailable for $routeName. Exercise general caution.',
      safetyTips: ['Stay alert and aware of surroundings'],
      source: 'ai_gemini',
    );
  }
}
