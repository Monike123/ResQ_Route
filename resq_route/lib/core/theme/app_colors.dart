import 'package:flutter/material.dart';

/// Centralized color palette for ResQ Route.
class AppColors {
  AppColors._();

  // ── Primary ──
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF64B5F6);

  // ── Safety Colors ──
  static const Color safetySafe = Color(0xFF4CAF50); // Green — safe
  static const Color safetyModerate = Color(0xFFFFA726); // Orange — moderate
  static const Color safetyUnsafe = Color(0xFFEF5350); // Red — unsafe

  // ── SOS Emergency ──
  static const Color sosRed = Color(0xFFD32F2F);
  static const Color sosRedDark = Color(0xFFB71C1C);

  // ── Neutrals ──
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  // ── Map Markers ──
  static const Color markerOrigin = Color(0xFF1E88E5);
  static const Color markerDestination = Color(0xFFE53935);
  static const Color markerUnsafeZone = Color(0xFFFF5722);
}
