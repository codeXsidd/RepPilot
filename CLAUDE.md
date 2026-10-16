# RepPilot - CLAUDE.md

## Product Overview

RepPilot is a polished, completely free, offline-first Android fitness application.
No account, backend, subscription, advertisements, paid APIs, or mandatory internet connection.

## Product Requirements

1. **Workout Management**: Custom weekly gym workout classes and schedules
2. **Exercise Tracking**: Custom exercises, sets, reps, weights, and rest timers
3. **Live Workout Recording**: Set-by-set workout recording with recovery after app closure
4. **Progressive Overload**: Explainable rule-based progressive overload suggestions
5. **Body Weight Tracking**: Daily body-weight tracking and weight-history charts
6. **Diet & Nutrition**: Diet logging, calories, protein, meal planning, and water intake
7. **Motivation**: Daily motivational messages, consistency streaks, and weekly reports
8. **Theming**: Dark, light, and system themes
9. **Data Management**: Local data storage, backup, restore, and export
10. **Accessibility & Privacy**: Good accessibility, responsive layouts, and privacy

## Architecture

### State Management
- **Provider** for app-wide state (theme, settings)
- **Riverpod** or plain ChangeNotifier for feature-level state
- Decision: Use **Provider + ChangeNotifier** to minimize dependencies

### Local Storage
- **sqflite** for structured relational data (workouts, exercises, logs, weight, diet)
- **shared_preferences** for lightweight settings (theme, onboarding flags)

### Project Structure
```
lib/
  main.dart                  # App entry point
  app.dart                   # MaterialApp configuration
  core/
    database/                # Database helper, migrations, schema
    theme/                   # ThemeData for dark/light/system
    constants.dart           # App-wide constants
    utils.dart               # Shared utilities
  models/                    # Data classes (Exercise, Workout, WeightEntry, etc.)
  screens/
    home/                    # Dashboard / home screen
    workouts/                # Workout templates, schedule, live session
    exercises/               # Exercise library, custom exercises
    progress/                # Progressive overload, charts
    weight/                  # Body weight tracking, history charts
    diet/                    # Diet logging, meal plans, water intake
    settings/                # Theme, backup/restore, export
  widgets/                   # Shared reusable widgets
  services/
    backup_service.dart      # JSON export/import, file picker
    overload_service.dart    # Progressive overload rule engine
    motivation_service.dart  # Daily messages, streaks
```

### Database Schema (sqflite)
- **exercises**: id, name, category, notes, isCustom
- **workout_templates**: id, name, dayOfWeek, order
- **template_exercises**: id, templateId, exerciseId, targetSets, targetReps, targetWeight, restSeconds, order
- **workout_sessions**: id, templateId, startedAt, completedAt, notes
- **session_sets**: id, sessionId, exerciseId, setNumber, reps, weight, completed, timestamp
- **weight_entries**: id, date, weight, notes
- **diet_entries**: id, date, mealType, description, calories, proteinGrams
- **water_entries**: id, date, millilitres
- **settings**: key, value (for theme, units, etc.)

## Coding Standards

- Dart 3.13+ with null safety enforced
- Format with `dart format` before every commit
- Run `flutter analyze` — zero warnings allowed
- Run `flutter test` after every change — all tests must pass
- Prefer `const` constructors everywhere possible
- Use named parameters for widget constructors
- Keep widgets small — extract into separate files at ~100 lines
- Models are immutable data classes with `copyWith`, `toMap`, `fromMap`
- No `print()` in production code — use `debugPrint()` only in debug builds
- All user-facing strings in one place for future i18n readiness

## Data Safety Rules

- **Never delete user data** without explicit user confirmation
- **Database migrations** must be forward-only and additive — never drop columns
- **Backup before destructive operations** (schema upgrades create automatic JSON backup)
- **No network calls** — the app must work 100% offline
- **No analytics, tracking, or telemetry** of any kind
- **Export format** is human-readable JSON so users own their data
- Shared preferences store only non-critical settings; all important data is in sqflite

## Build & Test Commands

```bash
flutter pub get              # Resolve dependencies
dart format .                # Format all Dart files
flutter analyze              # Static analysis (must be zero issues)
flutter test                 # Run all tests (must all pass)
flutter build apk --release  # Build release APK
```

## Dependencies Policy

- Minimize third-party packages — prefer Flutter SDK built-ins
- No packages requiring internet, accounts, or API keys
- Verify pub.dev compatibility and maintenance status before adding
- Pin major versions in pubspec.yaml

## Key Decisions Log

| Decision | Rationale |
|---|---|
| sqflite over Hive/Isar | Mature, relational, zero-setup, good migration support |
| Provider over Riverpod/Bloc | Simpler, fewer deps, adequate for this app's complexity |
| fl_chart for charts | Free, offline, well-maintained, good weight/progress charts |
| No Firebase | Requirement: no backend, no accounts, no internet dependency |
| JSON backup format | Human-readable, portable, no vendor lock-in |
