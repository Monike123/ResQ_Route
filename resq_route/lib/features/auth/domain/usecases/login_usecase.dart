import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/rate_limiter_service.dart';
import '../../../../core/services/session_manager.dart';

/// Login use case — validates, checks rate limit, authenticates.
class LoginUseCase {
  final AuthRepository _authRepo;
  final SecureStorageService _secureStorage;
  final RateLimiterService _rateLimiter;
  final SessionManager _sessionManager;

  LoginUseCase(
    this._authRepo,
    this._secureStorage,
    this._rateLimiter,
    this._sessionManager,
  );

  Future<LoginResult> execute({
    required String identifier,
    required String password,
  }) async {
    // 1. Check rate limit
    if (await _rateLimiter.isLocked(identifier)) {
      final remaining = _rateLimiter.lockoutRemaining(identifier);
      final minutes = remaining?.inMinutes ?? 15;
      return LoginResult.locked(
        'Too many failed attempts. Try again in $minutes minutes.',
      );
    }

    // 2. Determine identifier type
    final isEmail = Validators.isValidEmail(identifier);
    final isPhone = Validators.isValidIndianPhone(identifier);

    if (!isEmail && !isPhone) {
      return LoginResult.failure('Enter a valid phone number or email');
    }

    // 3. Attempt login
    try {
      final AuthResponse response;
      if (isPhone) {
        response = await _authRepo.signInWithPhone(
          phone: identifier,
          password: password,
        );
      } else {
        response = await _authRepo.signInWithEmail(
          email: identifier,
          password: password,
        );
      }

      if (response.session != null) {
        // 4. Store tokens
        await _secureStorage.saveAccessToken(
          response.session!.accessToken,
        );
        if (response.session!.refreshToken != null) {
          await _secureStorage.saveRefreshToken(
            response.session!.refreshToken!,
          );
        }

        // 5. Start auto-refresh
        _sessionManager.startAutoRefresh();

        // 6. Reset rate limiter
        await _rateLimiter.reset(identifier);

        return LoginResult.success(response.session!);
      }

      return LoginResult.failure('Login failed. Please try again.');
    } on AuthException catch (e) {
      // Record failed attempt
      await _rateLimiter.recordFailedAttempt(identifier);
      final remaining = _rateLimiter.remainingAttempts(identifier);

      if (remaining <= 0) {
        return LoginResult.locked(
          'Account locked. Too many failed attempts.',
        );
      }

      return LoginResult.failure(
        '${_extractMessage(e)} ($remaining attempts remaining)',
      );
    } catch (e) {
      await _rateLimiter.recordFailedAttempt(identifier);
      return LoginResult.failure('Something went wrong. Please try again.');
    }
  }

  String _extractMessage(AuthException error) {
    if (error.message.contains('Invalid login credentials')) {
      return 'Invalid phone/email or password.';
    }
    return 'Authentication failed.';
  }
}

/// Result wrapper for login operation.
class LoginResult {
  final LoginStatus status;
  final Session? session;
  final String? error;

  LoginResult._({required this.status, this.session, this.error});

  factory LoginResult.success(Session session) =>
      LoginResult._(status: LoginStatus.success, session: session);

  factory LoginResult.failure(String error) =>
      LoginResult._(status: LoginStatus.failure, error: error);

  factory LoginResult.locked(String message) =>
      LoginResult._(status: LoginStatus.locked, error: message);

  bool get isSuccess => status == LoginStatus.success;
  bool get isLocked => status == LoginStatus.locked;
}

enum LoginStatus { success, failure, locked }
