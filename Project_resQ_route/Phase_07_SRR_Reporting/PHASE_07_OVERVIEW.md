# Phase 07 — SRR Reporting Engine

## Objective
Build the Safety Route Report (SRR) system — generate PDF reports, map snapshots, integrity-hashed documents, shareable links, and post-journey feedback collection.

## Prerequisites
- Phase 6 complete (SOS events and journey data available)
- Journey points stored in database

## Deliverables
| # | Deliverable | Detailed File |
|---|-------------|---------------|
| 1 | PDF report generation | [01_pdf_report_generation.md](./01_pdf_report_generation.md) |
| 2 | Map snapshot rendering | [02_map_snapshot_rendering.md](./02_map_snapshot_rendering.md) |
| 3 | Integrity hashing | [03_integrity_hashing.md](./03_integrity_hashing.md) |
| 4 | Share link system | [04_share_link_system.md](./04_share_link_system.md) |
| 5 | Post-journey feedback | [05_post_journey_feedback.md](./05_post_journey_feedback.md) |

## Report Contents
```
┌──────────────────────────────────┐
│     SAFETY ROUTE REPORT (SRR)    │
│     ResQ Route                   │
│                                  │
│  User: [Name]  ID: RR-XXXX      │
│  Date: 2024-01-15                │
│  Journey Duration: 45 min        │
│                                  │
│  [Map Snapshot with Route Path]  │
│                                  │
│  Safety Score: 85/100            │
│  Distance: 3.2 km               │
│  Status: Completed               │
│                                  │
│  SOS Events: 0                   │
│  Unsafe Zones Passed: 2          │
│                                  │
│  Integrity Hash: SHA-256         │
│  Generated: 2024-01-15T10:30Z    │
└──────────────────────────────────┘
```

## Database Schema
```sql
CREATE TABLE public.reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    journey_id UUID REFERENCES public.journeys(id),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    report_type TEXT DEFAULT 'srr' CHECK (report_type IN ('srr', 'sos_report')),
    pdf_url TEXT,
    map_snapshot_url TEXT,
    share_link_id VARCHAR(50) UNIQUE,
    share_link_expires_at TIMESTAMPTZ,
    integrity_hash VARCHAR(255),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own reports" ON public.reports FOR SELECT USING (auth.uid() = user_id);
```

## Git Branch
```bash
git checkout -b phase/07-srr-reporting
```

## Verification Criteria
- [ ] PDF generated with journey summary + map
- [ ] Map snapshot captures route and unsafe zones
- [ ] SHA-256 integrity hash attached to report
- [ ] Share link allows view-only access
- [ ] Post-journey feedback collected and stored
