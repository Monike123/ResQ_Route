import 'dart:math';

/// Multi-factor safety scoring algorithm.
///
/// Formula: SafetyScore = (CrimeDensity × 0.35) + (UserFlags × 0.25) +
///          (CommercialFactor × 0.20) + (Lighting × 0.10) + (PopulationDensity × 0.10)
///
/// All component scores are normalized 0-100. Higher = safer.
class SafetyScoreService {
  // ── Weights ──
  static const double wCrime = 0.35;
  static const double wFlags = 0.25;
  static const double wCommercial = 0.20;
  static const double wLighting = 0.10;
  static const double wPopulation = 0.10;

  // ── Severity multipliers ──
  static const Map<String, int> severityMultiplier = {
    'critical': 10,
    'high': 7,
    'medium': 4,
    'low': 2,
  };

  /// Calculate the full safety score from raw data.
  SafetyResult calculateScore({
    required List<CrimeDataPoint> crimePoints,
    required List<UnsafeFlag> unsafeFlags,
    required int commercialPointCount,
    required DateTime travelTime,
    String areaType = 'suburban',
    double? aiConfidence,
  }) {
    final crimeScore = _calculateCrimeScore(crimePoints);
    final flagScore = _calculateFlagScore(unsafeFlags);
    final commercialScore = _calculateCommercialScore(commercialPointCount);
    final lightingScore =
        _calculateLightingScore(travelTime, commercialPointCount);
    final populationScore = _calculatePopulationScore(areaType);

    final weighted = (crimeScore * wCrime) +
        (flagScore * wFlags) +
        (commercialScore * wCommercial) +
        (lightingScore * wLighting) +
        (populationScore * wPopulation);

    final overallScore = weighted.clamp(0.0, 100.0);

    final confidence = calculateConfidence(
      dataPointCount: crimePoints.length + unsafeFlags.length,
      crimePoints: crimePoints,
      aiConfidence: aiConfidence,
    );

    return SafetyResult(
      overallScore: _round(overallScore),
      crimeScore: _round(crimeScore),
      flagScore: _round(flagScore),
      commercialScore: _round(commercialScore),
      lightingScore: _round(lightingScore),
      populationScore: _round(populationScore),
      confidence: _round(confidence),
      weights: const {
        'crime_density': wCrime,
        'user_flags': wFlags,
        'commercial': wCommercial,
        'lighting': wLighting,
        'population': wPopulation,
      },
    );
  }

  // ── Crime Density Score (35%) ──
  double _calculateCrimeScore(List<CrimeDataPoint> crimePoints) {
    if (crimePoints.isEmpty) return 95.0; // No crime data = high score

    double totalImpact = 0;
    for (final crime in crimePoints) {
      final mult = severityMultiplier[crime.severity] ?? 2;
      final decay = _recencyDecay(crime.occurredAt);
      totalImpact += mult * decay;
    }
    return (100 - totalImpact).clamp(0.0, 100.0);
  }

  // ── User Flag Score (25%) ──
  double _calculateFlagScore(List<UnsafeFlag> flags) {
    if (flags.isEmpty) return 95.0;

    double impact = 0;
    for (final flag in flags) {
      final ageDecay = flag.createdAt
              .isBefore(DateTime.now().subtract(const Duration(days: 90)))
          ? 0.5
          : 1.0;
      impact += (flag.isVerified ? 15 : 5) * ageDecay;
    }
    return (100 - impact).clamp(0.0, 100.0);
  }

  // ── Commercial Factor (20%) ──
  double _calculateCommercialScore(int commercialPointCount) {
    // More commercial activity = more help nearby = safer
    return (commercialPointCount * 7.0).clamp(0.0, 100.0);
  }

  // ── Lighting Factor (10%) ──
  double _calculateLightingScore(DateTime travelTime, int commercialPoints) {
    final hour = travelTime.hour;
    double base;
    if (hour >= 6 && hour < 18) {
      base = 90.0; // Daytime
    } else if (hour >= 18 && hour < 22) {
      base = 60.0; // Evening
    } else {
      base = 30.0; // Night
    }
    // Boost for well-lit commercial zones
    if (commercialPoints > 5) base += 20;
    return base.clamp(0.0, 100.0);
  }

  // ── Population Density (10%) ──
  double _calculatePopulationScore(String areaType) {
    switch (areaType.toLowerCase()) {
      case 'urban':
      case 'commercial':
        return 85.0;
      case 'suburban':
      case 'residential':
        return 65.0;
      case 'industrial':
        return 40.0;
      case 'rural':
      case 'isolated':
        return 20.0;
      default:
        return 65.0;
    }
  }

  // ── Confidence Scoring ──
  double calculateConfidence({
    required int dataPointCount,
    required List<CrimeDataPoint> crimePoints,
    double? aiConfidence,
    double? userFeedbackAccuracy,
  }) {
    // Data density (0.4 weight)
    double dataDensity;
    if (dataPointCount == 0) {
      dataDensity = 0.1;
    } else if (dataPointCount <= 5) {
      dataDensity = 0.4;
    } else if (dataPointCount <= 15) {
      dataDensity = 0.7;
    } else {
      dataDensity = 1.0;
    }

    // Data recency (0.3 weight)
    double dataRecency = 0.3;
    if (crimePoints.isNotEmpty) {
      final now = DateTime.now();
      final recentCount = crimePoints
          .where(
              (c) => c.occurredAt.isAfter(now.subtract(const Duration(days: 30))))
          .length;
      final ratio = recentCount / crimePoints.length;
      if (ratio > 0.7) {
        dataRecency = 1.0;
      } else if (ratio > 0.3) {
        dataRecency = 0.6;
      } else {
        dataRecency = 0.3;
      }
    }

    // AI confidence (0.2 weight) — from Gemini response
    final aiConf = aiConfidence ?? 0.5;

    // User feedback (0.1 weight) — from historical accuracy
    final feedback = userFeedbackAccuracy ?? 0.5;

    return (dataDensity * 0.4) +
        (dataRecency * 0.3) +
        (aiConf * 0.2) +
        (feedback * 0.1);
  }

  // ── Helpers ──
  double _recencyDecay(DateTime occurredAt) {
    final days = DateTime.now().difference(occurredAt).inDays;
    if (days < 30) return 1.0;
    if (days < 90) return 0.7;
    if (days < 180) return 0.4;
    if (days < 365) return 0.2;
    return 0.05;
  }

  double _round(double value) => (value * 10).roundToDouble() / 10;

  /// Segment a route into ~segmentMeters chunks.
  /// Returns centers of each chunk.
  List<({double lat, double lng})> segmentRoute(
    List<Map<String, double>> waypoints,
    double segmentMeters,
  ) {
    if (waypoints.isEmpty) return [];
    final chunks = <({double lat, double lng})>[];
    double distance = 0;
    var lastPoint = waypoints.first;

    for (final point in waypoints) {
      distance += haversineDistance(
        lastPoint['lat']!,
        lastPoint['lng']!,
        point['lat']!,
        point['lng']!,
      );
      if (distance >= segmentMeters) {
        chunks.add((lat: point['lat']!, lng: point['lng']!));
        distance = 0;
      }
      lastPoint = point;
    }
    if (chunks.isEmpty) {
      chunks.add((lat: waypoints.first['lat']!, lng: waypoints.first['lng']!));
    }
    return chunks;
  }

  /// Haversine distance in meters between two lat/lng points.
  static double haversineDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = _radians(lat2 - lat1);
    final dLng = _radians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_radians(lat1)) *
            cos(_radians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _radians(double degrees) => degrees * pi / 180;
}

/// Raw crime data point for scoring.
class CrimeDataPoint {
  final String severity; // critical, high, medium, low
  final DateTime occurredAt;
  final double lat;
  final double lng;

  const CrimeDataPoint({
    required this.severity,
    required this.occurredAt,
    required this.lat,
    required this.lng,
  });
}

/// User-reported unsafe zone flag for scoring.
class UnsafeFlag {
  final bool isVerified;
  final DateTime createdAt;

  const UnsafeFlag({
    required this.isVerified,
    required this.createdAt,
  });
}

/// Result of the safety scoring algorithm.
class SafetyResult {
  final double overallScore;
  final double crimeScore;
  final double flagScore;
  final double commercialScore;
  final double lightingScore;
  final double populationScore;
  final double confidence;
  final Map<String, double> weights;

  const SafetyResult({
    required this.overallScore,
    required this.crimeScore,
    required this.flagScore,
    required this.commercialScore,
    required this.lightingScore,
    required this.populationScore,
    required this.confidence,
    required this.weights,
  });

  /// Convert to JSON for storage in safety_breakdown column.
  Map<String, dynamic> toBreakdownJson() => {
        'overall_score': overallScore,
        'components': {
          'crime_density_score': crimeScore,
          'user_flag_score': flagScore,
          'commercial_factor': commercialScore,
          'lighting_factor': lightingScore,
          'population_density': populationScore,
        },
        'weights': weights,
        'confidence': confidence,
      };

  /// Parse from safety_breakdown JSON column.
  factory SafetyResult.fromBreakdownJson(Map<String, dynamic> json) {
    final components =
        json['components'] as Map<String, dynamic>? ?? {};
    final weights =
        (json['weights'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            SafetyResult._defaultWeights;

    return SafetyResult(
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0,
      crimeScore:
          (components['crime_density_score'] as num?)?.toDouble() ?? 0,
      flagScore: (components['user_flag_score'] as num?)?.toDouble() ?? 0,
      commercialScore:
          (components['commercial_factor'] as num?)?.toDouble() ?? 0,
      lightingScore:
          (components['lighting_factor'] as num?)?.toDouble() ?? 0,
      populationScore:
          (components['population_density'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      weights: weights,
    );
  }

  static const Map<String, double> _defaultWeights = {
    'crime_density': 0.35,
    'user_flags': 0.25,
    'commercial': 0.20,
    'lighting': 0.10,
    'population': 0.10,
  };
}
