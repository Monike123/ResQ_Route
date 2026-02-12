# 01 — Destination Input System

## Objective
Implement an intuitive destination search with Google Places Autocomplete, recent searches, and saved places.

---

## Home Screen Layout

```
┌─────────────────────────────────┐
│  🔍 Where are you going?       │  ← Search bar (tappable)
├─────────────────────────────────┤
│                                 │
│        [Google Map View]        │  ← Current location centered
│          📍 You are here        │
│        🔴 Unsafe Zone           │
│        🔴 Unsafe Zone           │
│                                 │
├─────────────────────────────────┤
│  Recent Searches                │
│  📍 Office - 2.5 km            │
│  📍 Home - 5.1 km              │
│  📍 Mall - 3.2 km              │
├─────────────────────────────────┤
│  [🆘 SOS]    [📄 SRR]          │  ← Bottom action bar
└─────────────────────────────────┘
```

---

## Search Screen (Tap on Search Bar)

```
┌─────────────────────────────────┐
│  ← 🔍 [Search destination... ] │
│                                 │
│  SUGGESTIONS (Places API)       │
│  ──────────────────────────     │
│  📍 Indiranagar, Bengaluru      │
│  📍 Indira Gandhi Airport       │
│  📍 India Gate, New Delhi       │
│                                 │
│  SAVED PLACES                   │
│  ──────────────────────────     │
│  🏠 Home                        │
│  🏢 Work                        │
│  ⭐ Gym                         │
│                                 │
│  RECENT                         │
│  ──────────────────────────     │
│  🕐 Coffee Shop, MG Road       │
│  🕐 Hospital, Koramangala      │
└─────────────────────────────────┘
```

---

## Google Places Autocomplete

### Edge Function: `places-autocomplete`
Server-proxied to protect API key:

```typescript
// supabase/functions/places-autocomplete/index.ts
serve(async (req) => {
  const { query, lat, lng } = await req.json();
  
  const apiKey = Deno.env.get('GOOGLE_MAPS_API_KEY')!;
  const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json` +
    `?input=${encodeURIComponent(query)}` +
    `&location=${lat},${lng}` +
    `&radius=50000` +       // 50km radius bias
    `&components=country:in` + // Restrict to India
    `&key=${apiKey}`;
  
  const response = await fetch(url);
  const data = await response.json();
  
  return new Response(JSON.stringify({
    predictions: data.predictions?.map((p: any) => ({
      placeId: p.place_id,
      description: p.description,
      mainText: p.structured_formatting?.main_text,
      secondaryText: p.structured_formatting?.secondary_text,
    })) ?? [],
  }));
});
```

### Place Details (Get coordinates from Place ID)
```typescript
// supabase/functions/place-details/index.ts
serve(async (req) => {
  const { placeId } = await req.json();
  const apiKey = Deno.env.get('GOOGLE_MAPS_API_KEY')!;
  
  const url = `https://maps.googleapis.com/maps/api/place/details/json` +
    `?place_id=${placeId}` +
    `&fields=geometry,name,formatted_address` +
    `&key=${apiKey}`;
  
  const response = await fetch(url);
  const data = await response.json();
  
  return new Response(JSON.stringify({
    lat: data.result?.geometry?.location?.lat,
    lng: data.result?.geometry?.location?.lng,
    name: data.result?.name,
    address: data.result?.formatted_address,
  }));
});
```

---

## Flutter Implementation

### Search Service
```dart
class PlacesSearchService {
  final SupabaseClient _client;

  Future<List<PlacePrediction>> searchPlaces({
    required String query,
    required double lat,
    required double lng,
  }) async {
    if (query.length < 3) return []; // Min 3 chars

    final response = await _client.functions.invoke(
      'places-autocomplete',
      body: {'query': query, 'lat': lat, 'lng': lng},
    );

    final data = response.data as Map<String, dynamic>;
    return (data['predictions'] as List)
        .map((p) => PlacePrediction.fromJson(p))
        .toList();
  }

  Future<PlaceDetails> getPlaceDetails(String placeId) async {
    final response = await _client.functions.invoke(
      'place-details',
      body: {'placeId': placeId},
    );
    return PlaceDetails.fromJson(response.data);
  }
}
```

### Debounced Search (prevent excessive API calls)
```dart
class SearchDebouncer {
  Timer? _timer;
  
  void run(VoidCallback action, {Duration delay = const Duration(milliseconds: 500)}) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
}
```

---

## Recent Searches & Saved Places

### Local Storage
```dart
class RecentSearchesService {
  static const _key = 'recent_searches';
  static const _maxRecent = 10;

  final SharedPreferences _prefs;

  Future<void> addSearch(PlaceDetails place) async {
    final searches = await getRecentSearches();
    searches.removeWhere((s) => s.placeId == place.placeId); // Deduplicate
    searches.insert(0, place);
    if (searches.length > _maxRecent) searches.removeLast();
    await _prefs.setString(_key, json.encode(searches.map((s) => s.toJson()).toList()));
  }

  Future<List<PlaceDetails>> getRecentSearches() async {
    final data = _prefs.getString(_key);
    if (data == null) return [];
    return (json.decode(data) as List)
        .map((j) => PlaceDetails.fromJson(j))
        .toList();
  }
}
```

---

## Verification
- [ ] Search bar triggers Places Autocomplete
- [ ] Debounce prevents API spam (500ms delay)
- [ ] Place selection resolves to lat/lng coordinates
- [ ] Recent searches saved and displayed
- [ ] Map pins to selected destination
- [ ] API key NOT exposed in client (routed through Edge Function)
