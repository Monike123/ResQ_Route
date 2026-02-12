# 04 — Safety Score Tuning Panel

## Objective
Allow admins to adjust safety score component weights and preview the impact before applying changes.

---

## Tuning UI

```
┌─────────────────────────────────────┐
│  ⚙️ Safety Score Configuration       │
│  ─────────────────────────────────── │
│                                     │
│  Component Weights (must sum to 1.0)│
│                                     │
│  Crime Density:  ━━━━━━━━░░  0.35   │
│  User Flags:     ━━━━━━░░░░  0.25   │
│  Commercial:     ━━━━░░░░░░  0.20   │
│  Lighting:       ━━░░░░░░░░  0.10   │
│  Population:     ━━░░░░░░░░  0.10   │
│                                     │
│  Total: 1.00 ✅                      │
│                                     │
│  [PREVIEW CHANGES]                  │
│  [APPLY WEIGHTS]                    │
│                                     │
│  ⚠️ Last changed: 2024-01-10        │
│  by: admin@resqroute.com            │
└─────────────────────────────────────┘
```

## Weights Storage

```sql
CREATE TABLE public.safety_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value JSONB NOT NULL,
    updated_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default weights
INSERT INTO safety_config (config_key, config_value) VALUES
('score_weights', '{
    "crime_density": 0.35,
    "user_flags": 0.25,
    "commercial": 0.20,
    "lighting": 0.10,
    "population": 0.10
}');
```

## Preview Mode

Before applying new weights, show impact on 10 sample routes:

```dart
Future<List<ScorePreview>> previewWeightChange(Map<String, double> newWeights) async {
  final routes = await supabase.from('routes')
      .select('id, safety_breakdown')
      .not('safety_breakdown', 'is', null)
      .limit(10);

  return routes.map((r) {
    final breakdown = r['safety_breakdown']['components'];
    final oldScore = r['safety_breakdown']['overall_score'];
    final newScore = 
        (breakdown['crime_density_score'] * newWeights['crime_density']!) +
        (breakdown['user_flag_score'] * newWeights['user_flags']!) +
        (breakdown['commercial_factor'] * newWeights['commercial']!) +
        (breakdown['lighting_factor'] * newWeights['lighting']!) +
        (breakdown['population_density'] * newWeights['population']!);
    
    return ScorePreview(routeId: r['id'], oldScore: oldScore, newScore: newScore);
  }).toList();
}
```

---

## Verification
- [ ] Weights adjustable via sliders (sum to 1.0)
- [ ] Preview shows impact on sample routes
- [ ] Changes logged in audit trail
- [ ] New weights apply to future score calculations
