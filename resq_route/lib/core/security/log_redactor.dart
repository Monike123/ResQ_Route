/// PII log redaction utilities.
/// Never log raw phone numbers, emails, or Aadhaar numbers.
class LogRedactor {
  LogRedactor._();

  /// Redact phone: show only last 4 digits.
  /// Example: `+919876543210` → `****3210`
  static String redactPhone(String phone) {
    if (phone.length < 4) return '****';
    return '****${phone.substring(phone.length - 4)}';
  }

  /// Redact email: show first 2 chars + domain.
  /// Example: `user@example.com` → `us***@example.com`
  static String redactEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].length < 2) return '***@***';
    return '${parts[0].substring(0, 2)}***@${parts[1]}';
  }

  /// Fully redact Aadhaar / PAN — never log these.
  static String redactSensitiveId(String id) {
    return '********';
  }

  /// Redact a map of user data for safe logging.
  static Map<String, dynamic> redactUserData(Map<String, dynamic> data) {
    final safe = Map<String, dynamic>.from(data);
    if (safe.containsKey('phone')) {
      safe['phone'] = redactPhone(safe['phone'] as String? ?? '');
    }
    if (safe.containsKey('email')) {
      safe['email'] = redactEmail(safe['email'] as String? ?? '');
    }
    if (safe.containsKey('aadhar_hash')) {
      safe['aadhar_hash'] = '********';
    }
    return safe;
  }
}
