# 🔀 Git Strategy & Backup Plan — ResQ Route

## Repository Setup

### Initial Git Repository
```bash
cd ResQ_Route_App   # (Flutter project root, created in Phase 1)
git init
git remote add origin <your-github-repo-url>
```

### Branch Structure

```
main ─────────────────────────────────────── (production-stable releases only)
  │
  └── develop ─────────────────────────────── (integration branch)
        │
        ├── phase/01-foundation ────────────── Phase 1 feature branch
        ├── phase/02-authentication ────────── Phase 2 feature branch
        ├── phase/03-route-engine ──────────── Phase 3 feature branch
        ├── phase/04-safety-scoring ────────── Phase 4 feature branch
        ├── phase/05-live-monitoring ───────── Phase 5 feature branch
        ├── phase/06-emergency-response ────── Phase 6 feature branch
        ├── phase/07-reporting ─────────────── Phase 7 feature branch
        ├── phase/08-admin-dashboard ───────── Phase 8 feature branch
        ├── phase/09-security ──────────────── Phase 9 feature branch
        └── phase/10-testing-deployment ────── Phase 10 feature branch
```

---

## Workflow Per Phase

### 1. Starting a Phase
```bash
git checkout develop
git pull origin develop
git checkout -b phase/XX-phase-name
```

### 2. During Development (Atomic Commits)
Use conventional commit messages following GSD pattern:
```bash
# Feature work
git commit -m "feat(phase-XX): implement [feature description]"

# Bug fixes
git commit -m "fix(phase-XX): resolve [issue description]"

# Tests
git commit -m "test(phase-XX): add tests for [feature]"

# Documentation
git commit -m "docs(phase-XX): update [document name]"

# Refactoring
git commit -m "refactor(phase-XX): clean up [area]"
```

**Commit Frequency**: At least once per completed task within a plan. Never go more than 2 hours without a commit during active development.

### 3. Completing a Phase

```bash
# Ensure all changes are committed
git status

# Push the phase branch
git push origin phase/XX-phase-name

# Create a Pull Request to develop
# Review & merge via GitHub PR

# After merge, tag the release
git checkout develop
git pull origin develop
git tag -a vX.X.0 -m "Phase XX: [Phase Name] complete"
git push origin --tags

# Create backup
# (see Backup Strategy below)
```

---

## Release Tags

| Phase | Tag | Description |
|-------|-----|-------------|
| Phase 1 | `v0.1.0` | Foundation & Project Setup |
| Phase 2 | `v0.2.0` | Identity & Authentication |
| Phase 3 | `v0.3.0` | Route Intelligence Engine |
| Phase 4 | `v0.4.0` | Safety Scoring & AI Integration |
| Phase 5 | `v0.5.0` | Live Monitoring Engine |
| Phase 6 | `v0.6.0` | Emergency Response System |
| Phase 7 | `v0.7.0` | SRR Reporting Engine |
| Phase 8 | `v0.8.0` | Admin Dashboard |
| Phase 9 | `v0.9.0` | Security Hardening |
| Phase 10 | `v1.0.0` | Production Release |

---

## Backup Strategy

### Per-Phase Backup
After each phase completion:

1. **Git Tag** — as shown above
2. **ZIP Archive** — full project state excluding `node_modules`, `.dart_tool`, `build/`
   ```bash
   # PowerShell
   Compress-Archive -Path .\* -DestinationPath "..\backups\ResQ_Route_v0.X.0.zip" -Force
   ```
3. **GitHub Release** — attach the ZIP to the tagged release on GitHub

### .gitignore (Essential)
```gitignore
# Flutter
.dart_tool/
.packages
build/
*.iml
.idea/
.vscode/

# Environment
.env
.env.*
*.env

# Supabase local
supabase/.temp/

# Python
.venv/
__pycache__/
*.pyc

# OS
.DS_Store
Thumbs.db

# Keys & Secrets
*.pem
*.key
*.p12
service-account.json
google-services.json
GoogleService-Info.plist

# Build artifacts
*.apk
*.aab
*.ipa
```

---

## Emergency Recovery

If something goes wrong during a phase:
```bash
# Reset to last stable state
git checkout develop
git reset --hard vX.X.0   # Last completed phase tag

# Or recover from backup ZIP
```

---

## Collaboration Rules (Cross-Chat)

- **Chat 1 (Planning)**: Only modifies `Project_resQ_route/` plan files
- **Chat 2 (Implementation)**: Only modifies actual code in the Flutter project
- **Chat 3 (Debugging)**: Only patches code, never restructures

Each chat should commit with a clear prefix:
- Planning: `docs(plan): ...`
- Implementation: `feat(phase-XX): ...`
- Debugging: `fix(phase-XX): ...`
