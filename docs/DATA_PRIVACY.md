# RepPilot Data & Privacy

## Where your data lives

All data is stored locally on your device in a SQLite database inside the
app's private storage directory. No data is ever sent to a server, cloud
service, or third party.

## What is stored

- Workout routines, exercises, and session history
- Set-by-set workout logs (reps, weight, RPE)
- Body weight and body measurement entries
- Food entries, water intake, and meal templates
- Personal goals and progressive overload recommendations
- App preferences (theme, reminder settings)

## Backup & export

- **JSON backup** exports every table into a single human-readable file.
  You choose where to save it. The file format is documented in the backup
  header (`format`, `version`, `schemaVersion` fields).
- **CSV export** is available for body weight, food log, and workout
  session tables for easy import into spreadsheets.
- Backups are **not encrypted**. Anyone with access to the file can read
  your data. Store backup files in a location you trust.

## Restore

- Restore replaces **all** current data with the contents of the backup.
- A preview screen shows record counts before you confirm.
- The restore runs inside a database transaction. If it fails partway
  through, the transaction rolls back and your previous data remains
  intact.
- Backups from older schema versions are accepted; missing columns
  receive default values. Backups from newer schema versions are rejected.

## Data deletion

- **Reset All Data** permanently deletes every record and re-seeds the
  default exercise and food libraries. This requires two confirmations.
- Uninstalling the app deletes all data unless you have created a backup.
- There is no "recycle bin" or undo for deletion.

## Permissions

RepPilot requests **no** runtime permissions beyond what Android grants
automatically. File export and import use the Storage Access Framework
(SAF), which presents a system file-picker dialog without needing broad
storage permissions.

The debug and profile build variants declare `INTERNET` permission for
Flutter hot-reload; the release build does **not** include it.

## Network access

RepPilot makes **zero** network calls. There is no analytics, telemetry,
crash reporting, ad SDK, or remote configuration. The release APK does not
hold the `INTERNET` permission.

## Credentials

The source code contains no API keys, passwords, tokens, or credentials
of any kind.

## Limitations

- Backups are plain-text JSON. Treat them like any other personal file.
- The app does not currently support selective (partial) restore.
- Progress photos are not yet implemented; when they are, they will be
  stored locally and included in backups only with user consent.
- Database migrations are forward-only. Once you open the app with a new
  version, the database schema is upgraded and cannot be downgraded. The
  app creates an automatic copy of the database file before each
  migration.
