# Roadmap: ResQ Route

## Overview

ResQ Route is built in 10 phases, progressing from foundation through authentication, route intelligence, AI-powered safety scoring, live monitoring, emergency response, reporting, admin tools, security hardening, and final deployment.

## Phases

- [x] **Phase 1: Foundation & Project Setup** - Flutter scaffold, platform configs, core infrastructure, CI/CD
- [ ] **Phase 2: Identity & Authentication** - Supabase Auth, signup/login, Aadhaar/PAN, emergency contacts
- [ ] **Phase 3: Route Intelligence Engine** - Destination search, Google Maps, route fetching, unsafe zones
- [ ] **Phase 4: Safety Scoring & AI** - Safety algorithm, Gemini AI, crime pipeline, route ranking
- [ ] **Phase 5: Live Monitoring Engine** - GPS tracking, state machine, deadman switch, voice trigger
- [ ] **Phase 6: Emergency Response System** - SOS triggers, SMS alerts, forensic snapshots
- [ ] **Phase 7: SRR Reporting Engine** - PDF generation, map snapshots, integrity hashing
- [ ] **Phase 8: Admin Dashboard** - Web admin panel, moderation, analytics
- [ ] **Phase 9: Security Hardening** - Encryption, PII compliance, Aadhaar compliance, RLS
- [ ] **Phase 10: Testing & Deployment** - Load testing, chaos testing, app store deployment

## Phase Details

### Phase 1: Foundation & Project Setup
**Goal**: Working Flutter project with all infrastructure and tooling ready
**Depends on**: Nothing (first phase)
**Requirements**: Foundation
**Success Criteria**:
  1. `flutter analyze` passes with 0 errors
  2. `flutter test` passes
  3. Project builds for Android
  4. Core infrastructure files exist (theme, utils, navigation, errors)
  5. CI/CD pipeline runs on push
**Plans**: 1 plan (completed)

Plans:
- [x] 01-01: Create Flutter project, platform configs, core infrastructure, CI/CD

### Phase 2: Identity & Authentication
**Goal**: Verified user identity with secure auth, emergency contacts, and abuse prevention
**Depends on**: Phase 1
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06
**Success Criteria**:
  1. User can create account with phone + OTP
  2. User can log in and sessions persist across app restarts
  3. User can verify identity via Aadhaar/PAN
  4. User can add/edit/remove emergency contacts (up to 5)
  5. Repeated failed login attempts trigger rate limiting
**Plans**: TBD

### Phase 3: Route Intelligence Engine
**Goal**: Users can search destinations and view multiple route alternatives with unsafe zone overlays
**Depends on**: Phase 2
**Requirements**: ROUTE-01, ROUTE-02, ROUTE-03, ROUTE-04
**Success Criteria**:
  1. User types destination and sees autocomplete suggestions
  2. App fetches multiple route alternatives from Google Maps
  3. Unsafe zones display as colored overlays on the map
  4. Previously searched routes are cached for offline use
**Plans**: TBD

### Phase 4: Safety Scoring & AI
**Goal**: AI-powered safety scores rank routes by danger level using crime data and Gemini analysis
**Depends on**: Phase 3
**Requirements**: SAFETY-01, SAFETY-02, SAFETY-03, SAFETY-04
**Success Criteria**:
  1. Each route segment receives a safety score (0-100)
  2. Gemini AI analyzes crime data for route corridors
  3. Routes are ranked by composite safety score
  4. Confidence level shown for each safety prediction
**Plans**: TBD

### Phase 5: Live Monitoring Engine
**Goal**: Real-time GPS tracking with automatic danger detection during journeys
**Depends on**: Phase 4
**Requirements**: MONITOR-01, MONITOR-02, MONITOR-03, MONITOR-04
**Success Criteria**:
  1. User can start a monitored journey with live GPS tracking
  2. Stationary detection triggers deadman switch alert
  3. Voice command "help" triggers SOS
  4. Route deviation of >500m triggers a warning
**Plans**: TBD

### Phase 6: Emergency Response System
**Goal**: Multi-trigger SOS with SMS alerts, forensic capture, and public tracking
**Depends on**: Phase 5
**Requirements**: SOS-01, SOS-02, SOS-03, SOS-04
**Success Criteria**:
  1. SOS can be triggered via button, voice, or deadman switch
  2. Emergency contacts receive SMS with live tracking link
  3. Forensic snapshot captures location, audio, and environment data
  4. Public tracking link shows real-time user location
**Plans**: TBD

### Phase 7: SRR Reporting Engine
**Goal**: Legally defensible Safety Route Reports with tamper-proof integrity
**Depends on**: Phase 6
**Requirements**: REPORT-01, REPORT-02, REPORT-03
**Success Criteria**:
  1. PDF report generated after each journey
  2. Report includes map snapshots of the route taken
  3. SHA-256 hash verifies report integrity
**Plans**: TBD

### Phase 8: Admin Dashboard
**Goal**: Web-based admin panel for moderation, analytics, and safety score tuning
**Depends on**: Phase 7
**Requirements**: ADMIN-01, ADMIN-02, ADMIN-03
**Success Criteria**:
  1. Admin can log in with MFA
  2. Admin can moderate unsafe zone reports
  3. Analytics dashboard shows usage metrics
**Plans**: TBD

### Phase 9: Security Hardening
**Goal**: Full security audit, encryption, compliance, and penetration testing
**Depends on**: Phase 8
**Requirements**: SEC-01, SEC-02, SEC-03
**Success Criteria**:
  1. All PII encrypted at rest
  2. Aadhaar data handling complies with regulations
  3. RLS policies enforce row-level access control
**Plans**: TBD

### Phase 10: Testing & Deployment
**Goal**: Comprehensive testing suite and app store deployment
**Depends on**: Phase 9
**Requirements**: TEST-01, TEST-02, TEST-03
**Success Criteria**:
  1. Unit test coverage >80%
  2. Emergency simulation test passes
  3. App published on Google Play Store
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 1/1 | Complete | 2026-02-19 |
| 2. Authentication | 0/? | Not started | - |
| 3. Route Engine | 0/? | Not started | - |
| 4. Safety Scoring | 0/? | Not started | - |
| 5. Live Monitoring | 0/? | Not started | - |
| 6. Emergency Response | 0/? | Not started | - |
| 7. Reporting | 0/? | Not started | - |
| 8. Admin Dashboard | 0/? | Not started | - |
| 9. Security | 0/? | Not started | - |
| 10. Testing & Deploy | 0/? | Not started | - |
