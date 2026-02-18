import '../repositories/auth_repository.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/session_manager.dart';

/// Logout use case — clears session, tokens, and stops auto-refresh.
class LogoutUseCase {
  final AuthRepository _authRepo;
  final SecureStorageService _secureStorage;
  final SessionManager _sessionManager;

  LogoutUseCase(this._authRepo, this._secureStorage, this._sessionManager);

  Future<void> execute({bool allDevices = false}) async {
    // 1. Stop background services
    _sessionManager.stopAutoRefresh();

    // 2. Sign out from Supabase
    await _authRepo.signOut(allDevices: allDevices);

    // 3. Clear local secure storage
    await _secureStorage.clearAll();
  }
}
