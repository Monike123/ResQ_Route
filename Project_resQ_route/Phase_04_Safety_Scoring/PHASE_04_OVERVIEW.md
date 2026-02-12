# Phase 04 — Safety Scoring & AI Integration

## Objective
Implement the core differentiator — AI-powered safety scoring that analyzes crime data, user flags, commercial density, and environmental factors to rank routes by safety.

## Prerequisites
- Phase 3 completed (Routes fetched and stored)
- Google Gemini API key configured
- Crime data table populated (or seeded with test data)

## Deliverables
| # | Deliverable | Detailed File |
|---|-------------|---------------|
| 1 | Safety score algorithm | [01_safety_score_algorithm.md](./01_safety_score_algorithm.md) |
| 2 | Gemini AI integration | [02_gemini_ai_integration.md](./02_gemini_ai_integration.md) |
| 3 | Crime data pipeline | [03_crime_data_pipeline.md](./03_crime_data_pipeline.md) |
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

## Security Checkpoints (Phase 4)
- [ ] AI prompt injection prevention
- [ ] Gemini API key never in client code
- [ ] AI response validation (schema check)
- [ ] Fallback when AI unavailable
- [ ] Cost monitoring alerts

## Git Branch
```bash
git checkout -b phase/04-safety-scoring
```

## Verification Criteria
- [ ] Safety scores calculated for all 3 routes
- [ ] Scores update in real-time on route cards
- [ ] AI analysis returns valid crime assessments
- [ ] Fallback scores generated when AI is down
- [ ] Routes correctly ranked (highest safety = recommended)
