# 01 — Flutter Project Setup

## Objective
Create the Flutter project, configure Android/iOS settings, and establish the base app with essential metadata.

---

## Steps

### 1.1 Create Flutter Project
```bash
flutter create --org com.resqroute --project-name resq_route --platforms android,ios .
```

> [!NOTE]
> The `--org` flag sets the Android package name (`com.resqroute.resq_route`) and iOS bundle identifier.

### 1.2 Configure `pubspec.yaml`
```yaml
name: resq_route
description: AI-powered personal safety navigation app
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

# Dependencies added in 04_dependency_management.md
```

### 1.3 Android Configuration

#### `android/app/build.gradle`
- **minSdkVersion**: `21` (Android 5.0) — required for background location
- **targetSdkVersion**: `34` (latest stable)
- **compileSdkVersion**: `34`
- Enable **multidex**: `multiDexEnabled true`
- Enable **Java 8 desugaring** (required for some plugins):
  ```gradle
  compileOptions {
      coreLibraryDesugaringEnabled true
      sourceCompatibility JavaVersion.VERSION_1_8
      targetCompatibility JavaVersion.VERSION_1_8
  }
  ```
- Add desugaring dependency:
  ```gradle
  dependencies {
      coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
  }
  ```

#### `android/app/src/main/AndroidManifest.xml`
Add required permissions:
```xml
<!-- Location -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

<!-- Foreground Service -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

<!-- Internet -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Vibrate (for alerts) -->
<uses-permission android:name="android.permission.VIBRATE" />

<!-- Microphone (voice SOS) -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- SMS (direct fallback) -->
<uses-permission android:name="android.permission.SEND_SMS" />

<!-- Phone state (for emergency calls) -->
<uses-permission android:name="android.permission.READ_PHONE_STATE" />

<!-- Wake Lock (keep app running) -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

#### Google Maps API Key (Android)
```xml
<!-- Inside <application> tag -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${GOOGLE_MAPS_API_KEY}" />
```
Reference this from `android/local.properties`:
```properties
GOOGLE_MAPS_API_KEY=YOUR_KEY_HERE
```

### 1.4 iOS Configuration

#### `ios/Runner/Info.plist`
Add usage description keys:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>ResQ Route needs your location to calculate safe routes.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>ResQ Route monitors your location during journeys for safety.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>ResQ Route needs background location access for safety monitoring.</string>

<key>NSMicrophoneUsageDescription</key>
<string>ResQ Route listens for voice-activated SOS triggers.</string>

<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
    <string>processing</string>
</array>
```

### 1.5 App Metadata
- **App Name**: ResQ Route
- **Package Name (Android)**: `com.resqroute.resq_route`
- **Bundle ID (iOS)**: `com.resqroute.resqRoute`
- **App Icon**: Generate using `flutter_launcher_icons` package (Phase 2+)
- **Splash Screen**: Configure using `flutter_native_splash` package

### 1.6 Initial App Entry Point

Create `lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ResQRouteApp());
}

class ResQRouteApp extends StatelessWidget {
  const ResQRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResQ Route',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), // Safety blue
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('ResQ Route — Setup Complete'),
        ),
      ),
    );
  }
}
```

---

## Verification
- [ ] `flutter doctor` passes without errors
- [ ] `flutter run` launches on Android emulator
- [ ] `flutter run` launches on iOS simulator (if on macOS)
- [ ] App displays "ResQ Route — Setup Complete"
- [ ] No build errors or warnings
