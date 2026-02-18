import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for Supabase Auth operations.
class AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSource(this._client);

  // ── SIGNUP ──

  Future<AuthResponse> signUpWithPhone({
    required String phone,
    required String password,
    String? email,
  }) async {
    return await _client.auth.signUp(
      phone: phone,
      password: password,
      emailRedirectTo: null,
      data: email != null ? {'email': email} : null,
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  // ── LOGIN ──

  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      phone: phone,
      password: password,
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ── OTP ──

  Future<void> sendOtp({required String phone}) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
    OtpType type = OtpType.sms,
  }) async {
    return await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: type,
    );
  }

  // ── PASSWORD RESET ──

  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> resetPasswordForPhone(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  // ── SESSION ──

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> refreshSession() async {
    return await _client.auth.refreshSession();
  }

  // ── SIGN OUT ──

  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    await _client.auth.signOut(scope: scope);
  }

  // ── AUTH STATE ──

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
