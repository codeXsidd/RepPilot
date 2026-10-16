# Store Listing & Distribution

## App Identity

| Field | Value |
|---|---|
| App name | RepPilot |
| Package name | `com.reppilot.rep_pilot` |
| Tagline | Train smart. Track every rep. Grow stronger. |
| Category | Health & Fitness |
| Content rating | Everyone |

## Short Description (80 chars max)

Free offline gym tracker. Log workouts, track weight, build strength.

## Full Description (4000 chars max)

RepPilot is a completely free, offline-first fitness app that puts you in control of your training data.

**No account required. No subscriptions. No ads. No internet needed.**

WORKOUT MANAGEMENT
Create custom workout routines and schedule them across the week. Add exercises from a library of 58 built-in movements or create your own. Set target reps, weights, and rest periods for each exercise.

LIVE WORKOUT RECORDING
Log every set in real time with a clean, focused interface. Built-in rest timer keeps you on track. If the app closes mid-workout, your session is saved and ready to resume.

PROGRESSIVE OVERLOAD ENGINE
RepPilot analyzes your training history and suggests when to increase weight or reps. Every suggestion comes with a clear explanation so you understand the reasoning.

BODY WEIGHT TRACKING
Record daily weigh-ins and visualize your progress with charts. Track trends over weeks and months.

DIET & NUTRITION
Log meals with calories, protein, carbs, and fat. Search from 90+ common foods or add your own. Track daily water intake.

MOTIVATION & CONSISTENCY
Daily motivational messages, consistency streaks, and weekly performance reports keep you accountable.

YOUR DATA, YOUR CONTROL
All data is stored locally on your device. Export full JSON backups or CSV files anytime. No cloud, no sync, no data collection. Uninstalling the app removes all data unless you export first.

FEATURES AT A GLANCE
• Custom workout routines with weekly scheduling
• 58 built-in exercises + unlimited custom exercises
• Set-by-set workout logging with rest timers
• Progressive overload suggestions with explanations
• Body weight tracking with history charts
• Meal logging with calorie and macro tracking
• Water intake tracking
• Daily motivation and consistency streaks
• Weekly performance reports
• Dark, light, and system themes
• Full data backup, restore, and CSV export
• No ads, no accounts, no internet required

## Screenshot Requirements

Google Play requires 2-8 screenshots per device type. Recommended screenshots:

1. **Home Dashboard** — Shows today's workout, weekly summary, streak
2. **Workout Session** — Live recording with sets, reps, weight entry
3. **Exercise Library** — Browsing exercises by category with search
4. **Progressive Overload** — Suggestion cards with explanations
5. **Body Weight Chart** — Weight history with trend line
6. **Diet Logging** — Meal entry with nutritional breakdown
7. **Backup & Restore** — Data export screen showing privacy message
8. **Dark Theme** — Any feature screen in dark mode

### Specifications
- Phone: 16:9 aspect ratio, minimum 1080×1920 px
- 7-inch tablet: minimum 1200×1920 px (optional)
- 10-inch tablet: minimum 1600×2560 px (optional)
- Format: JPEG or 24-bit PNG, no alpha
- Max file size: 8 MB per image

### How to capture
```bash
# On a connected device or emulator:
adb exec-out screencap -p > screenshot_home.png
```

Or use Android Studio > Logcat > Camera icon, or the emulator's screenshot button.

## Privacy Disclosures

### Data Safety Section (Google Play)

| Question | Answer |
|---|---|
| Does the app collect or share any user data? | **No** |
| Does the app collect data types? | No data collected |
| Is data encrypted in transit? | N/A — no network calls |
| Can users request data deletion? | Yes — Settings > Backup & Restore > Reset All Data |
| Does the app use data to track users? | **No** |

### Privacy Policy

RepPilot does not collect, transmit, or share any personal data. The app operates entirely offline. All user data (workouts, body weight, nutrition logs) is stored locally on the device using SQLite. Users can export their data as JSON or CSV files at any time. No analytics, tracking, telemetry, or advertising SDKs are included.

If Google Play requires a privacy policy URL, host the above text on a GitHub Pages site or as a plain text file in the repository.

## Content Rating

RepPilot contains no:
- Violence, sexual content, or profanity
- User-generated content sharing
- In-app purchases or ads
- Location tracking or personal data collection

Expected IARC rating: **Everyone / PEGI 3 / USK 0**

## Application ID

The current ID is `com.reppilot.rep_pilot`. Before publishing:

1. **Choose a unique ID** — Use reverse-domain notation: `com.yourname.reppilot` or `dev.yourname.reppilot`
2. **This cannot be changed** after publishing to Google Play
3. **Update in** `android/app/build.gradle.kts` — both `applicationId` and `namespace`
4. After changing, run `flutter clean && flutter pub get` before building
