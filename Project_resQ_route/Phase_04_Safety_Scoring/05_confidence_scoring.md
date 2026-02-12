# 05 — Confidence Scoring

## Objective
Generate a confidence score that indicates how reliable the safety assessment is, based on data quality, quantity, and recency.

---

## Confidence Formula

```
Confidence = (DataDensity × 0.4) + (DataRecency × 0.3) + (AIConfidence × 0.2) + (UserFeedback × 0.1)

DataDensity: How many data points exist near the route
  0 points = 0.1 | 1-5 = 0.4 | 6-15 = 0.7 | 15+ = 1.0

DataRecency: How recent is the crime data
  All < 30 days = 1.0 | Mix = 0.6 | All > 180 days = 0.3

AIConfidence: Gemini's self-reported confidence
  Directly from AI response (0-1)

UserFeedback: Historical accuracy of safety predictions
  Based on post-journey feedback matching predictions
```

## Display

```
🛡️ Safety Score: 85/100
📊 Confidence: High (0.82)
   "Based on 23 data points from the last 2 months"
```

## Low Confidence Warning

When confidence < 0.4:
```
⚠️ Limited safety data available for this area.
Exercise extra caution and consider sharing your live location.
```

---

## Verification
- [ ] Confidence score calculated per route
- [ ] Low confidence triggers user warning
- [ ] Data density factor reflects nearby data points
- [ ] AI confidence value incorporated when available
