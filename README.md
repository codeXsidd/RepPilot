# RepPilot

**Train smart. Track every rep. Grow stronger.**

RepPilot is a free, offline-first Android fitness app. No accounts, no subscriptions, no ads, no internet required. Your data stays on your device.

## Features

- **Workout Management** — Create custom routines, assign exercises, schedule across the week
- **Exercise Library** — 152 built-in exercises across 10 categories with full metadata (difficulty, instructions, safety notes, secondary muscles, substitutions) plus unlimited custom exercises
- **Live Workout Recording** — Set-by-set logging with rest timers; recovers if the app closes mid-workout
- **Progressive Overload** — Rule-based suggestions that explain *why* they recommend increasing weight or reps
- **Body Weight Tracking** — Daily weigh-ins with history charts
- **Diet & Nutrition** — Log meals (calories, protein, carbs, fat), track water intake, search from 90+ common foods
- **Motivation** — Daily messages, consistency streaks, and weekly performance reports
- **Body Measurements** — Track waist, chest, arms, and hips over time
- **Units** — Display weights in kg or lb (configurable in Settings)
- **Themes** — Dark, light, or follow system
- **Onboarding** — Guided welcome flow for first-time users
- **Data Ownership** — Full JSON backup/restore, CSV exports, factory reset — you own your data

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.47+ (Dart 3.13+)
- Android SDK with API 36 (install via Android Studio SDK Manager)
- Java 17+ (ships with Android Studio)

## Setup

```bash
git clone https://github.com/<your-username>/RepPilot.git
cd RepPilot
flutter pub get
```

## Run

```bash
# Debug on a connected device or emulator
flutter run

# Release mode (faster, no debug banner)
flutter run --release
```

## Testing

```bash
# Run all tests (642 tests)
flutter test

# Run with verbose output
flutter test --reporter expanded
```

## Code Quality

```bash
# Format all Dart files
dart format .

# Static analysis (must be zero issues)
flutter analyze
```

## Build

```bash
# Release APK (for sideloading or GitHub Releases)
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Android App Bundle (for Google Play)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

> **Note:** Release builds are currently signed with debug keys. See [docs/SIGNING.md](docs/SIGNING.md) for production signing setup.

## Project Structure

```
lib/
  main.dart                  # App entry point
  app.dart                   # MaterialApp configuration
  core/
    database/                # Database helper, migrations, schema (v7, 16 tables)
    theme/                   # Dark/light/system themes
    constants.dart           # App-wide constants
    utils.dart               # Shared utilities
  models/                    # 14 immutable data classes
  repositories/              # 16 database repositories
  screens/
    home/                    # Dashboard with weekly summary
    workouts/                # Routines, schedule, live session
    exercises/               # Exercise library and custom exercises
    progress/                # Progressive overload, charts
    weight/                  # Body weight tracking and history
    diet/                    # Meal logging, food search, water intake
    settings/                # Theme, backup/restore, profile
  services/                  # Overload engine, backup, motivation, reports
  widgets/                   # Shared reusable widgets
```

## Architecture

| Layer | Technology |
|---|---|
| State management | Provider + ChangeNotifier |
| Local storage | sqflite (SQLite) — 16 tables, schema v7 |
| Settings | shared_preferences |
| Charts | fl_chart |
| File I/O | file_picker 13.x |

No network calls, no analytics, no telemetry. Everything runs locally.

## Application ID

The current Android application ID is `com.reppilot.rep_pilot`. If you fork this project, change it to your own reverse-domain ID in [android/app/build.gradle.kts](android/app/build.gradle.kts):

```kotlin
applicationId = "com.yourdomain.yourapp"
```

Also update the `namespace` in the same file to match.

## Troubleshooting

| Problem | Solution |
|---|---|
| `flutter pub get` fails | Run `flutter doctor` and fix any SDK issues |
| Build fails with compileSdk errors | Ensure Android SDK 36 is installed |
| Tests fail on Windows | Requires `sqflite_common_ffi` (already in dev_dependencies) |
| Emulator runs slowly | Enable hardware acceleration in BIOS and use x86_64 image |
| APK too large for your needs | Run `flutter build apk --split-per-abi` for smaller per-architecture APKs |

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Ensure `flutter analyze` reports zero issues
4. Ensure `flutter test` passes all tests
5. Format with `dart format .`
6. Open a pull request

## License

See [LICENSE](LICENSE) for details.

## Privacy

RepPilot collects no data. There are no network calls, no analytics, no tracking, and no telemetry. All data is stored locally on your device in a SQLite database. Uninstalling the app deletes all data unless you export a backup first.
