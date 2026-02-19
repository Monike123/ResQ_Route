/// Client-side input validation for security-critical fields.
class InputValidator {
  InputValidator._();

  /// Validate Indian mobile phone (10-digit, starts with 6-9).
  static bool isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^\+?91?[6-9]\d{9}$').hasMatch(cleaned);
  }

  /// Validate email (basic RFC 5322).
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
    ).hasMatch(email);
  }

  /// Validate latitude (-90 to 90).
  static bool isValidLatitude(double lat) {
    return lat >= -90 && lat <= 90;
  }

  /// Validate longitude (-180 to 180).
  static bool isValidLongitude(double lng) {
    return lng >= -180 && lng <= 180;
  }

  /// Validate coordinate pair.
  static bool isValidCoordinates(double lat, double lng) {
    return isValidLatitude(lat) && isValidLongitude(lng);
  }

  /// Enforce max text length, trim whitespace.
  static String sanitizeText(String text, {int maxLength = 500}) {
    final trimmed = text.trim();
    if (trimmed.length > maxLength) {
      return trimmed.substring(0, maxLength);
    }
    return trimmed;
  }

  /// Sanitize AI prompt input — strip potential injection patterns.
  static String sanitizeAiPrompt(String prompt) {
    // Remove system/role override attempts
    final cleaned = prompt
        .replaceAll(RegExp(r'\bsystem\s*:', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bassistant\s*:', caseSensitive: false), '')
        .replaceAll(RegExp(r'\brole\s*:', caseSensitive: false), '')
        .replaceAll(RegExp(r'ignore\s+previous\s+instructions',
            caseSensitive: false), '')
        .trim();
    return sanitizeText(cleaned, maxLength: 2000);
  }

  /// Validate Aadhaar format (12 digits).
  static bool isValidAadhaar(String aadhaar) {
    final cleaned = aadhaar.replaceAll(RegExp(r'\s'), '');
    return RegExp(r'^\d{12}$').hasMatch(cleaned);
  }

  /// Validate PAN format (ABCDE1234F).
  static bool isValidPan(String pan) {
    return RegExp(r'^[A-Z]{5}\d{4}[A-Z]$').hasMatch(pan.toUpperCase());
  }
}
