# Release Checklist

## Pre-Release

- [ ] All tests pass: `flutter test`
- [ ] Zero analysis issues: `flutter analyze`
- [ ] Code formatted: `dart format .`
- [ ] Version bumped in `pubspec.yaml` (e.g., `1.0.0+1` → `1.1.0+2`)
- [ ] Application ID finalized (cannot change after first Play Store upload)
- [ ] App label is "RepPilot" in `AndroidManifest.xml`
- [ ] Release signing configured (see [SIGNING.md](SIGNING.md))
- [ ] No secrets or signing material in Git (check `git status`)

## Build

```bash
flutter clean
flutter pub get

# APK for GitHub Releases / sideloading
flutter build apk --release

# AAB for Google Play
flutter build appbundle --release
```

### Verify artifacts exist:
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

## GitHub Releases

1. Tag the release:
   ```bash
   git tag -a v1.0.0 -m "RepPilot v1.0.0"
   git push origin v1.0.0
   ```

2. Create a GitHub Release:
   - Go to **Releases > Draft a new release**
   - Select the tag `v1.0.0`
   - Title: `RepPilot v1.0.0`
   - Description: Include changelog, features, and installation instructions
   - Attach `app-release.apk` as a binary asset
   - Mark as **Latest release**

3. Installation instructions for users:
   ```
   1. Download app-release.apk from the Assets section below
   2. On your Android device, enable "Install from unknown sources" in Settings
   3. Open the downloaded APK file to install
   4. Open RepPilot and start training
   ```

## Google Play Publishing

> **Important:** A Google Play Developer account costs $25 (one-time). Publishing is optional — GitHub Releases provides free APK distribution.

### First-time setup:
1. Create a [Google Play Developer account](https://play.google.com/console)
2. Create a new app in the Play Console
3. Fill in the store listing (see [STORE_LISTING.md](STORE_LISTING.md))
4. Complete the Data Safety questionnaire (all answers: no data collected)
5. Complete the Content Rating questionnaire
6. Set pricing to **Free**
7. Upload the AAB file (`app-release.aab`)
8. Select target countries
9. Submit for review

### Google Play requirements (as of 2026):
- **Target API level**: Must target at latest API level within one year of its release
- **App Bundle format**: AAB required for new apps (APK not accepted)
- **Data Safety section**: Must be completed even for offline apps
- **Content rating**: IARC questionnaire required
- **Privacy policy**: Required if app handles any user data (even local-only)
- **64-bit support**: Required (Flutter provides this by default)
- **App signing**: Google Play App Signing enrollment recommended

### Update process:
1. Bump `version` in `pubspec.yaml` (both version name and build number)
2. Build new AAB: `flutter build appbundle --release`
3. Upload to Play Console > Release > Production
4. Add release notes
5. Submit for review

## Post-Release

- [ ] Verify APK installs and launches on a real device
- [ ] Test critical paths: create workout, log session, view progress
- [ ] Verify backup export/import works
- [ ] Check that the app label shows "RepPilot" in the launcher
- [ ] Monitor GitHub Issues / Play Console reviews for crash reports
