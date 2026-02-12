# 🛡️ ResQ Route — Master Execution Plan

> **Personal Travel Protection Infrastructure Platform**
> Built with **Flutter** (Frontend) + **Supabase** (Backend) + **Google Gemini AI**

---

## 📋 Project Overview

ResQ Route is a **verified, AI-enhanced, real-time personal safety navigation system** that prioritizes user protection over mere efficiency. Unlike standard navigation apps that optimize for time, ResQ Route optimizes for **safety** — preventing risky routes, actively monitoring users during travel, auto-intervening in danger scenarios, generating legal-grade journey documentation, and continuously improving safety intelligence.

### Core Mission
- **Prevent** risky route selection through AI-powered safety scoring
- **Monitor** users during travel with GPS, voice, and movement analysis
- **Intervene** automatically in danger scenarios via SOS protocols
- **Document** journeys with legally defensible trip reports (SRR)
- **Learn** and improve through crowdsourced feedback and AI recalibration

---

## 🏗️ Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile App** | Flutter (Dart) | Cross-platform iOS & Android |
| **Backend** | Supabase (PostgreSQL + PostGIS) | Auth, DB, Realtime, Storage, Edge Functions |
| **AI Engine** | Google Gemini API | Crime analysis, safety scoring, news aggregation |
| **Maps** | Google Maps Platform | Directions, Places, Static Maps |
| **SMS** | Twilio | Emergency contact notifications |
| **Identity** | Aadhaar/PAN API | Government ID verification |
| **State Mgmt** | Riverpod / Bloc | Flutter state management |
| **Realtime** | Supabase Realtime (WebSocket) | Live tracking, SOS broadcasts |
| **Storage** | Supabase Storage | Reports, photos, profile images |
| **Edge Functions** | Supabase Edge Functions (Deno) | Server-side logic, API integrations |
| **Python Env** | `.venv` (pre-configured) | Data scripts, ML, ingestion tools |

---

## 🔄 Supabase Architecture (Replaces Custom FastAPI Backend)

The original spec uses FastAPI + Celery + Redis. We adapt to **Supabase** for faster development and managed infrastructure:

| Original Component | Supabase Equivalent |
|--------------------|---------------------|
| FastAPI REST API | Supabase Edge Functions + PostgREST Auto-API |
| PostgreSQL + PostGIS | Supabase PostgreSQL (PostGIS extension enabled) |
| JWT Auth + Refresh Tokens | Supabase Auth (built-in JWT, OAuth, MFA) |
| Redis Cache | Supabase Realtime + PostgreSQL materialized views |
| Celery Task Queue | Supabase Edge Functions + Database Webhooks + pg_cron |
| WebSocket Server | Supabase Realtime Channels |
| S3 Storage | Supabase Storage Buckets |
| RBAC | Supabase Row Level Security (RLS) |

> [!IMPORTANT]
> Supabase credentials will be provided during Phase 1 backend setup. Do NOT hardcode any credentials.

---

## 📐 Phased Development Plan

The project is split into **10 phases**, each with its own Git branch, detailed implementation files, and verification checkpoints.

### Phase Overview

| # | Phase | Key Deliverables | Dependencies | Est. Complexity |
|---|-------|-----------------|--------------|-----------------|
| 1 | **Foundation & Project Setup** | Flutter project, Supabase init, folder structure, CI/CD scaffold | None | 🟢 Low |
| 2 | **Identity & Authentication** | Sign up, login, OTP, Aadhaar/PAN verify, emergency contacts | Phase 1 | 🟡 Medium |
| 3 | **Route Intelligence Engine** | Destination input, Google Maps integration, route fetching, unsafe zone display | Phase 2 | 🟡 Medium |
| 4 | **Safety Scoring & AI Integration** | Gemini AI crime analysis, safety score algorithm, route ranking | Phase 3 | 🔴 High |
| 5 | **Live Monitoring Engine** | GPS tracking, state machine, deadman switch, voice trigger, route deviation | Phase 4 | 🔴 High |
| 6 | **Emergency Response System** | SOS triggers, SMS alerts, forensic snapshots, emergency services integration | Phase 5 | 🔴 High |
| 7 | **SRR Reporting Engine** | PDF generation, map snapshots, integrity hashing, share links | Phase 6 | 🟡 Medium |
| 8 | **Admin Dashboard** | Web admin panel, moderation workflows, analytics, safety score tuning | Phase 7 | 🟡 Medium |
| 9 | **Security Hardening & Compliance** | Encryption, PII handling, Aadhaar compliance, threat mitigation, penetration testing | Phase 8 | 🔴 High |
| 10 | **Testing, Optimization & Deployment** | Load testing, chaos testing, battery optimization, app store deployment | Phase 9 | 🟡 Medium |

---

## 📁 Directory Structure for Plans

```
Project_resQ_route/
├── 00_MASTER_PLAN.md                  ← This file (overall roadmap)
├── 01_GIT_STRATEGY.md                 ← Git branching & backup strategy
├── 02_SECURITY_CHECKLIST.md           ← Cross-phase security checklist
│
├── Phase_01_Foundation/
│   ├── PHASE_01_OVERVIEW.md           ← Phase summary & objectives
│   ├── 01_flutter_project_setup.md
│   ├── 02_supabase_initialization.md
│   ├── 03_folder_structure.md
│   ├── 04_dependency_management.md
│   ├── 05_ci_cd_scaffold.md
│   └── 06_environment_config.md
│
├── Phase_02_Authentication/
│   ├── PHASE_02_OVERVIEW.md
│   ├── 01_supabase_auth_setup.md
│   ├── 02_user_registration_flow.md
│   ├── 03_login_flow.md
│   ├── 04_aadhaar_pan_verification.md
│   ├── 05_emergency_contacts.md
│   ├── 06_session_management.md
│   └── 07_abuse_prevention.md
│
├── Phase_03_Route_Engine/
│   ├── PHASE_03_OVERVIEW.md
│   ├── 01_destination_input_system.md
│   ├── 02_google_maps_integration.md
│   ├── 03_route_fetching_algorithm.md
│   ├── 04_unsafe_zone_display.md
│   ├── 05_database_schema_routes.md
│   └── 06_route_caching.md
│
├── Phase_04_Safety_Scoring/
│   ├── PHASE_04_OVERVIEW.md
│   ├── 01_safety_score_algorithm.md
│   ├── 02_gemini_ai_integration.md
│   ├── 03_crime_data_pipeline.md
│   ├── 04_route_ranking_logic.md
│   ├── 05_confidence_scoring.md
│   └── 06_ai_cost_optimization.md
│
├── Phase_05_Live_Monitoring/
│   ├── PHASE_05_OVERVIEW.md
│   ├── 01_journey_state_machine.md
│   ├── 02_gps_tracking_service.md
│   ├── 03_stationary_deadman_switch.md
│   ├── 04_voice_trigger_system.md
│   ├── 05_route_deviation_detection.md
│   ├── 06_movement_smoothing.md
│   └── 07_battery_optimization.md
│
├── Phase_06_Emergency_Response/
│   ├── PHASE_06_OVERVIEW.md
│   ├── 01_sos_lifecycle.md
│   ├── 02_emergency_contact_sms.md
│   ├── 03_twilio_integration.md
│   ├── 04_forensic_snapshot.md
│   ├── 05_public_tracking_link.md
│   ├── 06_emergency_services_api.md
│   └── 07_fallback_mechanisms.md
│
├── Phase_07_Reporting/
│   ├── PHASE_07_OVERVIEW.md
│   ├── 01_srr_report_schema.md
│   ├── 02_pdf_generation.md
│   ├── 03_map_snapshot_rendering.md
│   ├── 04_integrity_hashing.md
│   ├── 05_share_link_system.md
│   └── 06_feedback_system.md
│
├── Phase_08_Admin_Dashboard/
│   ├── PHASE_08_OVERVIEW.md
│   ├── 01_admin_roles_rbac.md
│   ├── 02_unsafe_zone_moderation.md
│   ├── 03_flag_dispute_resolution.md
│   ├── 04_crime_data_ingestion.md
│   ├── 05_analytics_dashboard.md
│   └── 06_safety_score_tuning.md
│
├── Phase_09_Security/
│   ├── PHASE_09_OVERVIEW.md
│   ├── 01_data_encryption.md
│   ├── 02_pii_handling_compliance.md
│   ├── 03_aadhaar_compliance.md
│   ├── 04_rls_policies.md
│   ├── 05_threat_model.md
│   ├── 06_logging_redaction.md
│   └── 07_secure_coding_audit.md
│
└── Phase_10_Testing_Deployment/
    ├── PHASE_10_OVERVIEW.md
    ├── 01_unit_testing.md
    ├── 02_integration_testing.md
    ├── 03_load_testing.md
    ├── 04_emergency_simulations.md
    ├── 05_gps_mock_testing.md
    ├── 06_chaos_testing.md
    ├── 07_performance_optimization.md
    └── 08_app_store_deployment.md
```

---

## 🔀 Git Strategy (Per Phase)

Each phase gets its own **feature branch** from `develop`, merged via PR on completion:

```
main (production-stable)
├── develop (integration branch)
│   ├── phase/01-foundation
│   ├── phase/02-authentication
│   ├── phase/03-route-engine
│   ├── phase/04-safety-scoring
│   ├── phase/05-live-monitoring
│   ├── phase/06-emergency-response
│   ├── phase/07-reporting
│   ├── phase/08-admin-dashboard
│   ├── phase/09-security
│   └── phase/10-testing-deployment
```

**Backup Strategy**: Each phase completion triggers a tagged release (`v0.1.0`, `v0.2.0`, etc.) and a ZIP backup of the full project state.

> See [01_GIT_STRATEGY.md](file:///c:/Users/Manas/Desktop/ResQ%20Route/Project_resQ_route/01_GIT_STRATEGY.md) for full details.

---

## 🔒 Security-First Approach

Security is NOT a final-phase afterthought. Each phase includes **built-in security checkpoints**:

| Phase | Security Focus |
|-------|---------------|
| 1 | Environment variable management, `.gitignore` for secrets |
| 2 | Argon2 hashing, JWT rotation, Supabase RLS, rate limiting |
| 3 | API key protection, input validation |
| 4 | AI prompt injection protection, cost controls |
| 5 | Location data encryption, background task permissions |
| 6 | Emergency data immutability, forensic integrity |
| 7 | Report tamper-proofing (SHA-256), share link expiry |
| 8 | Admin MFA, RBAC enforcement, audit logging |
| 9 | Full threat model, penetration testing, compliance audit |
| 10 | Final security audit, dependency vulnerability scan |

> See [02_SECURITY_CHECKLIST.md](file:///c:/Users/Manas/Desktop/ResQ%20Route/Project_resQ_route/02_SECURITY_CHECKLIST.md) for the complete checklist.

---

## 💬 Chat Strategy

| Chat | Purpose |
|------|---------|
| **Chat 1 (This)** | 📋 Planning, architecture, adding new features to the plan |
| **Chat 2** | 🔨 Implementation — building from the plan files |
| **Chat 3** | 🐛 Debugging & Error Resolution post-build |

---

## ⚠️ Questions for User Before Phase 1

> [!IMPORTANT]
> The following decisions need your input before we begin implementation:

1. **Admin Dashboard**: Should the admin panel be a **Flutter Web** app or a separate **React/Next.js** web app?
2. **Identity Verification**: Do you have access to a specific **Aadhaar/PAN verification API provider**, or should we stub this for now?
3. **Maps API**: Do you have a **Google Maps Platform API key** ready, or should we plan for obtaining one?
4. **Twilio**: Do you have a **Twilio account** for SMS, or should we use a mock SMS service initially?
5. **Target Platform**: Are we targeting **both iOS and Android** from Phase 1, or starting with one?
6. **Flutter State Management**: Preference between **Riverpod**, **Bloc**, or **Provider**?
7. **Offline Support**: How critical is offline mode for the initial release? Should we prioritize it early or defer to optimization?
