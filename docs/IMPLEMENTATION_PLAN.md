# RepPilot Implementation Plan

## Current Status: Full Audit and Release Preparation Complete

**Repository state**: Complete feature set with 16 tables (schema v6), 14 models, 16 repositories, 10 services, 29 screens, 602 passing tests. Full audit performed: 7 defects found and fixed (units settings, onboarding, error handling, form validation, app icon). Custom adaptive icon, onboarding flow, and unit switching implemented.
**Diagnostics**: All passing — `flutter analyze` 0 issues, `flutter test` 602/602 pass, `dart format` clean, `flutter build apk --release` succeeds (54.2MB), `flutter build appbundle --release` succeeds (52.4MB). App installed and verified on Android 17 emulator.

---

## Phase 1: Foundation & Core Architecture
**Goal**: Establish the app skeleton, database, theming, and navigation.
**Status**: Complete (persistence layer)

### Tasks
- [x] Set up project structure (`lib/core/`, `lib/models/`, `lib/screens/`, `lib/services/`, `lib/widgets/`)
- [x] Add dependencies: `sqflite`, `path`, `provider`, `intl`, `path_provider`, `uuid`
- [x] Create database helper with versioned migrations and foreign keys
- [x] Define all data models with `toMap`/`fromMap`/`copyWith`
- [x] Write unit tests for models, database CRUD, constraints and migrations (98 tests)
- [x] Connect home screen to real repositories via Provider
- [ ] Add remaining dependencies: `shared_preferences`, `fl_chart`, `file_picker`
- [ ] Implement dark/light/system theme with `Provider` + persistence
- [ ] Build bottom navigation shell (Home, Workouts, Diet, Progress, Settings)
- [ ] Create placeholder screens for all tabs

### Acceptance Criteria
- ~~App launches with bottom nav and all 5 tabs~~ (pending)
- ~~Theme switching works (dark/light/system) and persists across restarts~~ (pending)
- [x] Database creates all 10 tables on first launch
- [x] All model serialization round-trips pass tests
- [x] `flutter analyze` and `flutter test` pass with zero issues

---

## Phase 2: Workout Templates & Exercise Library
**Goal**: Users can create workout plans with custom exercises.
**Status**: Complete

### Tasks
- [x] Seed a default exercise library (58 exercises across 6 categories)
- [x] Build exercise list screen with search and category filter
- [x] Build "add custom exercise" flow (with equipment and muscle group fields)
- [x] Build workout routine creation/editing screen
- [x] Assign exercises to routines with target sets/reps (min-max range)/weight/rest
- [x] Build weekly schedule view (7-day planner with day assignment)
- [x] Implement routine duplication, archiving, and deletion
- [x] Reorder exercises within routines (drag handle)
- [x] Multi-select exercise picker for adding exercises to routines
- [x] Database migration v1→v2 (equipment column, rep range columns)
- [x] Write tests for routine CRUD, exercise CRUD, scheduling, duplication, validation, and historical-data preservation (56 new tests)

### Schema Changes (v2)
- `exercises`: Added `equipment TEXT NOT NULL DEFAULT ''`
- `routine_exercises`: Added `target_reps_min INTEGER`, `target_reps_max INTEGER`
- New indexes: `idx_exercises_equipment`, `idx_exercises_muscle_group`

### Key Files Added/Modified
- `lib/core/data/default_exercises.dart` — 58 default exercises, category/equipment constants
- `lib/core/database/schema.dart` — v2 migration definitions
- `lib/core/database/database_helper.dart` — Migration runner
- `lib/models/exercise.dart` — Added equipment field
- `lib/models/routine.dart` — Sentinel pattern for nullable copyWith
- `lib/models/routine_exercise.dart` — Rep range fields, repsDisplay getter
- `lib/repositories/exercise_repository.dart` — Search by equipment, muscle group filter, seed defaults
- `lib/repositories/routine_repository.dart` — Schedule/unschedule, weekly schedule, duplicate, archive
- `lib/screens/workout/workout_screen.dart` — Weekly planner + routine list with CRUD
- `lib/screens/workout/routine_form_screen.dart` — Create/edit routine with exercise management
- `lib/screens/exercises/exercise_list_screen.dart` — Searchable exercise library
- `lib/screens/exercises/exercise_form_screen.dart` — Create/edit exercise form
- `lib/screens/exercises/exercise_picker_screen.dart` — Multi-select exercise picker
- `test/phase2_integration_test.dart` — Integration tests for Phase 2
- `test/repositories/routine_exercise_repository_test.dart` — RoutineExercise CRUD tests

### Acceptance Criteria
- [x] User can browse, search, and filter exercises (by category and text)
- [x] User can create custom exercises (with equipment type)
- [x] User can create/edit/duplicate/archive/delete workout routines
- [x] User can assign routines to weekdays via weekly planner
- [x] User can add, remove, and reorder exercises within routines
- [x] All CRUD operations persist in sqflite
- [x] Schedule changes do not affect workout history
- [x] Tests cover create, read, update, delete, scheduling, duplication, and validation paths

---

## Phase 3: Live Workout Session & Recording
**Goal**: Set-by-set workout logging with crash recovery.
**Status**: Complete

### Tasks
- [x] Build live workout session screen with exercise sections and set rows
- [x] Implement set-by-set logging (reps, weight, check-off, RPE, warmup toggle)
- [x] Add rest timer with pause, resume, reset, and progress bar
- [x] Save session state to DB after each set change (crash recovery)
- [x] Detect and offer to resume interrupted sessions on app open (home screen banner)
- [x] Show previous session's numbers for reference during workout
- [x] Build workout history list screen with duration and set counts
- [x] Build session summary screen (duration, volume, exercise breakdown)
- [x] Add standalone "Quick Start" workout (no routine required)
- [x] Add/remove/skip sets, add exercises mid-workout, reorder exercises
- [x] Swipe-to-delete sets, back-press protection with cancel confirmation
- [x] Prevent duplicate session saves and double-finish
- [x] Fix updateSet sentinel bug (Object sentinel pattern for nullable copyWith params)
- [x] Write ActiveWorkoutService unit tests (35 tests)
- [x] Write RestTimerService unit tests (22 tests)
- [x] Write Phase 3 integration tests (11 tests)

### Schema Changes (v3–v6)
- `workout_sets`: Added `is_warmup INTEGER NOT NULL DEFAULT 0`
- `workout_sessions`: Added `ON DELETE SET NULL` for routine foreign key (preserves history after routine deletion)
- `session_sets` renamed to `workout_sets` with updated columns (rpe, notes, completed_at, is_warmup)

### Key Files Added/Modified
- `lib/services/active_workout_service.dart` — Core session state manager with sentinel-based updateSet
- `lib/services/rest_timer_service.dart` — Countdown timer with pause/resume/reset
- `lib/screens/workout/live_workout_screen.dart` — Full live workout UI (set rows, rest timer bar, RPE/warmup controls)
- `lib/screens/workout/session_summary_screen.dart` — Post-workout summary with stats
- `lib/screens/workout/workout_history_screen.dart` — Completed session history list
- `lib/screens/workout/workout_screen.dart` — Added Quick Start standalone workout
- `lib/screens/home/home_screen.dart` — Active session detection and resume banner
- `test/services/active_workout_service_test.dart` — Comprehensive service tests
- `test/services/rest_timer_service_test.dart` — Timer service tests
- `test/phase3_integration_test.dart` — End-to-end lifecycle, recovery, and edge case tests

### Acceptance Criteria
- [x] User starts a workout from a routine or standalone Quick Start and logs each set
- [x] Rest timer counts down with pause/resume/reset controls
- [x] Closing and reopening the app resumes the active session
- [x] Completed sessions appear in workout history with summary
- [x] Previous workout data shown next to current inputs
- [x] RPE input and warmup toggle available per set
- [x] Sets can be added, removed, skipped, and reordered
- [x] Double-finish and accidental data loss prevented
- [x] Tests verify session persistence, recovery, lifecycle, and edge cases (69 new tests)

---

## Phase 4: Progressive Overload Engine
**Goal**: Rule-based suggestions to help users progressively increase difficulty.
**Status**: Complete

### Tasks
- [x] Define deterministic overload rules with configurable thresholds
- [x] Build OverloadService with generateRecommendation and generateForSession methods
- [x] Generate recommendations automatically after finishing a workout
- [x] Display recommendations in session summary with plain-language explanations
- [x] Add user ability to accept, edit, or dismiss suggestions
- [x] Accepted/edited recommendations pre-fill next workout's weights and reps
- [x] Build exercise settings screen (min/max reps, weight increment, bodyweight flag, machine increment)
- [x] Handle high-effort sessions (RPE >= 9.0) by maintaining load
- [x] Handle incomplete sets by recommending consistency before progression
- [x] Handle bodyweight exercises with rep-only progression
- [x] Handle machines with fixed increments (machineIncrementKg overrides default)
- [x] Support kg/lb display via explainRecommendation without corrupting stored kg values
- [x] Record recommendation history in overload_recommendations table
- [x] Write OverloadService unit tests (32 tests: increases, repeats, high effort, incomplete, empty, bodyweight, unit conversion, edge cases)
- [x] Write Phase 4 integration tests (13 tests: full workflow, accept/dismiss/edit, settings, history, bodyweight)

### Overload Rules
1. **All sets >= max reps at current weight**: Increase weight by configured increment, reset reps to min
2. **Average reps below max**: Maintain weight, build reps by +1 toward max
3. **Any set incomplete**: Maintain load, focus on completing all prescribed sets
4. **Average RPE >= 9.0**: Maintain load until effort is manageable
5. **Bodyweight exercise at max reps**: Increase rep target by +1
6. **Empty/warmup-only history**: No recommendation generated
7. **Skipped sets (reps=0)**: Excluded from analysis entirely

### Key Files Added/Modified
- `lib/services/overload_service.dart` — Deterministic progressive overload engine with configurable thresholds
- `lib/services/active_workout_service.dart` — Integrated overload generation into finishWorkout, accepted recommendations into startFromRoutine
- `lib/screens/workout/session_summary_screen.dart` — Recommendation cards with accept/edit/dismiss actions
- `lib/screens/exercises/exercise_settings_screen.dart` — Per-exercise overload configuration UI
- `lib/screens/exercises/exercise_form_screen.dart` — Added overload settings navigation button
- `lib/screens/workout/live_workout_screen.dart` — Passes overload dependencies to finish flow
- `lib/screens/workout/workout_screen.dart` — Passes recRepo for recommendation application
- `lib/repositories/overload_recommendation_repository.dart` — Added full update method for edited recommendations
- `test/services/overload_service_test.dart` — 32 unit tests covering all engine paths
- `test/phase4_integration_test.dart` — 13 integration tests for end-to-end overload workflow

### Acceptance Criteria
- [x] After completing a workout, user sees overload suggestions per exercise
- [x] Each suggestion includes a plain-language explanation of the rule and evidence
- [x] User can accept (auto-fills next session), edit (custom weight/reps), or dismiss
- [x] Dismissed recommendations do not affect the next workout
- [x] Exercise settings (rep range, increment, bodyweight, machine) are configurable per exercise
- [x] High RPE and incomplete sets prevent automatic load increases
- [x] Recommendations are persisted and accumulate over time
- [x] Bodyweight exercises get rep-only suggestions
- [x] Machine exercises use fixed plate increments
- [x] kg/lb conversion in explanations without corrupting stored data
- [x] Engine is independent of UI code with all thresholds configurable
- [x] Tests cover increases, repeats, high effort, incomplete sets, empty history, unit conversion, and edge cases (45 new tests)

---

## Phase 5: Body Weight Tracking & Progress Analytics
**Goal**: Daily weight logging, body measurements, trend visualization, and progress analytics.
**Status**: Complete

### Tasks
- [x] Build weight entry screen with date, weight, notes, and kg/lb support
- [x] Build weight history chart (fl_chart LineChart with date axis)
- [x] Add 7-day moving average overlay on weight chart
- [x] Support selectable date ranges (1W, 1M, 3M, 6M, All)
- [x] Support both kg and lb display with correct conversion (stored as kg)
- [x] Show weight summary card (latest, 7-day avg, change)
- [x] Enhance BodyMeasurementRepository with getLatest and upsertByDate methods
- [x] Build body measurement history screen (list, add/edit/delete)
- [x] Add Measurements tab to ProgressDashboard (4 tabs: Weight, Measurements, Training, Records)
- [x] Display latest measurements card and recent entries in dashboard
- [x] Handle empty states for weight, measurements, training, and records tabs
- [x] Weight chart handles zero data points (SizedBox.shrink), one data point (±1 Y padding)
- [x] Never invent data for charts — show empty state message when no data
- [x] Write BodyMeasurementRepository tests (22 tests: CRUD, getByDate, getByDateRange, getLatest, upsertByDate, nullable fields)
- [x] Write WeightAnalyticsService tests (33 tests: moving average, weight change, 7-day avg, chart data, consistency, volume, PRs)
- [x] Write Phase 5 integration tests (22 tests: weight lifecycle, measurement lifecycle, analytics integration, date filtering, empty states, unit conversion)

### Key Files Added/Modified
- `lib/repositories/body_measurement_repository.dart` — Added getLatest and upsertByDate methods
- `lib/screens/weight/body_measurement_screen.dart` — New measurement history screen with CRUD
- `lib/screens/progress/progress_dashboard.dart` — Added Measurements tab (4 tabs total), loads measurements data
- `lib/screens/weight/weight_screen.dart` — Weight entry screen with chart, date range selector, summary card
- `lib/screens/weight/weight_chart.dart` — fl_chart LineChart with raw data and moving average overlay
- `lib/screens/weight/body_measurement_form.dart` — Body measurement form (waist, chest, arms, hips, notes)
- `lib/screens/weight/weight_entry_form.dart` — Weight entry form with kg/lb support
- `lib/services/weight_analytics_service.dart` — Moving average, 7-day avg, weight change, chart data, consistency, volume, PRs
- `test/repositories/body_measurement_repository_test.dart` — 22 repository tests
- `test/services/weight_analytics_service_test.dart` — 33 analytics service tests
- `test/phase5_integration_test.dart` — 22 integration tests

### Acceptance Criteria
- [x] User can log, edit, and delete daily body weight entries
- [x] User can log, edit, and delete body measurements (waist, chest, arms, hips)
- [x] Chart shows raw data points with 7-day moving average line
- [x] Date range selector filters chart and history (1W, 1M, 3M, 6M, All)
- [x] Unit switching converts display correctly (kg/lb) without corrupting stored kg values
- [x] Weight summary (latest, 7-day avg, change) appears on weight screen and progress dashboard
- [x] Body measurements appear in progress dashboard Measurements tab
- [x] Empty states shown when no data exists (never fake data)
- [x] Weight chart handles zero data points (empty state) and one data point (padded Y axis)
- [x] upsertByDate prevents duplicate entries per date
- [x] Workout consistency, total volume, and personal records shown in progress dashboard
- [x] Tests cover CRUD, unit conversions, date filtering, averages, empty states, and edge cases (77 new tests)

---

## Phase 6: Diet, Calories & Water
**Goal**: Meal logging, calorie/protein tracking, food database, meal templates, and water intake.
**Status**: Complete

### Tasks
- [x] Build Food model with portion calculation helpers (caloriesFor, proteinFor, carbsFor, fatFor)
- [x] Build FoodEntry, WaterEntry, MealTemplate, MealTemplateItem, PersonalGoal models
- [x] Build 6 repositories (food, food_entry, water_entry, meal_template, meal_template_item, personal_goal)
- [x] Create NutritionService with business logic (portion calculations, daily totals, weekly averages, meal grouping, template application, goal progress)
- [x] Seed 29 default Indian foods (idli, dosa, rice, dal, chapati, paneer, eggs, curd, etc.) with isEstimate: true
- [x] Build nutrition dashboard with date navigation, calorie/protein progress bars, 4 meal sections
- [x] Build food log form with search and quick-add modes, serving multiplier, validation
- [x] Build food search screen with category filter chips and favorites filter
- [x] Build food form screen for creating/editing custom foods
- [x] Build meal template screen (create, use, delete templates with food picker)
- [x] Build weekly nutrition summary screen (7-day averages)
- [x] Add water intake tracking with quick-add chips and daily goal
- [x] Add user-editable calorie, protein, and water goals
- [x] Wire all diet repositories as Providers in app.dart
- [x] Seed default foods at startup via foodRepo.seedDefaults(buildDefaultFoods())
- [x] Reject negative/zero servings in NutritionService
- [x] Label starter nutrition values as estimates (notes field)
- [x] Write FoodRepository tests (24 tests: CRUD, search, categories, favorites, seeding, portion calculations)
- [x] Write MealTemplateRepository + MealTemplateItemRepository tests (14 tests: CRUD, items, servings, cascade)
- [x] Write NutritionService tests (30 tests: portion calculations, daily totals, weekly averages, meal grouping, template calories/protein, goal progress, validation)
- [x] Write Phase 6 integration tests (28 tests: food logging lifecycle, template workflow, water tracking, goals, date boundaries, default food seeding, empty states, validation)

### Schema (v6 tables for diet)
- **foods**: id, name, category, servingSize, servingUnit, caloriesPerServing, proteinPerServing, carbsPerServing, fatPerServing, isCustom, isEstimate, isFavorite, createdAt, updatedAt
- **food_entries**: id, date, mealType, description, calories, proteinGrams, carbsGrams, fatGrams, notes, createdAt, updatedAt
- **water_entries**: id, date, amountMl, createdAt
- **personal_goals**: id, goalType, targetValue, unit, isActive, createdAt, updatedAt
- **meal_templates**: id, name, mealType, notes, createdAt, updatedAt
- **meal_template_items**: id, templateId, foodId, servings, createdAt (CASCADE on food/template delete)

### Key Files Added/Modified
- `lib/core/data/default_foods.dart` — 29 default Indian foods across 7 categories
- `lib/models/food.dart` — Food model with portion helpers
- `lib/models/food_entry.dart` — FoodEntry model
- `lib/models/water_entry.dart` — WaterEntry model
- `lib/models/meal_template.dart` — MealTemplate model
- `lib/models/meal_template_item.dart` — MealTemplateItem model
- `lib/models/personal_goal.dart` — PersonalGoal model
- `lib/repositories/food_repository.dart` — Full CRUD + search, categories, favorites, seeding
- `lib/repositories/food_entry_repository.dart` — CRUD + getByDate, getDailyTotals (SQL SUM)
- `lib/repositories/water_entry_repository.dart` — CRUD + getDailyTotalMl, deleteByDate
- `lib/repositories/meal_template_repository.dart` — CRUD + getByMealType
- `lib/repositories/meal_template_item_repository.dart` — CRUD + getByTemplateId, deleteAllForTemplate
- `lib/repositories/personal_goal_repository.dart` — CRUD + getActiveByType, deactivate
- `lib/services/nutrition_service.dart` — Business logic: portion calculations, daily totals, weekly averages, meal grouping, template application, goal progress
- `lib/screens/diet/nutrition_dashboard.dart` — Full nutrition dashboard with date nav, progress bars, meal sections, water tracking
- `lib/screens/diet/food_log_form.dart` — Food logging form with search/quick-add modes
- `lib/screens/diet/food_search_screen.dart` — Searchable food catalog with category/favorite filters
- `lib/screens/diet/food_form_screen.dart` — Create/edit food items
- `lib/screens/diet/meal_template_screen.dart` — Template list and creation flow
- `lib/screens/diet/weekly_summary.dart` — 7-day nutrition summary
- `test/repositories/food_repository_test.dart` — 24 tests
- `test/repositories/meal_template_repository_test.dart` — 14 tests
- `test/services/nutrition_service_test.dart` — 30 tests
- `test/phase6_integration_test.dart` — 28 tests

### Acceptance Criteria
- [x] User can set editable calorie, protein, and water goals
- [x] User can log breakfast, lunch, dinner, and snacks with food search or quick add
- [x] User can create, edit, delete, and search foods in the catalog
- [x] Food model stores serving size, calories, protein, carbs, fat per serving
- [x] Portion calculations correctly scale nutrients by serving count
- [x] User can save favorite foods and create reusable meal templates
- [x] 29 default Indian foods seeded (idli, dosa, rice, dal, chapati, paneer, eggs, curd)
- [x] Starter nutrition values clearly labeled as estimates
- [x] Water intake tracked with quick-add chips and configurable daily goal
- [x] Daily and weekly nutrition summaries displayed
- [x] Custom foods work alongside defaults, fully offline
- [x] Negative/zero quantities rejected by NutritionService
- [x] No duplicate entries on template re-application (each application creates new entries)
- [x] All data persisted in SQLite with proper date boundary filtering
- [x] No remote food API, paid AI, or login required
- [x] Nutrition estimates not presented as medical advice
- [x] Dashboard connected to actual saved data via repositories
- [x] Tests cover portion calculations, daily totals, food CRUD, meal templates, hydration, date boundaries, validation (96 new tests)

---

## Phase 7: Motivation, Streaks & Reports
**Goal**: Keep users engaged with streaks, messages, weekly reports, and optional reminders.
**Status**: Complete

### Tasks
- [x] Create pool of 120+ motivational messages (embedded, no internet, no AI)
- [x] Build MotivationService with stable date-based message selection (same message all day, cycles through pool)
- [x] Build StreakService with current streak, longest streak, active week streak, total workout count
- [x] Streak computed from actual completed WorkoutSession data (completedAt dates)
- [x] Handle missed workouts supportively — never shame or encourage overtraining
- [x] Build milestone detection (streak: 7/14/30/60/90/100/150/200/365 days; total: 10/25/50/100/200/500/1000 workouts)
- [x] Build WeeklyReport model with nullable fields for all data sections
- [x] Build WeeklyReportService — aggregates workouts, volume, PRs, weight trend, nutrition averages, water averages from real saved data
- [x] Weekly report only shows sections where actual data exists (no fabricated statistics)
- [x] Build WeeklyReportScreen with date navigation (previous/next week)
- [x] Build ReminderService with abstract NotificationScheduler backend
- [x] Build NoOpNotificationScheduler for graceful degradation when notifications unavailable
- [x] Build ReminderPreferences model (workout/weight/water reminders with times and intervals)
- [x] Store reminder preferences in shared_preferences
- [x] App continues working normally when notification permission is denied
- [x] Build ReminderSettingsScreen with toggle switches, time pickers, interval dropdown
- [x] Update HomeScreen — streak card, total workouts, weekly report link, MotivationService integration
- [x] Remove hardcoded motivational messages from HomeScreen (now uses MotivationService)
- [x] Add Reminders section to SettingsScreen
- [x] Wire MotivationService, StreakService, WeeklyReportService, ReminderService as Providers
- [x] Write MotivationService tests (13 tests: stability, date handling, pool coverage, uniqueness, boundaries)
- [x] Write StreakService tests (26 tests: current/longest/week streaks, totals, milestones, messages, date edge cases)
- [x] Write WeeklyReportService tests (14 tests: empty state, workout counts, volume, weight, nutrition, water, date boundaries, streak)
- [x] Write ReminderService tests (15 tests: preferences, scheduling, disabled notifications, NoOp behavior)
- [x] Write Phase 7 integration tests (20 tests: motivation+streak lifecycle, weekly report from real data, reminder round-trip, date edge cases, no fabricated statistics)

### Key Files Added/Modified
- `lib/core/data/motivational_messages.dart` — 120+ motivational messages across categories (consistency, strength, mindset, recovery, nutrition, self-compassion)
- `lib/models/weekly_report.dart` — WeeklyReport and PersonalRecordEntry data classes with hasData flags
- `lib/services/motivation_service.dart` — Date-based stable message selection from pool
- `lib/services/streak_service.dart` — Current/longest/week streak calculation, milestones, supportive messaging
- `lib/services/weekly_report_service.dart` — Aggregates data from all repositories into WeeklyReport
- `lib/services/reminder_service.dart` — ReminderPreferences, NotificationScheduler interface, NoOpNotificationScheduler, ReminderService
- `lib/screens/home/weekly_report_screen.dart` — Weekly fitness report with date navigation and data-conditional sections
- `lib/screens/home/home_screen.dart` — Added streak card, total workouts, weekly report button, MotivationService
- `lib/screens/settings/reminder_settings_screen.dart` — Reminder configuration UI with toggles, time pickers, interval selection
- `lib/screens/settings/settings_screen.dart` — Added Notifications/Reminders section
- `lib/app.dart` — Wired MotivationService, StreakService, WeeklyReportService, ReminderService as Providers
- `lib/main.dart` — Initializes ReminderService with SharedPreferences and NoOpNotificationScheduler
- `test/services/motivation_service_test.dart` — 13 tests
- `test/services/streak_service_test.dart` — 26 tests
- `test/services/weekly_report_service_test.dart` — 14 tests
- `test/services/reminder_service_test.dart` — 15 tests
- `test/phase7_integration_test.dart` — 20 tests

### Acceptance Criteria
- [x] Home screen shows current streak and daily motivational message from 120+ pool
- [x] Motivational message is stable within a day and cycles through the full pool
- [x] Streak calculated from actual completed workout sessions (not fabricated)
- [x] Current streak counts consecutive days with completed workouts
- [x] Streak gracefully handles yesterday-only (counts yesterday if no workout today)
- [x] Missed workouts produce supportive messages, never shaming
- [x] Milestone thresholds detected for streaks and total workout counts
- [x] Weekly report compiles accurate cross-module summary (workouts, volume, PRs, weight, nutrition, water)
- [x] Weekly report only shows sections with actual saved data
- [x] Personal records detected by comparing this week's lifts to all-time history
- [x] Calendar boundaries respected (week = Monday–Sunday, local dates stripped of time)
- [x] Optional reminders for workouts, weight tracking, and hydration with user-editable times
- [x] App works normally when notification permission is denied (NoOpNotificationScheduler)
- [x] Reminder preferences persist across app restarts via shared_preferences
- [x] No internet, AI, accounts, or paid services required
- [x] Tests cover streak rules, motivation stability, date handling, weekly totals, and disabled notifications (88 new tests)

---

## Phase 8: Data Ownership, Backup, Restore & Privacy
**Goal**: Full data portability with documented JSON/CSV exports, validated restore, and transparent privacy.
**Status**: Complete

### Tasks
- [x] Build BackupService with full JSON export of all 16 tables
- [x] JSON backup format: `{"format":"reppilot_backup","version":1,"schemaVersion":6,"exportedAt":"...","appVersion":"1.0.0","tables":{...}}`
- [x] Export data in FK-safe insert order (parents before children)
- [x] Provide CSV export for body_weight_entries, food_entries, workout_sessions
- [x] CSV export handles commas, quotes, and newlines in data with proper escaping
- [x] Validate backup format, version, schemaVersion, table structure, row validity
- [x] Reject future backup versions and future schema versions
- [x] Warn (not reject) about older schema versions and rows missing IDs
- [x] Provide restore preview with record counts per table before user confirms
- [x] Restore uses `PRAGMA foreign_keys = OFF` + transaction (delete all → insert all) + re-enable
- [x] Restore filters unknown columns via `PRAGMA table_info` per table (forward-compatible with schema changes)
- [x] Sanitize imported values: convert bools to ints, skip non-primitive types
- [x] ConflictAlgorithm.replace handles duplicate IDs during restore
- [x] Transaction rollback preserves original data if restore fails partway
- [x] Foreign key integrity check after restore with warnings for violations
- [x] Full data reset with double confirmation dialog and default exercise/food re-seeding
- [x] Workout history preserved when routines are edited/deleted (ON DELETE SET NULL on routine_id, routine_name column retained)
- [x] Add auto-backup of database file before schema migrations in DatabaseHelper.onUpgrade
- [x] Expose DatabaseHelper.databasePath for future use
- [x] Add file_picker dependency (^8.1.6) for file import/export via SAF (no storage permissions needed)
- [x] Build BackupRestoreScreen with export (JSON + 3 CSV), import, reset, and privacy info sections
- [x] Wire BackupService as Provider in app.dart
- [x] Enable Backup & Restore link in SettingsScreen (previously disabled placeholder)
- [x] Inspect Android permissions — no unnecessary permissions (release build has no INTERNET)
- [x] Verify no API keys, passwords, or credentials in source code
- [x] Create docs/DATA_PRIVACY.md documenting storage, backups, permissions, network, limitations
- [x] Write BackupService unit tests (24 tests: export metadata, round-trip, CSV, validation, preview, restore, duplicates, sanitization, reset)
- [x] Write Phase 8 integration tests (19 tests: full 16-table round-trip, double restore, rollback on failure, reset, FK integrity, CSV, validation edge cases, workout history preservation)

### Backup Format
```json
{
  "format": "reppilot_backup",
  "version": 1,
  "schemaVersion": 6,
  "exportedAt": "2025-07-10T12:00:00.000Z",
  "appVersion": "1.0.0",
  "tables": {
    "user_profile": [...],
    "exercises": [...],
    "foods": [...],
    "routines": [...],
    "body_weight_entries": [...],
    "food_entries": [...],
    "water_entries": [...],
    "personal_goals": [...],
    "body_measurements": [...],
    "meal_templates": [...],
    "routine_exercises": [...],
    "exercise_settings": [...],
    "workout_sessions": [...],
    "workout_sets": [...],
    "overload_recommendations": [...],
    "meal_template_items": [...]
  }
}
```

### Table Insert Order (parents first)
1. user_profile, exercises, foods, routines
2. body_weight_entries, food_entries, water_entries, personal_goals, body_measurements
3. meal_templates, routine_exercises, exercise_settings
4. workout_sessions, workout_sets, overload_recommendations, meal_template_items

### Key Files Added/Modified
- `lib/services/backup_service.dart` — BackupService (export JSON/CSV, validate, preview, restore, reset), BackupValidationResult, RestorePreview, RestoreResult, BackupRestoreException
- `lib/screens/settings/backup_restore_screen.dart` — Export JSON/CSV, import with preview/confirm, double-confirm reset, privacy info
- `lib/core/database/database_helper.dart` — Added databasePath getter, _autoBackupBeforeMigration in onUpgrade
- `lib/screens/settings/settings_screen.dart` — Enabled Backup & Restore link (was disabled placeholder)
- `lib/app.dart` — Added BackupService(database) as Provider
- `pubspec.yaml` — Added file_picker (upgraded to ^13.0.0 in Phase 9 for compileSdk 36 compatibility)
- `docs/DATA_PRIVACY.md` — Storage, backup format, restore, deletion, permissions, network, credentials, limitations
- `test/services/backup_service_test.dart` — 24 unit tests
- `test/phase8_integration_test.dart` — 19 integration tests

### Acceptance Criteria
- [x] JSON export contains all 16 tables with documented format header
- [x] CSV export available for weight, food, and workout tables
- [x] Validation catches invalid format, version, schema, and table structure
- [x] Restore preview shows record counts per table before user confirms
- [x] Restore replaces all data atomically within a transaction
- [x] Failed restore rolls back — original data preserved
- [x] Duplicate IDs handled via replace (not error)
- [x] Rows with missing IDs skipped (warned, not rejected)
- [x] Unknown columns filtered out (forward-compatible with schema changes)
- [x] Boolean values in JSON converted to integers for SQLite
- [x] Full data reset requires double confirmation
- [x] Default exercises and foods re-seeded after reset
- [x] Workout history preserved when routines deleted (routine_name retained)
- [x] Auto-backup of database file before schema migrations
- [x] No unnecessary Android permissions
- [x] No API keys, passwords, or credentials in source
- [x] Data storage and limitations documented in docs/DATA_PRIVACY.md
- [x] Tests cover export, validation, restore round-trip, rollback, reset, duplicates, CSV, and edge cases (43 new tests)

---

## Phase 9: Comprehensive Quality Audit
**Goal**: Find and fix real correctness, data integrity, and release-blocking defects.
**Status**: Complete

### Build Pipeline
- [x] `dart format .` — 0 issues
- [x] `flutter pub get` — dependencies resolved
- [x] `flutter analyze` — 0 issues
- [x] `flutter test` — 602/602 pass (was 572 pre-audit, added 30 new tests)
- [x] `flutter build apk --release` — succeeds (54.2MB)

### Defects Found and Fixed

**Finding 1 (HIGH): Home screen weekly workout count uses unstripped DateTime**
- File: `lib/screens/home/home_screen.dart` lines 50-53
- Bug: `weekStart` retained time-of-day from `DateTime.now()`, causing Monday morning workouts to be missed from the weekly count
- Fix: Added `stripTime(now)` before computing `weekStart`; also added missing `:seconds: 59` to `weekEnd` Duration
- Also fixed same missing-seconds issue in `lib/screens/progress/progress_dashboard.dart`

**Finding 2 (MEDIUM): Six models cannot clear nullable fields via copyWith**
- Files: `food_entry.dart`, `workout_session.dart`, `routine_exercise.dart`, `exercise_settings.dart`, `personal_goal.dart`, `user_profile.dart`
- Bug: `copyWith` used `param ?? this.field` pattern for nullable fields, making it impossible to set them to null (e.g., clearing a calorie value)
- Fix: Added sentinel pattern (`const _sentinel = Object()`) to all nullable copyWith params, with `(param as num?)?.toDouble()` casts for double fields to handle int-to-double coercion

**Finding 3 (MEDIUM): Backup sanitizer silently dropped non-primitive values**
- File: `lib/services/backup_service.dart` `_sanitizeRow()`
- Bug: List/Map values in backup JSON were silently dropped, potentially causing NOT NULL constraint failures during restore
- Fix: Non-primitive values are now converted to strings via `.toString()` instead of being dropped

**Finding 4 (MEDIUM): Weekly report loaded ALL sessions with O(N) queries**
- File: `lib/services/weekly_report_service.dart` lines 52-58
- Bug: Issued one SQL query per completed session to find PRs — 200+ sequential queries for long-term users
- Fix: Added `getAllCompleted()` method to `WorkoutSetRepository` (single JOIN query), replaced the O(N) loop

**Finding 5 (LOW): Overload service treated null-rep sets as working sets**
- File: `lib/services/overload_service.dart` line 20
- Bug: Filter `s.reps != 0` passed null-rep sets (Dart `null != 0` is `true`), causing confusing recommendation text
- Fix: Added explicit `s.reps != null` check to working set filter

**Build fix: file_picker compileSdk incompatibility**
- `file_picker 8.3.7` hardcoded `compileSdk 34` but Flutter 3.47.5's `flutter_plugin_android_lifecycle` requires 36
- Fix: Upgraded `file_picker` from `^8.1.6` to `^13.0.0`; migrated API (`FilePicker.platform.pickFiles()` → `FilePicker.pickFile()`, `FilePicker.platform.saveFile()` → `FilePicker.saveFile()`, `file.bytes` → `file.readAsBytes()`)
- Also set `compileSdk = 36` in `android/app/build.gradle.kts`

### Audit Areas Verified (No Bugs Found)
- [x] Theme persistence: Correctly stores/loads via SharedPreferences
- [x] Navigation: All 5 tabs wired, all screens reachable (backup/restore, reminders, exercise settings, live workout, weekly report)
- [x] Active workout crash recovery: Correctly detects `completed_at IS NULL` sessions and offers resume
- [x] SQLite migrations: Forward-only, additive, consistent v1→v6 chain, auto-backup before upgrade
- [x] Repository correctness: All queries parameterized (no SQL injection), correct table/column names
- [x] Date handling: All repositories use `formatDateOnly(stripTime(date))` for date comparisons
- [x] Progressive overload: No division-by-zero, empty list guards, RPE/bodyweight paths handled
- [x] Backup restore: Transaction rollback on failure, FK integrity check, unknown column filtering
- [x] Model serialization: All toMap/fromMap round-trips verified

### Tests Added (30 new)
- `test/phase9_audit_test.dart`:
  - 15 sentinel copyWith tests (clear-to-null, preserve-existing, int-to-double coercion) across 6 models
  - 5 date boundary edge case tests (stripTime, weekday calculation, formatDateOnly)
  - 2 overload service null-rep filtering tests
  - 2 backup sanitizer non-primitive handling tests
  - 2 getAllCompleted repository tests
  - 4 empty state edge case tests (null macros, no routine, null reps/weight, default settings)

### Key Files Modified
- `lib/screens/home/home_screen.dart` — Fixed weekStart date boundary bug
- `lib/screens/progress/progress_dashboard.dart` — Fixed missing seconds in weekEnd Duration
- `lib/models/food_entry.dart` — Sentinel copyWith for calories, proteinGrams, carbsGrams, fatGrams
- `lib/models/workout_session.dart` — Sentinel copyWith for routineId, completedAt
- `lib/models/routine_exercise.dart` — Sentinel copyWith for targetRepsMin, targetRepsMax, targetWeightKg
- `lib/models/exercise_settings.dart` — Sentinel copyWith for machineIncrementKg
- `lib/models/personal_goal.dart` — Sentinel copyWith for startDate, endDate
- `lib/models/user_profile.dart` — Sentinel copyWith for heightCm, dateOfBirth
- `lib/services/backup_service.dart` — Non-primitive values converted to strings instead of dropped
- `lib/services/weekly_report_service.dart` — Uses getAllCompleted() instead of O(N) per-session queries
- `lib/repositories/workout_set_repository.dart` — Added getAllCompleted() single-query method
- `lib/services/overload_service.dart` — Added null reps check to working set filter
- `lib/screens/settings/backup_restore_screen.dart` — Migrated to file_picker 13.x API
- `pubspec.yaml` — file_picker ^13.0.0
- `android/app/build.gradle.kts` — compileSdk = 36
- `test/phase9_audit_test.dart` — 30 new tests

### Remaining Risks (require physical Android device)
- [ ] Live workout recording end-to-end (start, add sets, rest timer, finish, summary screen)
- [ ] Interrupted session recovery after process kill (resume banner on home screen)
- [ ] Backup export via SAF file picker dialog on real device
- [ ] Restore import flow with preview dialog and data verification
- [ ] Theme switching visual verification (dark/light/system)
- [ ] Notification scheduling with real Android notification manager
- [ ] Body weight and progress chart rendering with fl_chart
- [ ] Responsive layout on small (5") to large (7") screens
- [ ] TalkBack accessibility scan
- [ ] App icon and splash screen (not yet implemented)
- [ ] Rapid tap handling on workout controls (double-finish guard exists but untested on device)

---

## Phase 10: Release Preparation
**Goal**: Prepare RepPilot for public Android distribution.
**Status**: Complete

### Tasks
- [x] Verify Android application ID (`com.reppilot.rep_pilot`) and document how to change it
- [x] Fix app display name: `android:label` changed from `rep_pilot` to `RepPilot`
- [x] Build release APK (54.2MB) and Android App Bundle (52.3MB)
- [x] Document secure signing and keystore backup (`docs/SIGNING.md`)
- [x] Harden `.gitignore` with keystore/signing/secrets exclusions
- [x] Add MIT license (`LICENSE`)
- [x] Write comprehensive README with setup, run, test, build, and troubleshooting
- [x] Prepare store-description text, screenshot requirements, and privacy disclosures (`docs/STORE_LISTING.md`)
- [x] Create GitHub Releases checklist and APK distribution instructions (`docs/RELEASE_CHECKLIST.md`)
- [x] Identify manual physical-device checks (`docs/DEVICE_TESTING.md`)
- [x] Document Google Play publishing requirements and process
- [x] Run `flutter analyze` (0 issues), `flutter test` (602/602 pass), release builds (both succeed)

### Acceptance Criteria
- [x] `flutter analyze` reports zero issues
- [x] `flutter test` — 602/602 pass
- [x] `flutter build apk --release` succeeds
- [x] `flutter build appbundle --release` succeeds
- [x] `.gitignore` excludes `*.jks`, `*.keystore`, `key.properties`, `.env`
- [x] README covers setup, run, test, build, troubleshooting
- [x] Signing guide documents keystore generation, Gradle config, and backup
- [x] Store listing has short/full descriptions, screenshot specs, and privacy disclosures

### Remaining Before Publication
- [ ] Generate a release keystore and configure production signing (see `docs/SIGNING.md`)
- [ ] Replace debug signing in `build.gradle.kts` with release signing config
- [ ] Choose a final application ID if `com.reppilot.rep_pilot` is not desired
- [ ] Design and add a custom app icon (currently using Flutter default)
- [ ] Add a splash screen
- [ ] Capture screenshots for store listing
- [ ] Create a Google Play Developer account ($25 one-time) if publishing to Play Store
- [ ] Complete Play Console setup (data safety, content rating, store listing)
- [ ] Run manual device testing checklist (`docs/DEVICE_TESTING.md`)

---

## Dependency Plan

| Package | Version | Purpose |
|---|---|---|
| sqflite | ^2.4.2 | Local SQLite database |
| path | (SDK) | Path manipulation for DB |
| shared_preferences | ^2.3.4 | Lightweight key-value settings |
| provider | ^6.1.2 | State management |
| fl_chart | ^0.70.2 | Weight/progress charts |
| intl | ^0.20.2 | Date/number formatting |
| file_picker | ^13.0.0 | Backup file selection and export |
| path_provider | ^2.1.5 | App document directory |
| uuid | ^4.5.1 | Unique IDs for records |

All packages are free, offline-capable, and well-maintained on pub.dev.

---

## Risk Register

| Risk | Severity | Mitigation |
|---|---|---|
| sqflite migration breaks existing data | High | Auto-backup before migration; additive-only schema changes |
| fl_chart API breaking change | Medium | Pin version; charts are isolated in their own widgets |
| Large dataset performance (1000+ sessions) | Medium | Index key columns; paginate lists; lazy-load charts |
| Crash during active workout loses data | High | Save to DB after each set completion, not just session end |
| User expects cloud sync | Low | Document as offline-only in onboarding; export/import covers portability |
| Backup file corruption or tampering | Medium | Validate format, version, and table structure before restore; transaction rollback on failure |

---

## Next Step

**Phase 10 complete.** The app is ready for release signing and distribution. See `docs/RELEASE_CHECKLIST.md` for the step-by-step publishing workflow.
