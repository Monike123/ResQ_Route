# ResQ Route — Project Context

## Core Value
**Prevent harm through AI-powered safe navigation** — optimizing for user safety over speed, with real-time monitoring, automatic intervention, and legally defensible journey documentation.

## Vision
ResQ Route is a verified, AI-enhanced, real-time personal safety navigation system. Unlike standard maps apps that optimize for time, ResQ Route optimizes for **safety** — preventing risky routes, actively monitoring users, auto-intervening in danger, and generating legal-grade trip reports.

## Constraints
- **Platform**: Flutter (cross-platform iOS & Android)
- **Backend**: Supabase (PostgreSQL + PostGIS, Auth, Realtime, Storage, Edge Functions)
- **AI**: Google Gemini API for crime analysis and safety scoring
- **Maps**: Google Maps Platform (Directions, Places, Geocoding)
- **SMS**: Twilio for emergency contact notifications
- **Identity**: Aadhaar/PAN API for government ID verification
- **State Management**: Riverpod
- **Navigation**: GoRouter

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter (Dart) |
| Backend | Supabase (PostgreSQL + PostGIS) |
| AI Engine | Google Gemini API |
| Maps | Google Maps Platform |
| SMS | Twilio |
| Identity | Aadhaar/PAN API |
| State Mgmt | Riverpod |
| Realtime | Supabase Realtime (WebSocket) |

## Requirements

### Validated
- ✓ Flutter project scaffold — existing
- ✓ Android/iOS platform configuration — existing
- ✓ Core infrastructure (theme, utils, errors, navigation) — existing
- ✓ CI/CD workflow — existing
- ✓ Dependency management — existing

### Active
- [ ] AUTH-01: User can create account with phone + OTP
- [ ] AUTH-02: User can log in and stay logged in across sessions
- [ ] AUTH-03: User can verify identity via Aadhaar/PAN
- [ ] AUTH-04: User can manage emergency contacts (up to 5)
- [ ] AUTH-05: Session management with JWT rotation
- [ ] AUTH-06: Abuse prevention (rate limiting, lockout)
- [ ] ROUTE-01: User can search destinations with autocomplete
- [ ] ROUTE-02: Google Maps route fetching with multiple alternatives
- [ ] ROUTE-03: Unsafe zone display on map
- [ ] ROUTE-04: Route caching for offline access
- [ ] SAFETY-01: AI-powered safety score algorithm
- [ ] SAFETY-02: Gemini AI crime analysis integration
- [ ] SAFETY-03: Route ranking by safety score
- [ ] SAFETY-04: Confidence scoring for safety predictions
- [ ] MONITOR-01: GPS tracking with journey state machine
- [ ] MONITOR-02: Deadman switch (stationary detection)
- [ ] MONITOR-03: Voice trigger system for hands-free SOS
- [ ] MONITOR-04: Route deviation detection
- [ ] SOS-01: Multi-trigger SOS activation
- [ ] SOS-02: Emergency contact SMS alerts via Twilio
- [ ] SOS-03: Forensic snapshot capture
- [ ] SOS-04: Public tracking link for emergency contacts
- [ ] REPORT-01: Safety Route Report (SRR) generation
- [ ] REPORT-02: PDF generation with map snapshots
- [ ] REPORT-03: Report integrity hashing (SHA-256)
- [ ] ADMIN-01: Web admin dashboard with RBAC
- [ ] ADMIN-02: Unsafe zone moderation
- [ ] ADMIN-03: Analytics dashboard
- [ ] SEC-01: Data encryption at rest and in transit
- [ ] SEC-02: PII handling compliance (Aadhaar Act)
- [ ] SEC-03: Row Level Security policies
- [ ] TEST-01: Unit + integration + load testing
- [ ] TEST-02: Emergency simulation testing
- [ ] TEST-03: App store deployment

### Out of Scope
- Social features (friend connections, public profiles)
- Ride-hailing integration
- Real-time traffic optimization (safety > speed)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Supabase over FastAPI | Faster development, managed infra, built-in Auth/RLS | Adopted |
| Riverpod over Bloc | Less boilerplate, compile-time safety | Adopted |
| GoRouter for navigation | Declarative routing, deep link support | Adopted |
| Google Fonts Inter | Clean, modern, accessibility-focused | Adopted |
| Feature-first architecture | Scalable, maintainable modular structure | Adopted |
| --dart-define for secrets | Compile-time env vars, not in source code | Adopted |

## Detailed Planning Documents
Full phase-by-phase implementation details are in:
`c:\Users\Manas\Desktop\ResQ Route\Project_resQ_route\`

---
*Last updated: 2026-02-19 after Phase 1 completion*
