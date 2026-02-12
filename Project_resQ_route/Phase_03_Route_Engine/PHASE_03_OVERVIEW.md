# Phase 03 — Route Intelligence Engine

## Objective
Implement the complete route planning system — destination input, Google Maps integration, route fetching, unsafe zone overlay, and route caching.

## Prerequisites
- Phase 2 completed (Auth working, users can log in)
- Google Maps API key configured

## Deliverables
| # | Deliverable | Detailed File |
|---|-------------|---------------|
| 1 | Destination input system | [01_destination_input_system.md](./01_destination_input_system.md) |
| 2 | Google Maps integration | [02_google_maps_integration.md](./02_google_maps_integration.md) |
| 3 | Route fetching algorithm | [03_route_fetching_algorithm.md](./03_route_fetching_algorithm.md) |
| 4 | Unsafe zone display | [04_unsafe_zone_display.md](./04_unsafe_zone_display.md) |
| 5 | Database schema for routes | [05_database_schema_routes.md](./05_database_schema_routes.md) |
| 6 | Route caching strategy | [06_route_caching.md](./06_route_caching.md) |

## Security Checkpoints (Phase 3)
- [ ] Google Maps API key restricted by app package name
- [ ] Input coordinates validated (lat/lng bounds)
- [ ] Route requests authenticated (JWT required)
- [ ] RLS on `routes` table

## Key Screens
1. **Home Screen** — Map view with current location + unsafe zone markers
2. **Search/Destination Input** — Autocomplete search bar
3. **Route Selection** — 3 route cards with safety scores (initially pending)

## Git Branch
```bash
git checkout -b phase/03-route-engine
```

## Verification Criteria
- [ ] User can search and select a destination
- [ ] Google Maps displays on home screen
- [ ] 3 routes fetched between origin and destination
- [ ] Unsafe zones displayed as red markers on map
- [ ] Routes stored in database with waypoints
