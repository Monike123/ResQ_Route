# 🧠 ResQ Route — Project Memory

> **Purpose**: This file is the single source of truth shared across all chat sessions (Planning, Execution, Debug). Paste this file's contents at the start of any new chat to give the AI full project context.
>
> **Last Updated**: 2026-02-18 23:57 IST
> **Current Stage**: ✅ Planning Complete → ⏳ Execution Pending

---

## 📌 What Is ResQ Route?

**ResQ Route** is a **women's safety navigation app** built with **Flutter + Supabase**. It provides AI-powered safe route suggestions, live journey monitoring, and emergency SOS alerts.

### Core Value Proposition
- User enters a destination → app fetches 3 alternative routes from Google Maps
- Each route is scored for safety using AI (crime data, user flags, lighting, commercial density)
- User picks the safest route → app monitors the journey in real-time
- If user is in danger → SOS triggers alert with SMS, live tracking link, and forensic snapshot

### Tech Stack
| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) — cross-platform mobile |
| Backend | Supabase (PostgreSQL + Auth + Edge Functions + Realtime + Storage) |
| Maps | Google Maps SDK + Directions API + Places API |
| AI | Google Gemini API for crime analysis & safety scoring |
| SMS | Twilio (primary) + direct device SMS (fallback) |
| Identity | Aadhaar/PAN verification (SHA-256 hashed) |
| CI/CD | GitHub Actions |

### Repository
- **GitHub**: `https://github.com/Monike123/ResQ_Route.git`
- **Branch**: `main`
- **Local Path**: `c:\Users\Manas\Desktop\ResQ Route\`

---

## 📂 Project Structure

```
ResQ Route/
├── Project_Plan/              ← Original 16 spec files (reference only)
├── Project_resQ_route/        ← Our planning docs (68+ files)
│   ├── 00_MASTER_PLAN.md      ← 10-phase roadmap
│   ├── 01_GIT_STRATEGY.md     ← Branch & commit conventions
│   ├── 02_SECURITY_CHECKLIST.md
│   ├── PROJECT_MEMORY.md      ← THIS FILE
│   ├── Phase_01_Foundation/   ← 7 files
│   ├── Phase_02_Authentication/ ← 8 files
│   ├── Phase_03_Route_Engine/ ← 7 files
│   ├── Phase_04_Safety_Scoring/ ← 7 files
│   ├── Phase_05_Live_Monitoring/ ← 8 files
│   ├── Phase_06_Emergency_Response/ ← 6 files
│   ├── Phase_07_SRR_Reporting/ ← 6 files
│   ├── Phase_08_Admin_Dashboard/ ← 5 files
│   ├── Phase_09_Security_Hardening/ ← 6 files
│   └── Phase_10_Testing_Deployment/ ← 6 files
└── resq_route_app/            ← Flutter app (TO BE CREATED in Phase 1)
```

---

## 🗺️ 10-Phase Roadmap

| Phase | Name | Status | Key Deliverables |
|-------|------|--------|-----------------|
| 1 | Foundation & Project Setup | ⏳ Not Started | Flutter project, Supabase init, folder structure, CI/CD, env config |
| 2 | Identity & Authentication | ⏳ Not Started | Auth, signup/login, Aadhaar/PAN, emergency contacts, sessions |
| 3 | Route Intelligence Engine | ⏳ Not Started | Destination search, Google Maps, route fetching, unsafe zones, caching |
| 4 | Safety Scoring & AI | ⏳ Not Started | Safety algorithm, Gemini AI, crime pipeline, route ranking |
| 5 | Live Monitoring Engine | ⏳ Not Started | Journey state machine, GPS, deadman switch, voice SOS, deviation |
| 6 | Emergency Response | ⏳ Not Started | SOS triggers, Twilio SMS, forensic snapshots, tracking links, fallbacks |
| 7 | SRR Reporting | ⏳ Not Started | PDF reports, map snapshots, integrity hashing, share links, feedback |
| 8 | Admin Dashboard | ⏳ Not Started | Admin auth/RBAC, flag moderation, analytics, score tuning |
| 9 | Security Hardening | ⏳ Not Started | Encryption, PII, STRIDE model, mobile security, pen testing |
| 10 | Testing & Deployment | ⏳ Not Started | Test strategy, performance, battery, app store, monitoring |

---

## ✅ What Has Been Done

### Planning Chat (Conversation: fcb03f9b-0b94-4fa9-a45a-616abeebb548)

**Date**: 2026-02-12 to 2026-02-18

1. **Research** — Read all 16 original project specification files from `Project_Plan/`
2. **Adapted Architecture** — Converted original FastAPI backend specs to **Supabase** (Edge Functions, RLS, Realtime)
3. **Created 68+ detailed MD files** organized into 10 phase folders, each containing:
   - Phase overview with deliverable table
   - Detailed implementation files with Dart/TypeScript code samples
   - SQL schemas with PostGIS support and RLS policies
   - Mermaid diagrams (flowcharts, state machines)
   - ASCII UI mockups
   - Verification checklists
4. **Git** — Initialized repo, committed all docs (89 files, 11,482 lines), pushed to GitHub

### Key Design Decisions Made During Planning
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Backend | Supabase (not FastAPI) | Managed service, Auth + DB + Realtime + Storage in one |
| State management | Riverpod | Type-safe, testable, modern Flutter standard |
| Routing | GoRouter | Declarative routing with deep link support |
| Architecture | Feature-first + Clean Architecture | `features/auth/`, `features/routes/`, etc. |
| Safety scoring | Weighted multi-factor (crime 35%, flags 25%, commercial 20%, lighting 10%, population 10%) | Balanced between data sources |
| API key security | Edge Functions proxy | Keys never in client code |
| Identity verification | SHA-256 hash of Aadhaar/PAN | Compliance — never store raw identity numbers |
| SOS fallback | Twilio → backup provider → direct device SMS → offline queue | SOS must always work |
| Deadman switch | 20 min stationary → 60s countdown → auto-SOS | Key safety differentiator |

---

## ⏳ What Needs To Be Done Next

### Execution Order (Follow Phases 1-10 Sequentially)

**Phase 1 is next.** Read `Phase_01_Foundation/PHASE_01_OVERVIEW.md` and its 6 sub-files for exact implementation steps.

Key first steps:
1. Create Flutter project: `flutter create resq_route_app`
2. Set up Supabase project at supabase.com
3. Implement folder structure per `Phase_01_Foundation/03_folder_structure.md`
4. Add dependencies per `Phase_01_Foundation/04_dependency_management.md`
5. Configure environment files per `Phase_01_Foundation/06_environment_config.md`
6. Set up GitHub Actions per `Phase_01_Foundation/05_ci_cd_scaffold.md`

---

## 📝 Execution Log

> Update this section as phases are implemented. Record what happened, issues encountered, and solutions applied.

### Phase 1: Foundation & Project Setup
- **Status**: ⏳ Not Started
- **Started**: —
- **Completed**: —
- **Notes**: —
- **Issues**: —

### Phase 2: Identity & Authentication
- **Status**: ⏳ Not Started
- **Started**: —
- **Completed**: —
- **Notes**: —
- **Issues**: —

### Phase 3: Route Intelligence Engine
- **Status**: ⏳ Not Started
- **Started**: —
- **Completed**: —
- **Notes**: —
- **Issues**: —

### Phase 4: Safety Scoring & AI
- **Status**: ⏳ Not Started
- **Started**: —
- **Completed**: —
- **Notes**: —
- **Issues**: —

### Phase 5: Live Monitoring Engine
- **Status**: ⏳ Not Started
- **Started**: —
- **Completed**: —
- **Notes**: —
- **Issues**: —

### Phase 6: Emergency Response
- **Status**: ⏳ Not Started
- **Started**: —
- **Completed**: —
- **Notes**: —
- **Issues**: —

### Phase 7: SRR Reporting
- **Status**: ⏳ Not Started
- **Started**: —
- **Completed**: —
- **Notes**: —
- **Issues**: —

### Phase 8: Admin Dashboard
- **Status**: ⏳ Not Started
- **Started**: —
- **Completed**: —
- **Notes**: —
- **Issues**: —

### Phase 9: Security Hardening
- **Status**: ⏳ Not Started
- **Started**: —
- **Completed**: —
- **Notes**: —
- **Issues**: —

### Phase 10: Testing & Deployment
- **Status**: ⏳ Not Started
- **Started**: —
- **Completed**: —
- **Notes**: —
- **Issues**: —

---

## 🐛 Debug & Error Log

> Update this section when bugs are found and fixed. Keep a running log for the Debug chat.

| # | Date | Phase | Error Summary | Root Cause | Fix Applied | Status |
|---|------|-------|---------------|-----------|-------------|--------|
| — | — | — | No errors yet | — | — | — |

---

## 🔑 Environment & Credentials Needed

> These are required for execution. Do NOT store actual values here — just track what's needed.

| Service | What's Needed | Status |
|---------|--------------|--------|
| Supabase | Project URL + anon key + service role key | ⏳ Not set up |
| Google Cloud | Maps SDK key, Directions API, Places API | ⏳ Not set up |
| Google Gemini | API key for AI scoring | ⏳ Not set up |
| Twilio | Account SID + Auth Token + Phone Number | ⏳ Not set up |
| GitHub | Repo created ✅ | ✅ Done |

---

## 💬 Chat Session Reference

| Chat Purpose | Description | Key Files |
|-------------|-------------|-----------|
| **Planning** (this chat) | Architecture, design decisions, all 68+ MD planning docs | All `Phase_*/` files |
| **Execution** | Building the Flutter app, writing production code, database setup | `resq_route_app/` (to be created) |
| **Debug & Error Solving** | Fixing bugs, resolving build errors, troubleshooting | This file's Debug Log section |

### How To Use This File In New Chats

**For Execution Chat:**
```
Here is my project memory file for ResQ Route:
[paste PROJECT_MEMORY.md contents]

Start executing Phase [X]. The detailed implementation plan is in:
Phase_[XX]_[Name]/PHASE_[XX]_OVERVIEW.md and its sub-files.
```

**For Debug Chat:**
```
Here is my project memory file for ResQ Route:
[paste PROJECT_MEMORY.md contents]

I'm getting this error: [paste error]
This happened while implementing Phase [X], file [Y].
```

---

> **⚠️ INSTRUCTIONS FOR AI**: When you finish work in any chat session, UPDATE this file:
> 1. Update the phase status in the roadmap table (⏳ → 🔄 → ✅)
> 2. Fill in the Execution Log section for the phase you worked on
> 3. Add any bugs to the Debug & Error Log
> 4. Update "Last Updated" timestamp at the top
> 5. Commit and push: `git add PROJECT_MEMORY.md; git commit -m "update memory"; git push`
