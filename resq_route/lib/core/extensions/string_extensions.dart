/// Useful extensions on String.
extension StringExtensions on String {
  /// Capitalize first letter.
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Title case (capitalize each word).
  String get titleCase =>
      split(' ').map((word) => word.capitalize).join(' ');

  /// Check if string is a valid email.
  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  /// Check if string is a valid Indian phone number.
  bool get isValidPhone =>
      RegExp(r'^(\+91)?[6-9]\d{9}$').hasMatch(replaceAll(RegExp(r'[\s\-]'), ''));

  /// Mask a string for privacy (e.g., "XXXX XXXX 1234").
  String get masked {
    if (length <= 4) return this;
    final visible = substring(length - 4);
    final maskedPart = 'X' * (length - 4);
    return '$maskedPart$visible';
  }
}
