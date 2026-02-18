/// AI crime analysis result from Gemini API.
class AiAnalysisModel {
  final String riskLevel; // low, medium, high, critical
  final double safetyRating; // 0-100
  final List<HighRiskSegment> highRiskSegments;
  final List<String> precautions;
  final String summary;
  final double confidence; // 0-1
  final bool isFallback;

  const AiAnalysisModel({
    required this.riskLevel,
    required this.safetyRating,
    required this.highRiskSegments,
    required this.precautions,
    required this.summary,
    required this.confidence,
    this.isFallback = false,
  });

  factory AiAnalysisModel.fromJson(Map<String, dynamic> json) {
    final isFallback = json['fallback'] == true;

    if (isFallback) {
      return AiAnalysisModel(
        riskLevel: 'medium',
        safetyRating: (json['safety_rating'] as num?)?.toDouble() ?? 70,
        highRiskSegments: [],
        precautions: ['AI analysis unavailable — exercise general caution'],
        summary: json['message'] as String? ??
            'Statistical fallback — AI analysis was not available.',
        confidence: 0.3,
        isFallback: true,
      );
    }

    return AiAnalysisModel(
      riskLevel: json['risk_level'] as String? ?? 'medium',
      safetyRating: (json['safety_rating'] as num?)?.toDouble() ?? 70,
      highRiskSegments: (json['high_risk_segments'] as List<dynamic>?)
              ?.map((s) =>
                  HighRiskSegment.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      precautions: (json['precautions'] as List<dynamic>?)
              ?.map((p) => p.toString())
              .toList() ??
          [],
      summary: json['summary'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      isFallback: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'risk_level': riskLevel,
        'safety_rating': safetyRating,
        'high_risk_segments':
            highRiskSegments.map((s) => s.toJson()).toList(),
        'precautions': precautions,
        'summary': summary,
        'confidence': confidence,
        'fallback': isFallback,
      };

  /// Schema validation — matches Edge Function validation logic.
  static bool isValidSchema(Map<String, dynamic> data) {
    return data['risk_level'] is String &&
        ['low', 'medium', 'high', 'critical'].contains(data['risk_level']) &&
        data['safety_rating'] is num &&
        (data['safety_rating'] as num) >= 0 &&
        (data['safety_rating'] as num) <= 100 &&
        data['high_risk_segments'] is List &&
        data['precautions'] is List &&
        data['summary'] is String &&
        data['confidence'] is num;
  }
}

/// A geographic point flagged as high risk by AI.
class HighRiskSegment {
  final double lat;
  final double lng;
  final String reason;
  final String severity; // low, medium, high, critical

  const HighRiskSegment({
    required this.lat,
    required this.lng,
    required this.reason,
    required this.severity,
  });

  factory HighRiskSegment.fromJson(Map<String, dynamic> json) {
    return HighRiskSegment(
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String? ?? '',
      severity: json['severity'] as String? ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'reason': reason,
        'severity': severity,
      };
}
