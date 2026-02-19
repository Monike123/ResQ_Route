import 'package:flutter/services.dart';

/// App-level security utilities: debug detection, clipboard security.
class AppSecurityService {
  AppSecurityService._();

  /// Check if app is running in debug mode.
  static bool get isDebugMode {
    bool debug = false;
    assert(() {
      debug = true;
      return true;
    }());
    return debug;
  }

  /// Clear clipboard after a delay (for sensitive field pastes).
  static void clearClipboardAfterDelay({
    Duration delay = const Duration(seconds: 5),
  }) {
    Future.delayed(delay, () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }

  /// Initialize security checks on app start.
  /// Call from `main()` after `WidgetsFlutterBinding.ensureInitialized()`.
  static Future<void> initialize() async {
    if (!isDebugMode) {
      // In release mode: no extra logging, no dev tools
      // Additional hardening can be added here
    }
  }

  /// Check if a string looks like it could contain sensitive data.
  /// Used to prevent accidental logging of PII.
  static bool isPotentialPii(String value) {
    // Aadhaar-like (12 consecutive digits)
    if (RegExp(r'\d{12}').hasMatch(value)) return true;
    // PAN-like
    if (RegExp(r'[A-Z]{5}\d{4}[A-Z]').hasMatch(value)) return true;
    // Email
    if (RegExp(r'[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]').hasMatch(value)) {
      return true;
    }
    return false;
  }
}
