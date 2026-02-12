# 03 — Integrity Hashing

## Objective
Generate SHA-256 hashes for SRR reports to ensure tamper-evident, legally defensible documentation.

---

## Hash Generation

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

String generateReportHash({
  required JourneyModel journey,
  required RouteModel route,
  required List<SOSEventModel> sosEvents,
}) {
  // Create deterministic content string
  final content = json.encode({
    'journey_id': journey.id,
    'user_id': journey.userId,
    'started_at': journey.startedAt.toIso8601String(),
    'completed_at': journey.completedAt?.toIso8601String(),
    'distance_km': route.distanceKm,
    'duration_min': route.durationMin,
    'safety_score': route.safetyScore,
    'status': journey.status,
    'sos_events': sosEvents.map((e) => e.id).toList(),
    'generated_at': DateTime.now().toUtc().toIso8601String(),
  });

  final bytes = utf8.encode(content);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
```

## Verification

Anyone can verify the hash by reconstructing the content from database records and comparing:

```sql
-- Store hash alongside source data reference
UPDATE reports SET 
    integrity_hash = 'computed_hash',
    hash_source_data = '{"journey_id": "...", ...}'  -- Store the hashed content
WHERE id = 'report_id';
```

> [!NOTE]
> The hash source data is stored separately so that verification is possible without reconstructing the exact content.

---

## Verification
- [ ] SHA-256 computed from journey + route data
- [ ] Hash stored in reports table
- [ ] Hash printed on PDF document
- [ ] Hash source data stored for re-verification
