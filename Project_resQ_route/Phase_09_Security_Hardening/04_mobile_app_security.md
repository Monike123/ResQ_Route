# 04 — Mobile App Security

## Objective
Harden the Flutter mobile app against reverse engineering, tampering, and data extraction.

---

## Build-Time Security

### Code Obfuscation
```bash
flutter build apk --obfuscate --split-debug-info=build/debug-info/
flutter build ios --obfuscate --split-debug-info=build/debug-info/
```

> [!IMPORTANT]
> Save `split-debug-info` output for each release — required for crash report symbolication.

### ProGuard (Android)
```
# android/app/proguard-rules.pro
-keep class io.flutter.** { *; }
-keep class com.google.** { *; }
-dontwarn com.google.**
-keepattributes *Annotation*
```

---

## Runtime Security

### Root/Jailbreak Detection
```dart
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

Future<bool> isDeviceCompromised() async {
  final jailbroken = await FlutterJailbreakDetection.jailbroken;
  final developerMode = await FlutterJailbreakDetection.developerMode;
  return jailbroken || developerMode;
}

// On app start:
if (await isDeviceCompromised()) {
  showSecurityWarning(); // Warn but don't block — user safety > security theater
}
```

### Screenshot Prevention (Sensitive Screens)
```dart
// Android: FLAG_SECURE
if (Platform.isAndroid) {
  await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
}
// Apply on: Login screen, OTP screen, Aadhaar entry
// Remove on: Map screen, journey screen
```

### Clipboard Security
```dart
// Clear clipboard after paste on sensitive fields
void onPaste(String value) {
  Future.delayed(Duration(seconds: 5), () {
    Clipboard.setData(ClipboardData(text: ''));
  });
}
```

---

## Network Security

### SSL Pinning
See `01_encryption_audit.md` for implementation.

### Debug Detection
```dart
bool get isDebugMode {
  bool debug = false;
  assert(() {
    debug = true;
    return true;
  }());
  return debug;
}

// In production: disable logging, disable dev tools
if (!isDebugMode) {
  // Disable debug features
}
```

---

## Verification
- [ ] APK obfuscated with split debug info saved
- [ ] ProGuard rules configured
- [ ] Root/jailbreak detection warns user
- [ ] Screenshot prevention on sensitive screens
- [ ] Clipboard auto-cleared after paste
- [ ] Debug mode detection in production
