# 01 — Supabase Auth Setup

## Objective
Configure Supabase Auth for phone + email authentication with OTP verification, and integrate into the Flutter app.

---

## Supabase Dashboard Configuration

### Auth Providers
Navigate to Supabase Dashboard → Authentication → Providers:

| Provider | Status | Configuration |
|----------|--------|---------------|
| Email | ✅ Enabled | Confirmation required, secure email change |
| Phone (SMS) | ✅ Enabled | Twilio as SMS provider |
| Password | ✅ Enabled | Min 8 chars, requires uppercase+lowercase+digit+special |

### Twilio SMS Setup
Dashboard → Authentication → Phone Auth:
```
Twilio Account SID: <from user's Twilio account>
Twilio Auth Token: <from user's Twilio account>
Twilio Message Service SID: <or phone number>
SMS Template: "Your ResQ Route verification code is: {{.Code}}"
```

### Auth Settings
Dashboard → Authentication → Settings:
```
Site URL: com.resqroute.resq_route://     (deep link scheme)
JWT Expiry: 900                           (15 minutes)
Refresh Token Rotation: Enabled
Refresh Token Reuse Interval: 10          (seconds)
MFA: Disabled for users, Enabled for admins (Phase 8)
```

---

## Flutter Auth Service

### `lib/features/auth/data/datasources/auth_remote_datasource.dart`
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDataSource {
  final SupabaseClient _client;
  
  AuthRemoteDataSource(this._client);

  // === SIGNUP ===
  Future<AuthResponse> signUpWithPhone({
    required String phone,
    required String password,
  }) async {
    return await _client.auth.signUp(
      phone: phone,
      password: password,
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

  // === LOGIN ===
  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      phone: phone,
      password: password,
    );
  }

  // === OTP VERIFICATION ===
  Future<AuthResponse> verifyOTP({
    required String phone,
    required String token,
    required OtpType type,
  }) async {
    return await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: type,
    );
  }

  // === SESSION ===
  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // === AUTH STATE LISTENER ===
  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}
```

### Auth State Listener (App-Level)

```dart
// In main.dart or auth provider:
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  final event = data.event;
  final session = data.session;

  switch (event) {
    case AuthChangeEvent.signedIn:
      // Navigate to home, store session
      break;
    case AuthChangeEvent.signedOut:
      // Navigate to login, clear local data
      break;
    case AuthChangeEvent.tokenRefreshed:
      // Token auto-refreshed by Supabase
      break;
    case AuthChangeEvent.userUpdated:
      // Refresh user profile
      break;
    default:
      break;
  }
});
```

---

## Deep Linking (for Email Confirmation)

### Android (`AndroidManifest.xml`)
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="com.resqroute.resq_route" />
</intent-filter>
```

### iOS (`Info.plist`)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.resqroute.resq_route</string>
        </array>
    </dict>
</array>
```

---

## Verification
- [ ] Phone signup sends OTP via Twilio
- [ ] Email signup sends confirmation link
- [ ] OTP verification creates a session
- [ ] Auth state changes detected app-wide
- [ ] Deep linking opens app from email confirmation
- [ ] Token auto-refresh works silently
