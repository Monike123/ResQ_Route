# 06 — Environment Configuration

## Objective
Set up secure environment variable management for development, staging, and production environments.

---

## Environment Variables

### `.env.example` (committed to Git)
```env
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Google Maps
GOOGLE_MAPS_API_KEY=your-google-maps-key-here

# Google Gemini AI
GEMINI_API_KEY=your-gemini-api-key-here

# Twilio
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=+1234567890

# Aadhaar/PAN Verification API
IDENTITY_VERIFICATION_API_KEY=your-api-key
IDENTITY_VERIFICATION_API_URL=https://api-provider.example.com

# App Config
APP_ENVIRONMENT=development
APP_DEBUG=true
```

### `.env` (NOT committed — in `.gitignore`)
Same structure, with actual credential values.

---

## Flutter Environment Variable Loading

### Compile-Time Variables (via `--dart-define`)

For secrets that must be available in the Flutter app (client-side):
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-key \
  --dart-define=GOOGLE_MAPS_API_KEY=your-key
```

Access in Dart:
```dart
class EnvConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
}
```

### Server-Side Only Variables (Edge Functions)

Variables like `SUPABASE_SERVICE_ROLE_KEY`, `TWILIO_AUTH_TOKEN`, and `GEMINI_API_KEY` are NEVER in the client app. They go into:
- Supabase Dashboard → Edge Functions → Secrets
- Or via CLI: `supabase secrets set MY_SECRET=value`

---

## Environment-Specific Configurations

### `lib/core/constants/app_constants.dart`
```dart
enum AppEnvironment { development, staging, production }

class AppConfig {
  static AppEnvironment get environment {
    const env = String.fromEnvironment('APP_ENVIRONMENT', defaultValue: 'development');
    switch (env) {
      case 'production':
        return AppEnvironment.production;
      case 'staging':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.development;
    }
  }

  static bool get isProduction => environment == AppEnvironment.production;
  static bool get isDevelopment => environment == AppEnvironment.development;
  
  // Deadman switch thresholds
  static const int stationaryThresholdMeters = 10;
  static const int stationaryTimeoutMinutes = 20;
  static const int stationaryCountdownSeconds = 60;
  
  // GPS update intervals
  static const int gpsUpdateIntervalMs = 5000;   // Normal
  static const int gpsSOSIntervalMs = 20000;      // During SOS (every 20s)
  
  // API rate limits
  static const int maxRouteCalcsPerMinute = 10;
  static const int maxLoginAttemptsPerWindow = 5;
  static const int loginWindowMinutes = 15;
}
```

---

## VS Code Launch Configuration

### `.vscode/launch.json`
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "ResQ Route (Dev)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": [
        "--dart-define=SUPABASE_URL=${env:SUPABASE_URL}",
        "--dart-define=SUPABASE_ANON_KEY=${env:SUPABASE_ANON_KEY}",
        "--dart-define=GOOGLE_MAPS_API_KEY=${env:GOOGLE_MAPS_API_KEY}",
        "--dart-define=APP_ENVIRONMENT=development"
      ]
    }
  ]
}
```

---

## Verification
- [ ] `.env.example` exists with all variables listed (no values)
- [ ] `.env` is in `.gitignore`
- [ ] `EnvConfig` class reads variables correctly
- [ ] App launches with `--dart-define` flags
- [ ] No secrets visible in `flutter build apk` output
- [ ] Edge functions can access their secrets via `Deno.env.get()`
