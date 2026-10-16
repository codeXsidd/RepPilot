# Changelog

## v1.0.0 (2026-10-16)

### Features
- **Workout Management**: Custom routines with weekly scheduling, exercise ordering, duplication, and archiving
- **Exercise Library**: 58 built-in exercises across 6 categories plus unlimited custom exercises with equipment and muscle group tags
- **Live Workout Recording**: Set-by-set weight/reps logging with rest timer, RPE tracking, warmup marking, and session recovery after app closure
- **Progressive Overload**: Rule-based suggestions with configurable rep ranges, weight increments, and clear per-recommendation explanations
- **Body Weight Tracking**: Daily weigh-ins with 7-day moving average, trend charts (fl_chart), and date-range filtering
- **Body Measurements**: Track waist, chest, arms, and hips with history
- **Diet & Nutrition**: Meal logging with calories, protein, carbs, fat; 90+ built-in foods; food search; meal templates; water intake tracking with daily goals
- **Motivation**: 50+ daily motivational messages, consistency streaks, milestone tracking
- **Weekly Reports**: Database-driven weekly summaries covering workouts, volume, weight trends, nutrition averages, and hydration
- **Reminders**: Configurable workout, weight, and hydration reminder preferences (notification delivery requires platform notification plugin)
- **Themes**: Dark, light, and system themes with persistence
- **Units**: Configurable weight display (kg/lb) stored in user profile
- **Data Management**: Full JSON backup/restore with validation and preview, per-table CSV export, factory reset with double confirmation
- **Privacy**: Zero network calls, zero analytics, zero telemetry, all data stored locally in SQLite
- **Onboarding**: 4-page welcome flow for first-time users

### Technical
- Flutter 3.47.5 / Dart 3.13
- SQLite database with 16 tables, schema v6, 6 forward-only migrations
- 14 immutable data models with sentinel-pattern copyWith
- 16 database repositories with full CRUD
- 10 services (overload engine, backup, motivation, streaks, reports, analytics, nutrition, reminders, active workout, rest timer)
- 602 automated tests (unit, repository, service, integration)
- Provider + ChangeNotifier state management
- Material 3 theming with green accent
- Android adaptive icon (dark charcoal + green dumbbell motif)

### Build
- Release APK: 54.2 MB
- Release AAB: 52.4 MB
- Android application ID: `com.reppilot.rep_pilot`
- Minimum SDK: Flutter default (~21)
- Target SDK: Flutter default (~37)
- Compile SDK: 36
