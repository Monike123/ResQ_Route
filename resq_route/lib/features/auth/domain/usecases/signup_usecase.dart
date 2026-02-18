import '../repositories/auth_repository.dart';
import '../../../../core/utils/validators.dart';

/// Sign up use case — validates inputs and creates account.
class SignUpUseCase {
  final AuthRepository _authRepo;

  SignUpUseCase(this._authRepo);

  Future<SignUpResult> execute({
    required String phone,
    required String password,
    String? email,
  }) async {
    // Client-side validation
    if (!Validators.isValidIndianPhone(phone)) {
      return SignUpResult.failure('Enter a valid Indian phone number');
    }

    if (email != null && !Validators.isValidEmail(email)) {
      return SignUpResult.failure('Enter a valid email address');
    }

    if (!Validators.isStrongPassword(password)) {
      return SignUpResult.failure(
        'Password must be at least 8 characters with uppercase, '
        'lowercase, digit, and special character',
      );
    }

    try {
      final response = await _authRepo.signUp(
        phone: phone,
        password: password,
        email: email,
      );

      if (response.user != null) {
        return SignUpResult.success(response.user!.id);
      }
      return SignUpResult.failure('Signup failed. Please try again.');
    } catch (e) {
      return SignUpResult.failure(_extractMessage(e));
    }
  }

  String _extractMessage(dynamic error) {
    final msg = error.toString();
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return 'This phone number is already registered. Try logging in.';
    }
    if (msg.contains('network')) {
      return 'Connection failed. Please check your internet.';
    }
    return 'Something went wrong. Please try again later.';
  }
}

/// Result wrapper for signup operation.
class SignUpResult {
  final bool isSuccess;
  final String? userId;
  final String? error;

  SignUpResult._({required this.isSuccess, this.userId, this.error});

  factory SignUpResult.success(String userId) =>
      SignUpResult._(isSuccess: true, userId: userId);

  factory SignUpResult.failure(String error) =>
      SignUpResult._(isSuccess: false, error: error);
}
