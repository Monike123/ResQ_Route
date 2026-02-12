# 02 — PII Handling & Data Retention

## Objective
Implement strict PII handling policies, data retention schedules, and right-to-deletion compliance.

---

## PII Classification

| Data | Classification | Retention | Action on Delete |
|------|---------------|-----------|-----------------|
| Phone number | PII | Account lifetime | Purge on account deletion |
| Email | PII | Account lifetime | Purge on account deletion |
| Aadhaar hash | Sensitive PII | Account lifetime | Purge on account deletion |
| Location points | PII | 30 days | Auto-purge via pg_cron |
| SOS location data | Evidence | 7 years | Retain for legal purposes |
| Journey data | PII | 90 days summary, 30 days points | Summarize then purge |
| Profile image | PII | Account lifetime | Delete from storage |
| Device info | Metadata | 30 days | Auto-purge |

## Auto-Purge Implementation

```sql
-- Daily cleanup jobs
SELECT cron.schedule('purge-location-data', '0 3 * * *',
  $$DELETE FROM journey_points 
    WHERE recorded_at < NOW() - INTERVAL '30 days'
    AND journey_id NOT IN (
      SELECT journey_id FROM sos_events WHERE status != 'false_alarm'
    )$$
);

SELECT cron.schedule('purge-device-sessions', '30 3 * * *',
  $$DELETE FROM device_sessions 
    WHERE last_active_at < NOW() - INTERVAL '30 days'$$
);

SELECT cron.schedule('purge-rate-limits', '0 * * * *',
  $$DELETE FROM rate_limits 
    WHERE window_start < NOW() - INTERVAL '15 minutes'$$
);
```

## Right to Deletion (GDPR/Data Protection)

```sql
CREATE OR REPLACE FUNCTION delete_user_data(target_user_id UUID)
RETURNS void AS $$
BEGIN
    -- Delete in dependency order
    DELETE FROM feedback WHERE user_id = target_user_id;
    DELETE FROM reports WHERE user_id = target_user_id;
    DELETE FROM journey_points WHERE journey_id IN (
        SELECT id FROM journeys WHERE user_id = target_user_id
    );
    DELETE FROM journeys WHERE user_id = target_user_id;
    DELETE FROM routes WHERE user_id = target_user_id;
    DELETE FROM emergency_contacts WHERE user_id = target_user_id;
    DELETE FROM device_sessions WHERE user_id = target_user_id;
    
    -- Anonymize (don't delete) SOS events for legal retention
    UPDATE sos_events SET 
        metadata = metadata || '{"anonymized": true}'
    WHERE user_id = target_user_id;
    
    -- Delete profile
    DELETE FROM user_profiles WHERE id = target_user_id;
    
    -- Delete storage files
    -- (Note: handle via Edge Function that calls Storage API)
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## Log Redaction

```dart
class LogRedactor {
  static String redactPhone(String phone) {
    if (phone.length < 4) return '****';
    return '****${phone.substring(phone.length - 4)}';
  }

  static String redactEmail(String email) {
    final parts = email.split('@');
    return '${parts[0].substring(0, 2)}***@${parts[1]}';
  }

  // NEVER log: Aadhaar, PAN, passwords, full phone numbers
}
```

---

## Verification
- [ ] Auto-purge jobs scheduled via pg_cron
- [ ] 30-day retention for location data enforced
- [ ] SOS data retained 7 years (anonymized)
- [ ] Delete user function removes all PII
- [ ] Logs contain no raw PII
