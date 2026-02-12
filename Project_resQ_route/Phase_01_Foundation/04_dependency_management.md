# 04 — Dependency Management

## Objective
Define and install all Flutter packages required across the project, organized by feature area and phase.

---

## Core Dependencies (`pubspec.yaml`)

### Phase 1 — Foundation
```yaml
dependencies:
  flutter:
    sdk: flutter

  # Supabase
  supabase_flutter: ^2.5.0         # Supabase client (Auth, DB, Realtime, Storage)
  
  # State Management (choose one — user preference)
  flutter_riverpod: ^2.5.0          # Riverpod for state management
  riverpod_annotation: ^2.3.0       # Code generation for Riverpod
  
  # Navigation
  go_router: ^14.0.0                # Declarative routing
  
  # Storage
  flutter_secure_storage: ^9.0.0    # Encrypted local storage for tokens
  shared_preferences: ^2.2.0        # Simple key-value storage
  
  # UI
  google_fonts: ^6.0.0              # Custom typography
  flutter_svg: ^2.0.0               # SVG icon support
  
  # Utilities
  intl: ^0.19.0                     # Date/number formatting
  uuid: ^4.0.0                      # UUID generation
  logger: ^2.0.0                    # Structured logging
  equatable: ^2.0.5                 # Value equality
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.4.0        # Code gen for Riverpod
  json_serializable: ^6.8.0         # JSON serialization
  mockito: ^5.4.0                   # Mocking for tests
  mocktail: ^1.0.0                  # Alternative mocking
```

### Phase 2 — Authentication
```yaml
  # Already included via supabase_flutter (Supabase Auth)
  pin_code_fields: ^8.0.0           # OTP input widget
  image_picker: ^1.0.0              # Profile photo picker
  image_cropper: ^5.0.0             # Profile photo cropping
```

### Phase 3 — Route Engine
```yaml
  google_maps_flutter: ^2.6.0       # Google Maps widget
  flutter_polyline_points: ^2.0.0   # Route polyline rendering
  geolocator: ^11.0.0               # GPS position
  geocoding: ^3.0.0                 # Address ↔ coordinates
  http: ^1.2.0                      # HTTP client for API calls
  dio: ^5.4.0                       # Advanced HTTP client (interceptors, retries)
```

### Phase 4 — Safety Scoring
```yaml
  google_generative_ai: ^0.4.0      # Gemini AI Dart SDK
  fl_chart: ^0.68.0                 # Charts for safety score visualization
```

### Phase 5 — Live Monitoring
```yaml
  flutter_background_service: ^5.0.0 # Background execution
  flutter_local_notifications: ^17.0.0 # Local notifications
  speech_to_text: ^6.6.0            # Voice recognition
  vibration: ^1.8.0                 # Haptic feedback
  wakelock_plus: ^1.2.0             # Keep screen alive
  sensors_plus: ^4.0.0              # Accelerometer/gyroscope
```

### Phase 6 — Emergency Response
```yaml
  url_launcher: ^6.2.0              # Open phone dialer, SMS
  share_plus: ^7.2.0                # Share tracking links
  flutter_sms: ^2.3.3               # Direct SMS sending (fallback)
```

### Phase 7 — Reporting
```yaml
  pdf: ^3.10.0                      # PDF generation
  printing: ^5.12.0                 # Print/share PDF
  screenshot: ^3.0.0                # Map snapshot capture
  crypto: ^3.0.3                    # SHA-256 hashing
  path_provider: ^2.1.0             # File system paths
```

---

## Dependency Installation
```bash
flutter pub get
```

> [!IMPORTANT]
> Do NOT install all dependencies at once. Install only the packages needed for the current phase. Use `flutter pub add <package>` to add one at a time during implementation.

---

## Dependency Update Policy
- Run `flutter pub outdated` weekly
- Update patch versions freely
- Minor version updates: test on both platforms first
- Major version updates: only during a dedicated phase

---

## Verification
- [ ] `flutter pub get` resolves without conflicts  
- [ ] `flutter analyze` has no errors
- [ ] `flutter test` runs (even if no tests yet)
