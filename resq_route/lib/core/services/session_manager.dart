import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'secure_storage_service.dart';

/// Manages user session lifecycle: auto-refresh, session checks, and cleanup.
class SessionManager {
  final SupabaseClient _client;
  final SecureStorageService _secureStorage;
  Timer? _refreshTimer;

  SessionManager(this._client, this._secureStorage);

  /// Check existing session on app launch.
  ///
  /// Returns `true` if a valid session exists, `false` if user must log in.
  Future<bool> checkSession() async {
    final session = _client.auth.currentSession;

    if (session != null && !session.isExpired) {
      await _storeTokens(session);
      startAutoRefresh();
      return true;
    } else if (session != null) {
      // Try to refresh expired session
      try {
        final response = await _client.auth.refreshSession();
        if (response.session != null) {
          await _storeTokens(response.session!);
          startAutoRefresh();
          return true;
        }
      } catch (_) {
        // Refresh failed — user must log in
        await _secureStorage.clearAll();
      }
    }
    return false;
  }

  /// Start the auto-refresh timer.
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    final session = _client.auth.currentSession;
    if (session == null || session.expiresAt == null) return;

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      session.expiresAt! * 1000,
    );
    // Refresh 1 minute before expiry
    final refreshIn = expiresAt.difference(DateTime.now()) -
        const Duration(minutes: 1);

    if (refreshIn.isNegative) {
      _client.auth.refreshSession();
    } else {
      _refreshTimer = Timer(refreshIn, () {
        _client.auth.refreshSession();
        startAutoRefresh();
      });
    }
  }

  /// Stop the auto-refresh timer.
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Store tokens securely after auth events.
  Future<void> _storeTokens(Session session) async {
    await _secureStorage.saveAccessToken(session.accessToken);
    if (session.refreshToken != null) {
      await _secureStorage.saveRefreshToken(session.refreshToken!);
    }
  }

  /// Clean up on logout.
  Future<void> clearSession() async {
    stopAutoRefresh();
    await _secureStorage.clearAll();
  }

  void dispose() {
    stopAutoRefresh();
  }
}
