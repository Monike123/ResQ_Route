# 05 — CI/CD Scaffold

## Objective
Set up basic GitHub Actions for continuous integration — automated linting, testing, and build verification on each push/PR.

---

## GitHub Actions Workflow

### File: `.github/workflows/ci.yml`

```yaml
name: ResQ Route CI

on:
  push:
    branches: [main, develop, 'phase/**']
  pull_request:
    branches: [main, develop]

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Analyze code
        run: flutter analyze --no-fatal-infos
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Check formatting
        run: dart format --set-exit-if-changed .

  build-android:
    runs-on: ubuntu-latest
    needs: analyze-and-test
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'
      
      - uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build APK (debug)
        run: flutter build apk --debug
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}

  build-ios:
    runs-on: macos-latest
    needs: analyze-and-test
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build iOS (no-codesign)
        run: flutter build ios --no-codesign --debug
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
```

### Required GitHub Secrets
In GitHub repo → Settings → Secrets → Actions:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

---

## Pre-Commit Hooks (Optional but Recommended)

Install `lefthook` or use a Dart-based pre-commit:

```yaml
# lefthook.yml
pre-commit:
  commands:
    format:
      run: dart format .
    analyze:
      run: flutter analyze --no-fatal-infos
    test:
      run: flutter test
```

---

## Verification
- [ ] GitHub Actions workflow file exists at `.github/workflows/ci.yml`
- [ ] Pushing to any branch triggers analyze + test
- [ ] PR to `develop` or `main` triggers full build
- [ ] GitHub secrets are configured
