import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/models/emergency_contact_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/signup_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/rate_limiter_service.dart';
import '../../../../core/services/session_manager.dart';

// ── Supabase Client ──
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

// ── Data Sources ──
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => ProfileRemoteDataSource(ref.watch(supabaseClientProvider)),
);

// ── Services ──
final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);

final sharedPrefsProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

final rateLimiterProvider = Provider<RateLimiterService>((ref) {
  final prefs = ref.watch(sharedPrefsProvider).valueOrNull;
  if (prefs == null) {
    throw StateError('SharedPreferences not yet initialized');
  }
  return RateLimiterService(prefs);
});

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager(
    ref.watch(supabaseClientProvider),
    ref.watch(secureStorageProvider),
  );
});

// ── Repository ──
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(profileRemoteDataSourceProvider),
  ),
);

// ── Use Cases ──
final signUpUseCaseProvider = Provider<SignUpUseCase>(
  (ref) => SignUpUseCase(ref.watch(authRepositoryProvider)),
);

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(
    ref.watch(authRepositoryProvider),
    ref.watch(secureStorageProvider),
    ref.watch(rateLimiterProvider),
    ref.watch(sessionManagerProvider),
  ),
);

final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(
    ref.watch(authRepositoryProvider),
    ref.watch(secureStorageProvider),
    ref.watch(sessionManagerProvider),
  ),
);

// ── Auth State ──

/// Tracks the current auth state across the app.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Current user profile from Supabase.
final currentUserProfileProvider = FutureProvider<UserEntity?>((ref) async {
  final user = ref.watch(supabaseClientProvider).auth.currentUser;
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).getUserProfile(user.id);
});

/// Emergency contacts for the current user.
final emergencyContactsProvider =
    FutureProvider<List<EmergencyContactModel>>((ref) async {
  final user = ref.watch(supabaseClientProvider).auth.currentUser;
  if (user == null) return [];
  return ref.watch(authRepositoryProvider).getEmergencyContacts(user.id);
});

// ── Signup State ──
final signupLoadingProvider = StateProvider<bool>((ref) => false);
final signupErrorProvider = StateProvider<String?>((ref) => null);

// ── Login State ──
final loginLoadingProvider = StateProvider<bool>((ref) => false);
final loginErrorProvider = StateProvider<String?>((ref) => null);
