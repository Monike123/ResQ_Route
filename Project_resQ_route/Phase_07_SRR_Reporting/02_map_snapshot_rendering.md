# 02 — Map Snapshot Rendering

## Objective
Capture a static map image of the journey route for embedding in the PDF report.

---

## Google Static Maps API

```typescript
// Edge Function: generate-map-snapshot
function buildStaticMapUrl(journey: any, route: any, unsafeZones: any[]): string {
  const apiKey = Deno.env.get('GOOGLE_MAPS_API_KEY')!;
  
  let url = `https://maps.googleapis.com/maps/api/staticmap` +
    `?size=640x400` +
    `&scale=2` +            // Retina quality
    `&maptype=roadmap` +
    `&path=enc:${route.polyline_encoded}|color:0x4285F4FF|weight:4`;

  // Start marker (green)
  url += `&markers=color:green|label:S|${route.origin_lat},${route.origin_lng}`;
  
  // End marker (blue)
  url += `&markers=color:blue|label:E|${route.dest_lat},${route.dest_lng}`;

  // Unsafe zone markers (red, max 5)
  for (const zone of unsafeZones.slice(0, 5)) {
    url += `&markers=color:red|size:small|${zone.latitude},${zone.longitude}`;
  }

  url += `&key=${apiKey}`;
  return url;
}
```

## Flutter Integration

```dart
Future<Uint8List> captureMapSnapshot(JourneyModel journey, RouteModel route) async {
  final response = await Supabase.instance.client.functions.invoke(
    'generate-map-snapshot',
    body: { 'journeyId': journey.id, 'routeId': route.id },
  );
  
  // Returns binary image data
  return response.data as Uint8List;
}
```

---

## Verification
- [ ] Static map generated with route polyline
- [ ] Start/end markers visible
- [ ] Unsafe zones shown as red markers
- [ ] Image quality sufficient for PDF (retina)
