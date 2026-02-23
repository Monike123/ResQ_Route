# Phase 04 — Safety Scoring & AI Integration

## Objective
Implement the core differentiator — AI-powered safety scoring that analyzes real-world crime data (via Gemini + Perplexity web search), user flags, commercial density, and environmental factors to rank routes by safety.

## Prerequisites
- Phase 3 completed (Routes fetched and stored)
- Gemini API key configured
- Perplexity API key configured

> [!NOTE]
> Crime data is sourced via AI web search — no pre-seeded database required.
> When government crime APIs become available (future), they supplement AI data automatically.

## Deliverables
| # | Deliverable | Detailed File |
|---|-------------|---------------|
| 1 | Safety score algorithm | [01_safety_score_algorithm.md](./01_safety_score_algorithm.md) |
| 2 | Gemini & Perplexity AI integration | [02_gemini_ai_integration.md](./02_gemini_ai_integration.md) |
| 3 | Crime data pipeline (AI-sourced) | [03_crime_data_pipeline.md](./03_crime_data_pipeline.md) |
| 4 | Route ranking logic | [04_route_ranking_logic.md](./04_route_ranking_logic.md) |
| 5 | Confidence scoring | [05_confidence_scoring.md](./05_confidence_scoring.md) |
| 6 | AI cost optimization | [06_ai_cost_optimization.md](./06_ai_cost_optimization.md) |

## Safety Score Formula

```
SafetyScore = (CrimeDensity × 0.35) + (UserFlags × 0.25) + 
              (CommercialFactor × 0.20) + (Lighting × 0.10) + 
              (PopulationDensity × 0.10)
```

All component scores are normalized to 0-100. Higher = safer.

## Crime Data Source Architecture

```
Route name from Google Maps
        ↓
CrimeSearchOrchestrator
  ├── Gemini AI (crime analysis)      ─┐
  └── Perplexity AI (web search)      ─┤── parallel
        ↓                               │
Merge & deduplicate ←───────────────────┘
        ↓
Cache in crime_data table (7-day TTL)
        ↓
Feed into SafetyScoreService
```

## Security Checkpoints (Phase 4)
- [x] AI prompt injection prevention
- [x] API keys not in client code (AppConfig placeholders, prod uses Edge Function env)
- [x] AI response validation (schema check)
- [x] Fallback when AI unavailable
- [ ] Cost monitoring alerts

## Verification Criteria
- [x] Safety scores calculated for all 3 routes
- [ ] Scores update in real-time on route cards
- [x] AI analysis returns valid crime assessments
- [x] Fallback scores generated when AI is down
- [ ] Routes correctly ranked (highest safety = recommended)
