/// Application-wide constants and configuration values.
enum AppEnvironment { development, staging, production }

class AppConfig {
  AppConfig._();

  static AppEnvironment get environment {
    const env = String.fromEnvironment(
      'APP_ENVIRONMENT',
      defaultValue: 'development',
    );
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

  // ── Deadman Switch Thresholds ──
  static const int stationaryThresholdMeters = 10;
  static const int stationaryTimeoutMinutes = 20;
  static const int stationaryCountdownSeconds = 60;

  // ── GPS Update Intervals ──
  static const int gpsUpdateIntervalMs = 5000; // Normal
  static const int gpsSOSIntervalMs = 20000; // During SOS (every 20s)

  // ── Rate Limits ──
  static const int maxRouteCalcsPerMinute = 10;
  static const int maxLoginAttemptsPerWindow = 5;
  static const int loginWindowMinutes = 15;

  // ── Safety Score Weights ──
  static const double crimeWeight = 0.35;
  static const double flagWeight = 0.25;
  static const double commercialWeight = 0.20;
  static const double lightingWeight = 0.10;
  static const double populationWeight = 0.10;
}
