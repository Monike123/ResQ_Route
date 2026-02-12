# 07 — Abuse Prevention & Rate Limiting

## Objective
Prevent brute force attacks, account enumeration, spam signups, and abuse of authentication endpoints.

---

## Rate Limiting Strategy

### Client-Side Rate Limiter

```dart
class RateLimiterService {
  final SharedPreferences _prefs;

  static const int _maxAttempts = 5;
  static const int _windowMinutes = 15;

  Future<bool> isLocked(String identifier) async {
    final key = 'rate_limit_$identifier';
    final data = _prefs.getString(key);
    if (data == null) return false;

    final record = json.decode(data);
    final attempts = record['attempts'] as int;
    final firstAttempt = DateTime.parse(record['first_attempt']);
    final elapsed = DateTime.now().difference(firstAttempt);

    if (elapsed.inMinutes >= _windowMinutes) {
      await reset(identifier); // Window expired
      return false;
    }

    return attempts >= _maxAttempts;
  }

  Future<void> recordFailedAttempt(String identifier) async {
    final key = 'rate_limit_$identifier';
    final data = _prefs.getString(key);

    if (data == null) {
      await _prefs.setString(key, json.encode({
        'attempts': 1,
        'first_attempt': DateTime.now().toIso8601String(),
      }));
    } else {
      final record = json.decode(data);
      record['attempts'] = (record['attempts'] as int) + 1;
      await _prefs.setString(key, json.encode(record));
    }
  }

  Future<void> reset(String identifier) async {
    await _prefs.remove('rate_limit_$identifier');
  }

  Future<int> remainingAttempts(String identifier) async {
    final key = 'rate_limit_$identifier';
    final data = _prefs.getString(key);
    if (data == null) return _maxAttempts;
    final record = json.decode(data);
    return _maxAttempts - (record['attempts'] as int);
  }
}
```

### Server-Side (Supabase Edge Function Rate Limit)

For critical endpoints, implement server-side checks:

```sql
-- Rate limit tracking table
CREATE TABLE public.rate_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    identifier VARCHAR(255) NOT NULL,   -- IP or phone number
    endpoint VARCHAR(100) NOT NULL,
    attempts INTEGER DEFAULT 1,
    window_start TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(identifier, endpoint)
);

-- Cleanup function (run via pg_cron hourly)
CREATE OR REPLACE FUNCTION cleanup_expired_rate_limits()
RETURNS void AS $$
BEGIN
    DELETE FROM public.rate_limits 
    WHERE window_start < NOW() - INTERVAL '15 minutes';
END;
$$ LANGUAGE plpgsql;
```

---

## Anti-Abuse Measures

### 1. Account Enumeration Prevention
Never reveal whether a phone/email EXISTS in the system:

```dart
// BAD: "This phone number is not registered"
// GOOD: "If this phone number is registered, you'll receive an OTP"
```

### 2. Signup Spam Prevention
```
- Minimum 30 seconds between signup attempts from same device
- OTP verification required before profile creation
- Aadhaar/PAN uniqueness prevents duplicate accounts
```

### 3. Suspicious Activity Logging

```sql
CREATE TABLE public.security_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(50) NOT NULL,
    -- 'login_failed', 'account_locked', 'suspicious_ip', etc.
    identifier VARCHAR(255),
    ip_address VARCHAR(45),
    user_agent TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- No RLS — only accessible via service role
```

### 4. IP-Based Blocking

Track failed login IPs and temporarily block excessive failures:

| Threshold | Action |
|-----------|--------|
| 5 failures / 15 min (per account) | Lock account temporarily |
| 20 failures / 15 min (per IP) | Block IP temporarily |
| 50 failures / hour (per IP) | Block IP for 24 hours + alert admin |

---

## User Feedback During Lockout

```
┌─────────────────────────────┐
│   ⚠️ Account Temporarily     │
│      Locked                  │
│                             │
│  Too many failed login      │
│  attempts.                  │
│                             │
│  Try again in: 12:34        │
│                             │
│  [ Forgot Password? ]       │
│  [ Contact Support ]        │
└─────────────────────────────┘
```

---

## Verification
- [ ] Login locks after 5 failed attempts
- [ ] Lockout expires after 15 minutes
- [ ] Account enumeration not possible
- [ ] Signup spam prevented (OTP gate)
- [ ] Security events logged
- [ ] Remaining attempts shown to user
