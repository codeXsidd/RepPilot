import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/core/database/schema.dart';
import 'package:rep_pilot/services/backup_service.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late BackupService service;

  setUp(() async {
    db = await openTestDatabase();
    service = BackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  Map<String, dynamic> makeValidBackup({
    String format = kBackupFormat,
    int version = kBackupVersion,
    int? schemaVersion,
    Map<String, dynamic>? tables,
  }) {
    return {
      'format': format,
      'version': version,
      'schemaVersion': schemaVersion ?? currentSchemaVersion,
      'exportedAt': '2025-07-10T12:00:00.000Z',
      'appVersion': '1.0.0',
      'tables': tables ?? {for (final t in kTableInsertOrder) t: <dynamic>[]},
    };
  }

  group('exportToJson', () {
    test('exports all 16 tables with correct metadata', () async {
      final backup = await service.exportToJson();

      expect(backup['format'], kBackupFormat);
      expect(backup['version'], kBackupVersion);
      expect(backup['schemaVersion'], currentSchemaVersion);
      expect(backup['exportedAt'], isNotNull);
      expect(backup['appVersion'], '1.0.0');

      final tables = backup['tables'] as Map<String, dynamic>;
      for (final table in kTableInsertOrder) {
        expect(tables.containsKey(table), true, reason: 'missing $table');
        expect(tables[table], isList);
      }
    });

    test('exported data includes inserted records', () async {
      final now = DateTime.now().toIso8601String();
      final id = generateId();
      await db.insert('exercises', {
        'id': id,
        'name': 'Bench Press',
        'category': 'chest',
        'muscle_group': 'chest',
        'notes': '',
        'is_custom': 0,
        'is_archived': 0,
        'equipment': 'barbell',
        'created_at': now,
        'updated_at': now,
      });

      final backup = await service.exportToJson();
      final exercises =
          (backup['tables'] as Map<String, dynamic>)['exercises'] as List;
      expect(exercises.length, 1);
      expect(exercises.first['id'], id);
      expect(exercises.first['name'], 'Bench Press');
    });
  });

  group('encodeJson / parseBackupJson', () {
    test('round-trips through encode and parse', () async {
      final backup = await service.exportToJson();
      final jsonStr = service.encodeJson(backup);
      final parsed = service.parseBackupJson(jsonStr);

      expect(parsed, isNotNull);
      expect(parsed!['format'], kBackupFormat);
      expect(parsed['version'], kBackupVersion);
    });

    test('parseBackupJson returns null for invalid JSON', () {
      expect(service.parseBackupJson('not json'), isNull);
      expect(service.parseBackupJson('{bad'), isNull);
      expect(service.parseBackupJson(''), isNull);
    });

    test('parseBackupJson returns null for non-map JSON', () {
      expect(service.parseBackupJson('[1,2,3]'), isNull);
      expect(service.parseBackupJson('"hello"'), isNull);
    });
  });

  group('exportTableToCsv', () {
    test('returns empty string for empty table', () async {
      final csv = await service.exportTableToCsv('body_weight_entries');
      expect(csv, '');
    });

    test('produces valid CSV with header and data', () async {
      final now = DateTime.now().toIso8601String();
      await db.insert('body_weight_entries', {
        'id': generateId(),
        'date': '2025-07-10',
        'weight_kg': 80.5,
        'notes': '',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('body_weight_entries', {
        'id': generateId(),
        'date': '2025-07-11',
        'weight_kg': 80.0,
        'notes': 'morning',
        'created_at': now,
        'updated_at': now,
      });

      final csv = await service.exportTableToCsv('body_weight_entries');
      final lines = csv.trim().split('\n');
      expect(lines.length, 3);
      expect(lines.first, contains('id'));
      expect(lines.first, contains('weight_kg'));
      expect(lines[1], contains('80.5'));
    });

    test('escapes commas and quotes in CSV', () async {
      final now = DateTime.now().toIso8601String();
      await db.insert('body_weight_entries', {
        'id': generateId(),
        'date': '2025-07-10',
        'weight_kg': 80.5,
        'notes': 'first, "weigh-in"',
        'created_at': now,
        'updated_at': now,
      });

      final csv = await service.exportTableToCsv('body_weight_entries');
      expect(csv, contains('"first, ""weigh-in"""'));
    });
  });

  group('validateBackup', () {
    test('accepts valid backup', () {
      final result = service.validateBackup(makeValidBackup());
      expect(result.isValid, true);
      expect(result.errors, isEmpty);
    });

    test('rejects wrong format', () {
      final result = service.validateBackup(
        makeValidBackup(format: 'wrong_format'),
      );
      expect(result.isValid, false);
      expect(result.errors.first, contains('Invalid backup format'));
    });

    test('rejects invalid version', () {
      final result = service.validateBackup(makeValidBackup(version: 0));
      expect(result.isValid, false);
      expect(result.errors.first, contains('Invalid backup version'));
    });

    test('rejects future version', () {
      final result = service.validateBackup(makeValidBackup(version: 999));
      expect(result.isValid, false);
      expect(result.errors.first, contains('newer than supported'));
    });

    test('rejects invalid schema version', () {
      final result = service.validateBackup(makeValidBackup(schemaVersion: 0));
      expect(result.isValid, false);
      expect(result.errors.first, contains('Invalid schema version'));
    });

    test('rejects future schema version', () {
      final result = service.validateBackup(
        makeValidBackup(schemaVersion: 999),
      );
      expect(result.isValid, false);
      expect(result.errors.first, contains('newer than current'));
    });

    test('warns about older schema version', () {
      final result = service.validateBackup(
        makeValidBackup(schemaVersion: currentSchemaVersion - 1),
      );
      expect(result.isValid, true);
      expect(result.warnings, isNotEmpty);
      expect(result.warnings.first, contains('older schema'));
    });

    test('rejects missing tables field', () {
      final data = makeValidBackup();
      data.remove('tables');
      final result = service.validateBackup(data);
      expect(result.isValid, false);
    });

    test('warns about unknown tables', () {
      final result = service.validateBackup(
        makeValidBackup(
          tables: {'exercises': <dynamic>[], 'unknown_table': <dynamic>[]},
        ),
      );
      expect(result.isValid, true);
      expect(result.warnings, contains(contains('unknown_table')));
    });

    test('warns about rows without id field', () {
      final result = service.validateBackup(
        makeValidBackup(
          tables: {
            ...{for (final t in kTableInsertOrder) t: <dynamic>[]},
            'exercises': [
              {'name': 'No ID exercise'},
            ],
          },
        ),
      );
      expect(result.isValid, true);
      expect(result.warnings, contains(contains('missing "id"')));
    });

    test('rejects table data that is not a list', () {
      final result = service.validateBackup(
        makeValidBackup(
          tables: {
            ...{for (final t in kTableInsertOrder) t: <dynamic>[]},
            'exercises': 'not_a_list',
          },
        ),
      );
      expect(result.isValid, false);
      expect(result.errors.first, contains('not a list'));
    });
  });

  group('getRestorePreview', () {
    test('returns null for invalid backup', () {
      final preview = service.getRestorePreview({'format': 'wrong'});
      expect(preview, isNull);
    });

    test('returns correct counts', () {
      final preview = service.getRestorePreview(
        makeValidBackup(
          tables: {
            ...{for (final t in kTableInsertOrder) t: <dynamic>[]},
            'exercises': [
              {'id': '1', 'name': 'A'},
              {'id': '2', 'name': 'B'},
            ],
            'routines': [
              {'id': '3', 'name': 'Push Day'},
            ],
          },
        ),
      );

      expect(preview, isNotNull);
      expect(preview!.totalRecords, 3);
      expect(preview.recordCounts['exercises'], 2);
      expect(preview.recordCounts['routines'], 1);
      expect(preview.recordCounts['body_weight_entries'], 0);
      expect(preview.schemaVersion, currentSchemaVersion);
    });
  });

  group('restoreFromJson', () {
    test('restores exported data round-trip', () async {
      final now = DateTime.now().toIso8601String();
      final exerciseId = generateId();
      await db.insert('exercises', {
        'id': exerciseId,
        'name': 'Squat',
        'category': 'legs',
        'muscle_group': 'legs',
        'notes': '',
        'is_custom': 0,
        'is_archived': 0,
        'equipment': 'barbell',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('body_weight_entries', {
        'id': generateId(),
        'date': '2025-07-10',
        'weight_kg': 80.0,
        'notes': '',
        'created_at': now,
        'updated_at': now,
      });

      final backup = await service.exportToJson();

      // Clear database
      await service.resetAllData();
      final emptyExercises = await db.query('exercises');
      expect(emptyExercises, isEmpty);

      // Restore
      final result = await service.restoreFromJson(backup);
      expect(result.success, true);
      expect(result.recordsRestored, 2);

      final exercises = await db.query('exercises');
      expect(exercises.length, 1);
      expect(exercises.first['name'], 'Squat');

      final weights = await db.query('body_weight_entries');
      expect(weights.length, 1);
      expect(weights.first['weight_kg'], 80.0);
    });

    test('handles duplicate IDs via replace', () async {
      final now = DateTime.now().toIso8601String();
      final id = generateId();
      await db.insert('exercises', {
        'id': id,
        'name': 'Original',
        'category': 'legs',
        'muscle_group': 'legs',
        'notes': '',
        'is_custom': 0,
        'is_archived': 0,
        'equipment': 'barbell',
        'created_at': now,
        'updated_at': now,
      });

      final backup = makeValidBackup(
        tables: {
          ...{for (final t in kTableInsertOrder) t: <dynamic>[]},
          'exercises': [
            {
              'id': id,
              'name': 'Replacement',
              'category': 'chest',
              'muscle_group': 'chest',
              'notes': '',
              'is_custom': 0,
              'is_archived': 0,
              'equipment': 'barbell',
              'created_at': now,
              'updated_at': now,
            },
          ],
        },
      );

      final result = await service.restoreFromJson(backup);
      expect(result.success, true);

      final exercises = await db.query('exercises');
      expect(exercises.length, 1);
      expect(exercises.first['name'], 'Replacement');
    });

    test('throws on invalid backup', () async {
      expect(
        () => service.restoreFromJson({'format': 'wrong'}),
        throwsA(isA<BackupRestoreException>()),
      );
    });

    test('replaces all existing data', () async {
      final now = DateTime.now().toIso8601String();
      for (var i = 0; i < 5; i++) {
        await db.insert('exercises', {
          'id': generateId(),
          'name': 'Exercise $i',
          'category': 'legs',
          'muscle_group': 'legs',
          'notes': '',
          'is_custom': 1,
          'is_archived': 0,
          'equipment': '',
          'created_at': now,
          'updated_at': now,
        });
      }

      final backup = makeValidBackup(
        tables: {
          ...{for (final t in kTableInsertOrder) t: <dynamic>[]},
          'exercises': [
            {
              'id': generateId(),
              'name': 'Only One',
              'category': 'chest',
              'muscle_group': 'chest',
              'notes': '',
              'is_custom': 1,
              'is_archived': 0,
              'equipment': '',
              'created_at': now,
              'updated_at': now,
            },
          ],
        },
      );

      await service.restoreFromJson(backup);
      final exercises = await db.query('exercises');
      expect(exercises.length, 1);
      expect(exercises.first['name'], 'Only One');
    });

    test('sanitizes boolean values from JSON', () async {
      final now = DateTime.now().toIso8601String();
      final backup = makeValidBackup(
        tables: {
          ...{for (final t in kTableInsertOrder) t: <dynamic>[]},
          'exercises': [
            {
              'id': generateId(),
              'name': 'Bool Test',
              'category': 'legs',
              'muscle_group': 'legs',
              'notes': '',
              'is_custom': true,
              'is_archived': false,
              'equipment': '',
              'created_at': now,
              'updated_at': now,
            },
          ],
        },
      );

      final result = await service.restoreFromJson(backup);
      expect(result.success, true);

      final exercises = await db.query('exercises');
      expect(exercises.length, 1);
      expect(exercises.first['is_custom'], 1);
      expect(exercises.first['is_archived'], 0);
    });

    test('skips rows without id', () async {
      final now = DateTime.now().toIso8601String();
      final backup = makeValidBackup(
        tables: {
          ...{for (final t in kTableInsertOrder) t: <dynamic>[]},
          'body_weight_entries': [
            {
              'id': generateId(),
              'date': '2025-07-10',
              'weight_kg': 80.0,
              'notes': '',
              'created_at': now,
              'updated_at': now,
            },
            {
              'date': '2025-07-11',
              'weight_kg': 81.0,
              'notes': '',
              'created_at': now,
              'updated_at': now,
            },
          ],
        },
      );

      final result = await service.restoreFromJson(backup);
      expect(result.recordsRestored, 1);
    });

    test('ignores unknown columns in backup data', () async {
      final now = DateTime.now().toIso8601String();
      final backup = makeValidBackup(
        tables: {
          ...{for (final t in kTableInsertOrder) t: <dynamic>[]},
          'exercises': [
            {
              'id': generateId(),
              'name': 'Test',
              'category': 'legs',
              'muscle_group': 'legs',
              'notes': '',
              'is_custom': 1,
              'is_archived': 0,
              'equipment': '',
              'created_at': now,
              'updated_at': now,
              'future_column': 'should be ignored',
            },
          ],
        },
      );

      final result = await service.restoreFromJson(backup);
      expect(result.success, true);
      expect(result.recordsRestored, 1);
    });

    test('restores data through JSON encode/decode round-trip', () async {
      final now = DateTime.now().toIso8601String();
      await db.insert('exercises', {
        'id': generateId(),
        'name': 'Press',
        'category': 'shoulders',
        'muscle_group': 'shoulders',
        'notes': 'overhead',
        'is_custom': 0,
        'is_archived': 0,
        'equipment': 'barbell',
        'created_at': now,
        'updated_at': now,
      });

      final backup = await service.exportToJson();
      final jsonStr = service.encodeJson(backup);
      final parsed = service.parseBackupJson(jsonStr)!;

      await service.resetAllData();
      final result = await service.restoreFromJson(parsed);
      expect(result.success, true);
      expect(result.recordsRestored, 1);

      final exercises = await db.query('exercises');
      expect(exercises.first['name'], 'Press');
    });
  });

  group('resetAllData', () {
    test('deletes all records from all tables', () async {
      final now = DateTime.now().toIso8601String();
      await db.insert('exercises', {
        'id': generateId(),
        'name': 'Curl',
        'category': 'arms',
        'muscle_group': 'arms',
        'notes': '',
        'is_custom': 1,
        'is_archived': 0,
        'equipment': '',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('body_weight_entries', {
        'id': generateId(),
        'date': '2025-07-10',
        'weight_kg': 80.0,
        'notes': '',
        'created_at': now,
        'updated_at': now,
      });

      await service.resetAllData();

      for (final table in kTableInsertOrder) {
        final rows = await db.query(table);
        expect(rows, isEmpty, reason: '$table should be empty after reset');
      }
    });

    test('foreign keys re-enabled after reset', () async {
      await service.resetAllData();

      final fkStatus = await db.rawQuery('PRAGMA foreign_keys');
      expect(fkStatus.first.values.first, 1);
    });
  });

  group('restore with related data', () {
    test('restores parent-child records correctly', () async {
      final now = DateTime.now().toIso8601String();
      final exerciseId = generateId();
      final routineId = generateId();

      final backup = makeValidBackup(
        tables: {
          ...{for (final t in kTableInsertOrder) t: <dynamic>[]},
          'exercises': [
            {
              'id': exerciseId,
              'name': 'Deadlift',
              'category': 'back',
              'muscle_group': 'back',
              'notes': '',
              'is_custom': 0,
              'is_archived': 0,
              'equipment': 'barbell',
              'created_at': now,
              'updated_at': now,
            },
          ],
          'routines': [
            {
              'id': routineId,
              'name': 'Pull Day',
              'sort_order': 0,
              'notes': '',
              'is_archived': 0,
              'created_at': now,
              'updated_at': now,
            },
          ],
          'routine_exercises': [
            {
              'id': generateId(),
              'routine_id': routineId,
              'exercise_id': exerciseId,
              'target_sets': 4,
              'target_reps': 5,
              'rest_seconds': 180,
              'sort_order': 0,
              'notes': '',
              'created_at': now,
              'updated_at': now,
            },
          ],
        },
      );

      final result = await service.restoreFromJson(backup);
      expect(result.success, true);
      expect(result.recordsRestored, 3);

      final routineExercises = await db.query('routine_exercises');
      expect(routineExercises.length, 1);
      expect(routineExercises.first['routine_id'], routineId);
    });
  });

  group('tableDeleteOrder', () {
    test('is reverse of insert order', () {
      final deleteOrder = BackupService.tableDeleteOrder;
      expect(deleteOrder, kTableInsertOrder.reversed.toList());
    });
  });
}
