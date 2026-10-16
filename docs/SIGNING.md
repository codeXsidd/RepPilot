# Release Signing Guide

This document explains how to sign RepPilot for production distribution.

## Why Signing Matters

Every Android APK/AAB must be signed. Debug builds use an auto-generated debug keystore, but production releases need a dedicated release keystore that:

- Proves the app comes from you
- Prevents tampering
- Is required by Google Play and most distribution channels
- Must stay the same for all future updates (users cannot update if the signing key changes)

## Step 1: Generate a Keystore

Run from the project root (adjust paths for your OS):

```bash
keytool -genkey -v \
  -keystore android/upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

You will be prompted for:
- **Keystore password** — use a strong, unique password
- **Key password** — can be the same as keystore password
- **Name, organization, location** — used in the certificate (your name/org is fine)

> **CRITICAL:** The `.gitignore` already excludes `*.jks` and `*.keystore`. Never commit your keystore to version control.

## Step 2: Create key.properties

Create `android/key.properties` (this file is gitignored):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

> **CRITICAL:** Never commit `key.properties`. It is already in `.gitignore`.

## Step 3: Configure Gradle

Edit `android/app/build.gradle.kts` to load the properties and use them for release signing:

```kotlin
import java.util.Properties
import java.io.FileInputStream

// Load key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

## Step 4: Build Signed Release

```bash
# Signed APK
flutter build apk --release

# Signed App Bundle (for Google Play)
flutter build appbundle --release
```

## Keystore Backup

**If you lose your keystore, you cannot update your app on Google Play.** Users would need to uninstall and reinstall, losing all local data.

### Backup checklist:
- [ ] Copy `upload-keystore.jks` to an encrypted USB drive or password manager
- [ ] Record the keystore password and key password in a password manager
- [ ] Store backups in at least 2 separate physical locations
- [ ] If using Google Play App Signing, enroll your upload key — Google holds the app signing key, so you can reset your upload key if lost

### Google Play App Signing
Google Play App Signing is strongly recommended. Google holds the actual app signing key; you only need an upload key. Benefits:
- If you lose your upload key, you can request a reset from Google
- Google optimizes APKs per device
- Enroll during first upload in the Google Play Console

## Security Reminders

- **Never** commit `*.jks`, `*.keystore`, or `key.properties` to Git
- **Never** share keystore passwords in chat, email, or issue trackers
- **Never** use the debug keystore for production releases
- Store credentials in a password manager, not in plaintext files
- The `.gitignore` in this project already excludes signing material
