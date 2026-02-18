# ResQ Route — API Keys & Credentials Tracker

All keys needed before production. Placeholders are used during development.

| # | Service | Key / Credential | Where Used | Status |
|---|---------|-------------------|------------|--------|
| 1 | **Supabase** | Project URL (`https://xxx.supabase.co`) | `lib/core/constants/app_constants.dart` | ⏳ Placeholder |
| 2 | **Supabase** | Anon Key (public) | `lib/core/constants/app_constants.dart` | ⏳ Placeholder |
| 3 | **Supabase** | Service Role Key (private) | Edge Functions / server-side only | ⏳ Placeholder |
| 4 | **Google Maps** | Maps API Key (Android + iOS) | `AndroidManifest.xml`, `AppDelegate.swift` | ⏳ Placeholder |
| 4a | **Google Maps** | Directions API enabled | Edge Function `calculate-routes` | ⏳ Enable in GCP Console |
| 4b | **Google Maps** | Places API enabled | Edge Function `places-autocomplete` | ⏳ Enable in GCP Console |
| 4c | **Google Maps** | Geocoding API enabled | Edge Function `place-details` | ⏳ Enable in GCP Console |
| 5 | **Twilio** | Account SID | Supabase Auth → Phone provider | ⏳ Placeholder |
| 6 | **Twilio** | Auth Token | Supabase Auth → Phone provider | ⏳ Placeholder |
| 7 | **Twilio** | Messaging Service SID | Supabase Auth → Phone provider | ⏳ Placeholder |
| 8 | **Gemini API** | API Key | AI safety features (Phase 7+) | ⏳ Placeholder |
| 9 | **Identity Verification** | API Key | Aadhaar/PAN verify Edge Function | ⏳ Coming Soon |
| 10 | **Identity Verification** | API URL | Aadhaar/PAN verify Edge Function | ⏳ Coming Soon |

## How to provide keys

Once you have credentials, I will:
1. Update `lib/core/constants/app_constants.dart` with Supabase URL + Anon Key
2. Update `lib/core/supabase_client.dart` initialization
3. Set up `--dart-define` for compile-time injection
4. Add Edge Function env vars for service role key + third-party APIs

> **Security**: Keys are NEVER committed to git. They are injected via `--dart-define` or Supabase Edge Function secrets.
