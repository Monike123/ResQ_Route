# ProGuard rules for ResQ Route (Android release builds)
# Phase 9: Security Hardening

-keep class io.flutter.** { *; }
-keep class com.google.** { *; }
-dontwarn com.google.**
-keepattributes *Annotation*

# Keep Supabase / Realtime classes
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Keep Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
