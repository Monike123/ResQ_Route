import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user_entity.dart';
import '../../data/models/emergency_contact_model.dart';

/// Abstract auth repository interface for the domain layer.
abstract class AuthRepository {
  // ── Auth ──
  Future<AuthResponse> signUp({
    required String phone,
    required String password,
    String? email,
  });

  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  });

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendOtp({required String phone});

  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  });

  Future<void> resetPassword(String emailOrPhone);

  Future<void> signOut({bool allDevices = false});

  // ── Session ──
  Session? get currentSession;
  User? get currentUser;
  Stream<AuthState> get authStateChanges;

  // ── Profile ──
  Future<UserEntity?> getUserProfile(String userId);
  Future<void> updateProfile(String userId, Map<String, dynamic> data);
  Future<void> completeOnboarding(String userId);

  // ── Emergency Contacts ──
  Future<List<EmergencyContactModel>> getEmergencyContacts(String userId);
  Future<void> saveEmergencyContacts(List<EmergencyContactModel> contacts);
  Future<void> deleteEmergencyContact(String contactId);
}
