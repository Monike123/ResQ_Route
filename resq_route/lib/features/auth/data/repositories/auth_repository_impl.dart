import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/emergency_contact_model.dart';

/// Concrete implementation of [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _authDataSource;
  final ProfileRemoteDataSource _profileDataSource;

  AuthRepositoryImpl(this._authDataSource, this._profileDataSource);

  // ── Auth ──

  @override
  Future<AuthResponse> signUp({
    required String phone,
    required String password,
    String? email,
  }) async {
    return await _authDataSource.signUpWithPhone(
      phone: phone,
      password: password,
      email: email,
    );
  }

  @override
  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    return await _authDataSource.signInWithPhone(
      phone: phone,
      password: password,
    );
  }

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _authDataSource.signInWithEmail(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> sendOtp({required String phone}) async {
    await _authDataSource.sendOtp(phone: phone);
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    return await _authDataSource.verifyOtp(phone: phone, token: token);
  }

  @override
  Future<void> resetPassword(String emailOrPhone) async {
    if (emailOrPhone.contains('@')) {
      await _authDataSource.resetPasswordForEmail(emailOrPhone);
    } else {
      await _authDataSource.resetPasswordForPhone(emailOrPhone);
    }
  }

  @override
  Future<void> signOut({bool allDevices = false}) async {
    await _authDataSource.signOut(
      scope: allDevices ? SignOutScope.global : SignOutScope.local,
    );
  }

  // ── Session ──

  @override
  Session? get currentSession => _authDataSource.currentSession;

  @override
  User? get currentUser => _authDataSource.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _authDataSource.authStateChanges;

  // ── Profile ──

  @override
  Future<UserEntity?> getUserProfile(String userId) async {
    final model = await _profileDataSource.getProfile(userId);
    if (model == null) return null;
    return UserEntity(
      id: model.id,
      phone: model.phone,
      email: model.email,
      fullName: model.fullName,
      gender: model.gender,
      profileImageUrl: model.profileImageUrl,
      verificationStatus: model.verificationStatus,
      onboardingCompleted: model.onboardingCompleted,
    );
  }

  @override
  Future<void> updateProfile(
      String userId, Map<String, dynamic> data) async {
    await _profileDataSource.updateProfile(userId, data);
  }

  @override
  Future<void> completeOnboarding(String userId) async {
    await _profileDataSource.completeOnboarding(userId);
  }

  // ── Emergency Contacts ──

  @override
  Future<List<EmergencyContactModel>> getEmergencyContacts(
      String userId) async {
    return await _profileDataSource.getContacts(userId);
  }

  @override
  Future<void> saveEmergencyContacts(
      List<EmergencyContactModel> contacts) async {
    await _profileDataSource.saveAllContacts(contacts);
  }

  @override
  Future<void> deleteEmergencyContact(String contactId) async {
    await _profileDataSource.deleteContact(contactId);
  }
}
