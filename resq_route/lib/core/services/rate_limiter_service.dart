import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Client-side rate limiter to prevent brute force attacks.
///
/// Tracks failed attempts per identifier (phone/email) and locks
/// after [_maxAttempts] failures within [_windowMinutes].
class RateLimiterService {
  final SharedPreferences _prefs;

  static const int _maxAttempts = 5;
  static const int _windowMinutes = 15;

  RateLimiterService(this._prefs);

  /// Check if the identifier is currently locked out.
  Future<bool> isLocked(String identifier) async {
    final key = 'rate_limit_$identifier';
    final data = _prefs.getString(key);
    if (data == null) return false;

    final record = json.decode(data) as Map<String, dynamic>;
    final attempts = record['attempts'] as int;
    final firstAttempt = DateTime.parse(record['first_attempt'] as String);
    final elapsed = DateTime.now().difference(firstAttempt);

    if (elapsed.inMinutes >= _windowMinutes) {
      await reset(identifier);
      return false;
    }

    return attempts >= _maxAttempts;
  }

  /// Record a failed login attempt.
  Future<void> recordFailedAttempt(String identifier) async {
    final key = 'rate_limit_$identifier';
    final data = _prefs.getString(key);

    if (data == null) {
      await _prefs.setString(key, json.encode({
        'attempts': 1,
        'first_attempt': DateTime.now().toIso8601String(),
      }));
    } else {
      final record = json.decode(data) as Map<String, dynamic>;
      record['attempts'] = (record['attempts'] as int) + 1;
      await _prefs.setString(key, json.encode(record));
    }
  }

  /// Reset the rate limit for an identifier (on successful login).
  Future<void> reset(String identifier) async {
    await _prefs.remove('rate_limit_$identifier');
  }

  /// Get remaining attempts before lockout.
  int remainingAttempts(String identifier) {
    final key = 'rate_limit_$identifier';
    final data = _prefs.getString(key);
    if (data == null) return _maxAttempts;
    final record = json.decode(data) as Map<String, dynamic>;
    return _maxAttempts - (record['attempts'] as int);
  }

  /// Get remaining lockout duration.
  Duration? lockoutRemaining(String identifier) {
    final key = 'rate_limit_$identifier';
    final data = _prefs.getString(key);
    if (data == null) return null;

    final record = json.decode(data) as Map<String, dynamic>;
    final attempts = record['attempts'] as int;
    if (attempts < _maxAttempts) return null;

    final firstAttempt = DateTime.parse(record['first_attempt'] as String);
    final windowEnd = firstAttempt.add(const Duration(minutes: _windowMinutes));
    final remaining = windowEnd.difference(DateTime.now());

    return remaining.isNegative ? null : remaining;
  }
}
