# Changelog

## v1.3.0 (2026-10-17)

### Premium UI/UX Redesign
- **Centralized design tokens**: New `AppColors` and `AppSpacing` classes providing consistent color palette (blue accent), spacing, and border radii across all screens
- **Material 3 refinement**: Cohesive dark and light themes built on `ColorScheme` with blue primary accent (`#448AFF`), tinted surfaces, and subtle card borders
- **Rounded icons**: All icons updated to `_rounded` variants for a softer, modern look across 37+ screens
- **Tabular figures**: Numeric values use `FontFeature.tabularFigures()` for proper alignment in timers, stats, and weight displays
- **Home dashboard redesign**: Floating SliverAppBar with gradient icon, today's workout card with status-colored tint, stats row, daily overview, and motivational quote card
- **Live workout screen**: Redesigned timer display, bolder exercise names, rounded input fields, completed-set highlighting with primary color tint, and improved bottom bar
- **Workout screens**: Day cards with primary tint for current day, unified badge styling, progress bars with tabular figures
- **Exercise screens**: Difficulty indicators with color-coded dots, category chips, improved filter sheet, alpha-based chip coloring on detail screen
- **Progress dashboard**: Weight stats with headline typography, mini stat cards, tinted icon containers, trophy icons for personal records
- **Nutrition dashboard**: Uppercase section headers, macro chips with branded colors, blue-tinted water intake buttons
- **Settings**: Gradient blue app icon, redesigned theme and training level selectors with blue check indicators
- **Onboarding**: Circular tinted containers behind page icons
- **Empty states**: Circular tinted container behind icons for visual consistency
- **Section headers**: Uppercase with letter spacing and consistent typography throughout
- **Navigation bar**: Top border accent, rounded tab icons, blue pill indicator for selected tab

### Verified
- 673 unit tests passing
- 8 on-device integration tests passing (emulator API 37)
- Dark and light themes verified on Android emulator
- Zero `flutter analyze` issues
- Production signing intact

## v1.2.0 (2026-10-16)

### Exercise Library Expansion
- **255 built-in exercises** across 12 categories (up from 152 across 10)
- New categories: forearms, mobility/warm-up
- New exercise groups: kettlebell (10), medicine ball (6), resistance band (8), additional bodyweight (10), cable (8), machine (8), barbell compound (10), dumbbell (8), core (12)
- Muscle group explorer screen with SVG anatomy illustrations for each muscle group
- Per-exercise weight history and progression charts (max weight, volume, reps over time)
- Exercise detail screen now links to history/progression view

### Visual Exercise Learning
- 13 muscle group SVG illustrations (chest, back, shoulders, biceps, triceps, forearms, legs, hamstrings, glutes, calves, core, full body, mobility)
- 8 equipment SVG illustrations (barbell, dumbbell, cable, bodyweight, machine, kettlebell, resistance band, EZ bar)
- Muscle group explorer: tap a muscle group to see anatomy illustration and browse its exercises

### Food & Nutrition Expansion
- **109 built-in foods** (up from 29) covering Indian and international cuisine
- New Indian foods: moong/toor/masoor/urad dal, biryani, curries, street food (bhel puri, pani puri, kachori), sweets (gulab jamun, rasgulla, jalebi, kheer), South Indian (uttapam, medu vada, pesarattu)
- International foods: salmon, tuna, quinoa, Greek yogurt, oatmeal, avocado, pasta, dark chocolate, olive oil
- New categories: main, dairy, fruit, sweet

### Training Experience Levels
- Beginner, intermediate, and advanced training modes in Settings
- Each level provides tailored defaults for sets, rep ranges, and weight increments
- Persisted via shared_preferences

### Workout Calendar
- Monthly calendar view showing training days with dot markers
- Tap any day to see completed sessions with duration and set counts
- Month navigation with workout count summary
- Links to full session summary

### Daily Workout Experience
- My Weekly Workouts screen: Mon–Sun cards with status badges (rest, planned, in-progress, completed)
- Week navigation (previous / next / current) with weekly progress bar
- Workout day detail screen: exercise preview with muscle SVG illustrations, instructions, safety notes
- Start / Resume / View Summary workflow depending on session status
- Mark Incomplete with confirmation dialog (clears completion, preserves logged sets)
- Today's Workout card on home dashboard showing current-day status
- Database-level duplicate prevention: partial unique index on (routine_id, planned_date)
- Transactional create-or-resume (`getOrCreateForRoutine`) and idempotent completion (`completeIfActive`)
- Schema v8 migration: `planned_date` column on workout_sessions

### Progress Enhancements
- Calendar button on Progress screen for quick access to workout calendar
- Exercise history accessible from exercise detail screen

### Technical
- Database schema v8 with 8 forward-only migrations
- 673 automated tests (unit, widget, repository, service, integration)
- 8 on-device integration tests (emulator-verified)
- Fixed duplicate Hero tag crash when switching between Workout and Diet tabs

## v1.1.0 (2026-10-16)

### Exercise Library Expansion
- **152 built-in exercises** across 10 categories (up from 58 across 6)
- New categories: biceps, triceps, glutes, calves, full_body (split from arms/legs)
- Full metadata per exercise: difficulty, instructions, safety notes, secondary muscles, movement pattern, default programming, aliases, substitutions, home/gym suitability
- Exercise detail screen with instructions, safety notes, target muscles, and default programming
- Filter by difficulty (beginner/intermediate/advanced), equipment, home suitability
- Favorites system with star toggle on detail screen
- Recently used exercises tracked when completing workouts
- Exercise picker now has quick-access Recent and Favorites tabs
- Search now matches aliases and secondary muscles
- Database schema v7 with 20 new columns and 4 new indexes
- Idempotent catalog seeding: updates metadata on re-seed, preserves user favorites and last-used timestamps
- 40 new tests for catalog validation, model serialization, repository methods, and seeding

### Technical
- Database migration v6 to v7 (forward-only, additive)
- Exercise model expanded from 10 to 30 fields
- ExerciseRepository: 10 new query methods (getFiltered, getFavorites, getRecentlyUsed, toggleFavorite, etc.)
- 642 total automated tests (all passing)

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
