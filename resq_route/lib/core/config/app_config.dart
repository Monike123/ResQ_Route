/// Centralized API configuration.
///
/// Placeholder values — replace with real keys before deployment.
/// In production, these should come from Supabase Edge Function
/// environment variables (never in client code).
class AppConfig {
  AppConfig._();

  /// Gemini API key — used for AI crime analysis.
  /// In production: served via Edge Function env var `GEMINI_API_KEY`.
  static const String geminiApiKey = 'GEMINI_API_KEY_PLACEHOLDER';

  /// Perplexity API key — used for web-based crime search.
  /// In production: served via Edge Function env var `PERPLEXITY_API_KEY`.
  static const String perplexityApiKey = 'PERPLEXITY_API_KEY_PLACEHOLDER';

  /// Gemini model for crime analysis.
  static const String geminiModel = 'gemini-2.0-flash';

  /// Perplexity model for web search.
  static const String perplexityModel = 'sonar';

  /// Gemini API base URL.
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Perplexity API base URL.
  static const String perplexityBaseUrl =
      'https://api.perplexity.ai';

  /// Crime data cache TTL in days.
  static const int crimeDataCacheDays = 7;
}
