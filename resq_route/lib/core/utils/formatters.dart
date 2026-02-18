import 'package:intl/intl.dart';

/// Formatting helpers for dates, phone numbers, and distances.
class Formatters {
  Formatters._();

  /// Format DateTime to readable string (e.g., "19 Feb 2026, 12:30 AM").
  static String formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  /// Format DateTime to date only (e.g., "19 Feb 2026").
  static String formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  /// Format DateTime to time only (e.g., "12:30 AM").
  static String formatTime(DateTime dt) {
    return DateFormat('hh:mm a').format(dt);
  }

  /// Format phone number (e.g., "+91 98765 43210").
  static String formatPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length == 10) {
      return '+91 ${cleaned.substring(0, 5)} ${cleaned.substring(5)}';
    }
    if (cleaned.length == 12 && cleaned.startsWith('91')) {
      return '+${cleaned.substring(0, 2)} ${cleaned.substring(2, 7)} ${cleaned.substring(7)}';
    }
    if (cleaned.length == 13 && cleaned.startsWith('+91')) {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 8)} ${cleaned.substring(8)}';
    }
    return phone;
  }

  /// Format distance in meters to human-readable (e.g., "1.2 km" or "450 m").
  static String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  /// Format duration in seconds to human-readable (e.g., "1h 23m" or "45 min").
  static String formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).round()} min';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return '${hours}h ${mins}m';
  }
}
