# 03 — Forensic Snapshot Capture

## Objective
At the moment of SOS trigger, capture an immutable forensic record: location, time, battery, journey path, device state, nearby unsafe zones — for legal and safety purposes.

---

## Snapshot Contents

```json
{
  "snapshot_id": "uuid",
  "sos_event_id": "uuid",
  "captured_at": "ISO 8601",
  "user_id": "uuid",
  "user_name": "redacted if needed",
  "location": { "lat": 12.9716, "lng": 77.5946, "accuracy": 5.2 },
  "speed_mps": 1.2,
  "heading": 180,
  "battery_level": 42,
  "device": { "model": "Pixel 7", "os": "Android 14" },
  "journey_summary": {
    "journey_id": "uuid",
    "started_at": "ISO 8601",
    "route_safety_score": 72.5,
    "distance_traveled_km": 1.8,
    "points_recorded": 215
  },
  "last_10_positions": [
    { "lat": 12.971, "lng": 77.594, "recorded_at": "..." }
  ],
  "nearby_unsafe_zones": [
    { "id": "uuid", "reason": "Poor lighting", "distance_m": 180 }
  ],
  "trigger_type": "button",
  "integrity_hash": "SHA-256 hash of all above fields"
}
```

## Integrity Hash

```dart
String generateIntegrityHash(Map<String, dynamic> snapshot) {
  final content = json.encode(snapshot);
  final bytes = utf8.encode(content);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
```

> [!IMPORTANT]
> The integrity hash ensures the forensic record hasn't been tampered with after capture. Store the snapshot and hash separately — the hash in the `sos_events` table, the full snapshot in Supabase Storage.

## Storage

```dart
// Store as JSON in Supabase Storage (immutable bucket)
await Supabase.instance.client.storage
    .from('forensic-snapshots')
    .upload(
      '${sosEventId}/snapshot.json',
      utf8.encode(json.encode(snapshot)),
      fileOptions: FileOptions(contentType: 'application/json'),
    );
```

---

## Verification
- [ ] Snapshot captured within 2 seconds of SOS trigger
- [ ] Contains all required fields
- [ ] Integrity hash generated and stored
- [ ] Snapshot stored in immutable storage bucket
- [ ] Last 10 positions included for trail
