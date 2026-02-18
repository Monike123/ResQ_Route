import 'package:flutter/material.dart';
import '../models/route_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Service to rank routes by safety score and assign display labels.
class RouteRankingService {
  /// Sort routes by safety score (highest = safest first) and assign labels.
  List<RouteModel> rankRoutes(List<RouteModel> routes) {
    // Separate scored from unscored
    final scored = routes.where((r) => r.safetyScore != null).toList();
    final unscored = routes.where((r) => r.safetyScore == null).toList();

    // Sort scored routes: highest safety score first
    scored.sort((a, b) => b.safetyScore!.compareTo(a.safetyScore!));

    // Combine: scored first, then unscored
    return [...scored, ...unscored];
  }

  /// Get display label for a route based on its rank position.
  static String getLabel(int index, int totalRoutes) {
    switch (index) {
      case 0:
        return '⭐ Safest (Recommended)';
      case 1:
        return '⚖️ Balanced';
      default:
        if (index == totalRoutes - 1) return '📏 Shortest';
        return 'Route ${index + 1}';
    }
  }

  /// Color based on safety score value.
  static Color getScoreColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 80) return AppColors.safetySafe;
    if (score >= 60) return AppColors.safetyModerate;
    if (score >= 40) return const Color(0xFFFF7043); // Deep Orange
    return AppColors.safetyUnsafe;
  }

  /// Human-readable label for score range.
  static String getScoreLabel(double? score) {
    if (score == null) return 'Calculating...';
    if (score >= 80) return 'Safe';
    if (score >= 60) return 'Moderate';
    if (score >= 40) return 'Caution';
    return 'High Risk';
  }

  /// Get confidence label text.
  static String getConfidenceLabel(double confidence) {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.5) return 'Medium';
    return 'Low';
  }

  /// Whether to show low-confidence warning.
  static bool shouldShowConfidenceWarning(double confidence) {
    return confidence < 0.4;
  }
}
