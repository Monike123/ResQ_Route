# 03 — Project Folder Structure

## Objective
Establish a clean, scalable folder structure for the Flutter app following the feature-first architecture pattern.

---

## Flutter Project Structure

```
resq_route/
├── lib/
│   ├── main.dart                           # App entry point
│   │
│   ├── core/                               # Shared infrastructure
│   │   ├── supabase_client.dart            # Supabase initialization & client access
│   │   ├── constants/
│   │   │   ├── app_constants.dart          # App-wide constants
│   │   │   ├── api_endpoints.dart          # API URLs & keys
│   │   │   └── safety_constants.dart       # Deadman thresholds, score weights
│   │   ├── theme/
│   │   │   ├── app_theme.dart              # Light & dark themes
│   │   │   ├── app_colors.dart             # Color palette
│   │   │   └── app_typography.dart         # Text styles
│   │   ├── utils/
│   │   │   ├── validators.dart             # Input validation helpers
│   │   │   ├── formatters.dart             # Date, phone, distance formatters
│   │   │   ├── geo_utils.dart              # Geospatial calculation helpers
│   │   │   └── logger.dart                 # Structured logging utility
│   │   ├── errors/
│   │   │   ├── app_exceptions.dart         # Custom exception classes
│   │   │   └── error_handler.dart          # Global error handler
│   │   └── extensions/
│   │       ├── context_extensions.dart     # BuildContext extensions
│   │       └── string_extensions.dart      # String utility extensions
│   │
│   ├── features/                           # Feature modules (feature-first)
│   │   ├── auth/                           # Phase 2
│   │   │   ├── data/
│   │   │   │   ├── models/                 # Data models (User, Session)
│   │   │   │   ├── repositories/           # Auth repository implementations
│   │   │   │   └── datasources/            # Supabase auth data source
│   │   │   ├── domain/
│   │   │   │   ├── entities/               # Domain entities
│   │   │   │   ├── repositories/           # Repository interfaces
│   │   │   │   └── usecases/               # Auth use cases
│   │   │   └── presentation/
│   │   │       ├── screens/                # Login, Signup, Verification screens
│   │   │       ├── widgets/                # Auth-specific widgets
│   │   │       └── providers/              # State management (Riverpod/Bloc)
│   │   │
│   │   ├── routes/                         # Phase 3
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── safety/                         # Phase 4
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── monitoring/                     # Phase 5
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── emergency/                      # Phase 6
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── reports/                        # Phase 7
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   └── home/                           # Home / Dashboard
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   │
│   ├── navigation/                         # App navigation / routing
│   │   └── app_router.dart                 # Route definitions
│   │
│   └── services/                           # Background services
│       ├── location_service.dart           # GPS tracking service
│       ├── voice_recognition_service.dart  # Voice trigger service
│       ├── notification_service.dart       # Push/local notifications
│       └── websocket_service.dart          # Supabase Realtime wrapper
│
├── assets/
│   ├── images/                             # App images, map markers
│   ├── fonts/                              # Custom fonts
│   ├── icons/                              # Custom SVG icons
│   └── audio/                              # SOS alert sounds
│
├── test/                                   # Unit tests
│   ├── core/
│   ├── features/
│   └── services/
│
├── integration_test/                       # Integration tests
│
├── supabase/                               # Supabase Edge Functions & migrations
│   ├── functions/                          # Edge Functions (Deno/TypeScript)
│   │   ├── calculate-safety-score/
│   │   ├── send-sos-alerts/
│   │   ├── generate-report/
│   │   └── verify-identity/
│   └── migrations/                         # Database migration SQL files
│
├── scripts/                                # Utility scripts (Python .venv)
│   ├── crime_data_ingestion.py
│   └── data_migration.py
│
├── .env.example                            # Template for env vars (committed)
├── .env                                    # Actual env vars (NOT committed)
├── .gitignore
├── pubspec.yaml
├── analysis_options.yaml                   # Dart linter rules
└── README.md
```

---

## Architecture Pattern: Clean Architecture (Feature-First)

Each feature module follows the **Clean Architecture** layered pattern:

```
feature/
├── data/           # HOW — Implementation details
│   ├── models/     # JSON serializable DTOs
│   ├── datasources/# Supabase queries, API calls
│   └── repositories/# Repository implementations
├── domain/         # WHAT — Business rules
│   ├── entities/   # Pure domain objects
│   ├── repositories/# Abstract repository interfaces
│   └── usecases/   # Business logic units
└── presentation/   # UI — Display layer
    ├── screens/    # Full-page widgets
    ├── widgets/    # Reusable UI components
    └── providers/  # State management
```

---

## File Naming Conventions

| Convention | Example |
|-----------|---------|
| Files | `snake_case.dart` |
| Classes | `PascalCase` |
| Variables/Functions | `camelCase` |
| Constants | `camelCase` or `SCREAMING_SNAKE_CASE` for truly global |
| Test files | `<filename>_test.dart` |

---

## Verification
- [ ] All directories created
- [ ] `analysis_options.yaml` configured with pedantic rules
- [ ] `.env.example` contains all required variable names (no values)
- [ ] File structure is consistent and predictable
