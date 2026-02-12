# 02 — Performance Optimization

## Objective
Optimize app performance to meet non-functional requirements: cold start < 3s, route calculation < 5s, smooth 60fps UI.

---

## Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Cold start | < 3 seconds | Stopwatch from tap to home screen |
| Route calculation | < 5 seconds | API call to route cards rendered |
| Map render | < 2 seconds | Map tiles loaded + markers placed |
| PDF generation | < 10 seconds | Tap to PDF ready |
| Memory usage | < 200 MB | Profiler during active journey |
| Frame rate | 60 fps | Flutter DevTools during scrolling |

## Optimization Strategies

### 1. Lazy Loading
```dart
// Load heavy features only when needed
late final SafetyMapWidget _map = SafetyMapWidget(); // Created on first use
```

### 2. Image & Asset Optimization
- Compress all assets with `flutter_image_compress`
- Use WebP format for profile images
- Lazy load map tiles (Google Maps handles this)

### 3. Network Optimization
- Batch API requests where possible
- Cache route results (Phase 3, file 06)
- Use Supabase Realtime instead of polling
- Gzip compression on Edge Function responses

### 4. Database Query Optimization
```sql
-- Ensure all queries use indexed columns
EXPLAIN ANALYZE SELECT * FROM crime_data 
WHERE ST_DWithin(location::geography, 
    ST_SetSRID(ST_MakePoint(77.5946, 12.9716), 4326)::geography, 5000);
-- Should show "Index Scan using idx_crime_data_location"
```

### 5. Widget Optimization
```dart
// Use const constructors
const SizedBox(height: 16);

// Use RepaintBoundary for complex widgets
RepaintBoundary(
  child: SafetyScoreChart(score: route.safetyScore),
);

// Use ListView.builder for long lists
ListView.builder(
  itemCount: routes.length,
  itemBuilder: (context, index) => RouteCard(route: routes[index]),
);
```

---

## Profiling

```bash
# Run in profile mode
flutter run --profile

# Open DevTools
flutter DevTools
```

## Verification
- [ ] Cold start < 3 seconds measured
- [ ] Route calculation < 5 seconds measured
- [ ] 60 fps during scrolling and animations
- [ ] Memory stays under 200 MB
