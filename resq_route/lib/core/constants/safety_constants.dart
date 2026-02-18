/// Safety-related constants for scoring and monitoring.
class SafetyConstants {
  SafetyConstants._();

  // ── Score Ranges ──
  static const double scoreSafe = 7.0; // 7.0-10.0 = Safe
  static const double scoreModerate = 4.0; // 4.0-6.9 = Moderate
  // Below 4.0 = Unsafe

  // ── Deviation Thresholds ──
  static const double routeDeviationMeters = 100.0;
  static const int deviationAlertDelaySeconds = 30;

  // ── Unsafe Zone Radius ──
  static const double unsafeZoneRadiusMeters = 500.0;

  // ── SOS Countdown ──
  static const int sosCountdownSeconds = 10;
  static const int sosShakeThreshold = 3; // Number of shakes to trigger SOS

  // ── Voice Trigger Keywords ──
  static const List<String> sosVoiceTriggers = [
    'help',
    'help me',
    'bachao',
    'emergency',
    'sos',
  ];
}
