/// API endpoint constants.
/// All sensitive API calls go through Supabase Edge Functions.
class ApiEndpoints {
  ApiEndpoints._();

  // ── Google Maps (client-side, key restricted) ──
  static const String googleDirectionsBase =
      'https://maps.googleapis.com/maps/api/directions/json';
  static const String googlePlacesBase =
      'https://maps.googleapis.com/maps/api/place';
  static const String googleGeocodingBase =
      'https://maps.googleapis.com/maps/api/geocode/json';

  // ── Supabase Edge Functions (server-side proxies) ──
  static String edgeFunction(String functionName) =>
      '/functions/v1/$functionName';

  static String get calculateSafetyScore =>
      edgeFunction('calculate-safety-score');
  static String get sendSosAlerts => edgeFunction('send-sos-alerts');
  static String get generateReport => edgeFunction('generate-report');
  static String get verifyIdentity => edgeFunction('verify-identity');
}
