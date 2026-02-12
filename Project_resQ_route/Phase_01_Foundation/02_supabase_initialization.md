# 02 — Supabase Initialization

## Objective
Set up the Supabase project, enable required extensions (PostGIS), configure authentication settings, and establish the initial database schema foundation.

---

## Steps

### 2.1 Supabase Project Setup

1. **Create Project** on [Supabase Dashboard](https://supabase.com/dashboard)
   - Project Name: `resq-route`
   - Database Password: Strong random password (store securely)
   - Region: Choose closest to target users (e.g., `ap-south-1` for India)

2. **Retrieve Credentials** (user will provide these):
   - `SUPABASE_URL` — Project URL (e.g., `https://xxxx.supabase.co`)
   - `SUPABASE_ANON_KEY` — Public anon key (safe for client-side)
   - `SUPABASE_SERVICE_ROLE_KEY` — Service role key (NEVER in client code, only edge functions)

### 2.2 Enable PostGIS Extension

Run in Supabase SQL Editor:
```sql
-- Enable PostGIS for geospatial data
CREATE EXTENSION IF NOT EXISTS postgis;

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pgcrypto for hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Verify extensions
SELECT * FROM pg_extension WHERE extname IN ('postgis', 'uuid-ossp', 'pgcrypto');
```

### 2.3 Configure Supabase Auth

In Supabase Dashboard → Authentication → Settings:

| Setting | Value |
|---------|-------|
| Enable Phone Auth | ✅ Yes |
| Enable Email Auth | ✅ Yes |
| Email Confirmations | ✅ Enabled |
| Phone Confirmations | ✅ Enabled (OTP) |
| JWT Expiry | 900 seconds (15 min) |
| Refresh Token Rotation | ✅ Enabled |
| Refresh Token Reuse Interval | 10 seconds |
| Minimum Password Length | 8 |
| Password Requirements | Uppercase, lowercase, number, special char |

### 2.4 Create Initial Database Tables

> [!NOTE]
> Full schema is built progressively per phase. This is the foundation.

```sql
-- ============================================
-- USERS PROFILE TABLE (extends Supabase auth.users)
-- ============================================
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(255),
    aadhar_hash VARCHAR(255),        -- SHA-256 hash of Aadhaar (never raw)
    pan_hash VARCHAR(255),            -- SHA-256 hash of PAN (never raw)
    verification_status TEXT DEFAULT 'pending' 
        CHECK (verification_status IN ('pending', 'verified', 'failed')),
    verification_type TEXT 
        CHECK (verification_type IN ('aadhar', 'pan', NULL)),
    profile_image_url VARCHAR(255),
    gender TEXT CHECK (gender IN ('male', 'female', 'other', NULL)),
    preferred_emergency_language VARCHAR(10) DEFAULT 'en',
    trust_score FLOAT DEFAULT 0.0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Users can only read/update their own profile
CREATE POLICY "Users can view own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON public.user_profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### 2.5 Supabase Storage Buckets

Create storage buckets for file storage:

```sql
-- Via Supabase Dashboard or SQL:
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('profile-images', 'profile-images', true),
    ('report-pdfs', 'report-pdfs', false),
    ('flag-photos', 'flag-photos', false);
```

Storage policies:
```sql
-- Profile images: users can upload their own
CREATE POLICY "Users can upload profile images"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'profile-images' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Profile images: public read
CREATE POLICY "Public profile image read"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'profile-images');
```

### 2.6 Flutter Supabase Client Setup

Add to `lib/core/supabase_client.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;
}
```

Update `lib/main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  // ... rest of app
}
```

Run the app with env vars:
```bash
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

---

## Verification
- [ ] Supabase project created and accessible
- [ ] PostGIS extension enabled (`SELECT PostGIS_version();` returns version)
- [ ] Auth settings configured (phone + email)
- [ ] `user_profiles` table created with RLS policies
- [ ] Storage buckets created
- [ ] Flutter client connects successfully (test query returns without error)
