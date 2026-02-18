/// Input validation helpers used across the app.
class Validators {
  Validators._();

  /// Validates phone number (Indian format: +91XXXXXXXXXX or 10 digits).
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^(\+91)?[6-9]\d{9}$').hasMatch(cleaned)) {
      return 'Enter a valid Indian phone number';
    }
    return null;
  }

  /// Validates email address.
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates password strength.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain an uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain a lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }
    if (!RegExp(r'[!@#\$%\^&\*]').hasMatch(value)) {
      return 'Password must contain a special character';
    }
    return null;
  }

  /// Validates non-empty name.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  /// Validates Aadhaar number (12 digits).
  static String? validateAadhaar(String? value) {
    if (value == null || value.isEmpty) return 'Aadhaar number is required';
    final cleaned = value.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{12}$').hasMatch(cleaned)) {
      return 'Enter a valid 12-digit Aadhaar number';
    }
    return null;
  }

  /// Validates PAN card (e.g., ABCDE1234F).
  static String? validatePAN(String? value) {
    if (value == null || value.isEmpty) return 'PAN number is required';
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(value.toUpperCase())) {
      return 'Enter a valid PAN number (e.g., ABCDE1234F)';
    }
    return null;
  }

  // ── Boolean convenience methods (used by usecases) ──

  /// Returns true if the value is a valid Indian phone number.
  static bool isValidIndianPhone(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^(\+91)?[6-9]\d{9}$').hasMatch(cleaned);
  }

  /// Returns true if the value is a valid email address.
  static bool isValidEmail(String value) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
  }

  /// Returns true if the password meets strength requirements.
  static bool isStrongPassword(String value) {
    return validatePassword(value) == null;
  }
}

