# 01 — Encryption Audit & Implementation

## Objective
Audit and enforce encryption across all data flows — transit, rest, and client storage.

---

## Data in Transit

### TLS Configuration
Supabase endpoints automatically use TLS. Ensure client enforces:

```dart
// Ensure HTTPS-only in dio/http client
final dio = Dio(BaseOptions(
  baseUrl: 'https://your-project.supabase.co',
  // No HTTP fallback
));
```

### Certificate Pinning (Advanced)

```dart
// Use ssl_pinning_plugin for cert pinning
// Pin the Supabase SSL certificate fingerprint
final sslPinning = SslPinningPlugin(
  fingerprint: 'SHA256:YOUR_SUPABASE_CERT_FINGERPRINT',
  timeout: Duration(seconds: 10),
);
```

> [!WARNING]
> Certificate pinning requires certificate rotation management. When Supabase rotates their cert, you must update the app. Include a mechanism to update pins remotely.

---

## Data at Rest

### Database Encryption
Supabase uses encrypted PostgreSQL storage by default. No additional action needed.

### Client Storage Encryption
Already implemented via `flutter_secure_storage` (Phase 2):
- Android: EncryptedSharedPreferences (AES-256-SIV)
- iOS: Keychain (hardware-backed encryption)

### Sensitive Data Fields (Never Store Raw)

| Data | Storage Rule |
|------|-------------|
| Aadhaar number | SHA-256 hash only |
| PAN number | SHA-256 hash only |
| Password | Argon2 hash (Supabase handles) |
| JWT tokens | Encrypted local storage |
| API keys | Edge Function env vars only |
| Location data | Encrypted in transit, auto-purge after 30 days |

---

## Audit Checklist

```sql
-- Verify no raw PII stored
SELECT id, phone, email, aadhar_hash
FROM user_profiles
WHERE aadhar_hash NOT LIKE '%[a-f0-9]%'  -- Should all be hex hashes
LIMIT 1;
-- Should return 0 rows
```

---

## Verification
- [ ] All HTTP connections use HTTPS/TLS
- [ ] WebSocket connections use WSS
- [ ] Certificate pinning configured (optional for MVP)
- [ ] Client storage encrypted (SecureStorage)
- [ ] No raw PII in database
- [ ] API keys not in client bundle
