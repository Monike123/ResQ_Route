# 04 — Route Ranking Logic

## Objective
Rank the 3 fetched routes by safety score and present them in an intuitive UI with clear differentiation.

---

## Ranking Algorithm

```dart
List<RouteModel> rankRoutes(List<RouteModel> routes) {
  // Sort by safety score descending (highest = safest)
  final scored = routes.where((r) => r.safetyScore != null).toList();
  scored.sort((a, b) => b.safetyScore!.compareTo(a.safetyScore!));
  
  // Assign labels
  if (scored.isNotEmpty) scored[0].label = 'Safest (Recommended)';
  if (scored.length > 1) scored[1].label = 'Balanced';
  if (scored.length > 2) scored[2].label = 'Shortest';
  
  return scored;
}
```

## Route Card Design (Scored)

```
┌─────────────────────────────────────┐
│ ⭐ Safest (Recommended)             │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│                                     │
│  🛡️ Safety: 92/100  ████████████░  │
│  📏 Distance: 3.2 km               │
│  ⏱️  Duration: 40 min               │
│  🏪 14 commercial points nearby    │
│  ⚠️ 1 unsafe zone on route         │
│                                     │
│  [  VIEW DETAILS  ] [SELECT ROUTE] │
└─────────────────────────────────────┘
```

## Route Details Bottom Sheet

When "VIEW DETAILS" is tapped:

```
┌─────────────────────────────────────┐
│  📊 Safety Breakdown                │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  Crime Density    ████████░░  78%   │
│  User Reports     █████████░  90%   │
│  Commercial Area  ████████░░  85%   │
│  Lighting         ████░░░░░░  80%   │
│  Population       █████████░  88%   │
│                                     │
│  ⚠️ AI Analysis:                    │
│  "Moderate risk area near segment 3.│
│   Precaution: Avoid after 10pm."    │
│                                     │
│  🗺️ [VIEW ON MAP]                   │
│  📋 [FULL AI REPORT]                │
└─────────────────────────────────────┘
```

---

## Score Color Coding

```dart
Color getScoreColor(double score) {
  if (score >= 80) return const Color(0xFF4CAF50); // Green
  if (score >= 60) return const Color(0xFFFFA726); // Orange  
  if (score >= 40) return const Color(0xFFFF7043); // Deep Orange
  return const Color(0xFFF44336);                   // Red
}

String getScoreLabel(double score) {
  if (score >= 80) return 'Safe';
  if (score >= 60) return 'Moderate';
  if (score >= 40) return 'Caution';
  return 'High Risk';
}
```

---

## Verification
- [ ] Routes ranked by safety score (highest first)
- [ ] Route cards show score, distance, duration, commercial points
- [ ] Color coding reflects safety level
- [ ] Detail bottom sheet shows score breakdown
- [ ] AI analysis summary displayed when available
