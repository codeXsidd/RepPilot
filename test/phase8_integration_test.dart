import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/core/database/schema.dart';
import 'package:rep_pilot/services/backup_service.dart';

import 'helpers/test_database.dart';

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

  String ts() => DateTime.now().toIso8601String();

  Future<void> seedFullDataset() async {
    final now = ts();
    final exerciseId = generateId();
    final routineId = generateId();
    final sessionId = generateId();
    final foodId = generateId();
    final templateId = generateId();

    await db.insert('user_profile', {
      'id': generateId(),
      'display_name': 'Test User',
      'weight_unit': 'kg',
      'theme_mode': 'dark',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('exercises', {
      'id': exerciseId,
      'name': 'Squat',
      'category': 'legs',
      'muscle_group': 'quads',
      'notes': '',
      'is_custom': 0,
      'is_archived': 0,
      'equipment': 'barbell',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('foods', {
      'id': foodId,
      'name': 'Chicken Breast',
      'category': 'protein',
      'serving_size': 100.0,
      'serving_unit': 'g',
      'calories_per_serving': 165.0,
      'protein_per_serving': 31.0,
      'carbs_per_serving': 0.0,
      'fat_per_serving': 3.6,
      'is_custom': 0,
      'is_estimate': 0,
      'is_favorite': 1,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('routines', {
      'id': routineId,
      'name': 'Leg Day',
      'day_of_week': 1,
      'sort_order': 0,
      'notes': '',
      'is_archived': 0,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('routine_exercises', {
      'id': generateId(),
      'routine_id': routineId,
      'exercise_id': exerciseId,
      'target_sets': 5,
      'target_reps': 5,
      'rest_seconds': 180,
      'sort_order': 0,
      'notes': '',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('exercise_settings', {
      'id': generateId(),
      'exercise_id': exerciseId,
      'min_reps': 5,
      'max_reps': 8,
      'weight_increment_kg': 2.5,
      'is_bodyweight': 0,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('workout_sessions', {
      'id': sessionId,
      'routine_id': routineId,
      'routine_name': 'Leg Day',
      'started_at': now,
      'completed_at': now,
      'notes': 'Great session',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('workout_sets', {
      'id': generateId(),
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'exercise_name': 'Squat',
      'set_number': 1,
      'reps': 5,
      'weight_kg': 100.0,
      'completed': 1,
      'notes': '',
      'is_warmup': 0,
    });

    await db.insert('body_weight_entries', {
      'id': generateId(),
      'date': '2025-07-10',
      'weight_kg': 82.5,
      'notes': '',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('body_measurements', {
      'id': generateId(),
      'date': '2025-07-10',
      'waist_cm': 85.0,
      'chest_cm': 105.0,
      'notes': '',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('food_entries', {
      'id': generateId(),
      'date': '2025-07-10',
      'meal_type': 'lunch',
      'description': 'Grilled chicken and rice',
      'calories': 650.0,
      'protein_grams': 45.0,
      'notes': '',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('water_entries', {
      'id': generateId(),
      'date': '2025-07-10',
      'amount_ml': 500,
      'created_at': now,
    });

    await db.insert('personal_goals', {
      'id': generateId(),
      'goal_type': 'weight',
      'target_value': 80.0,
      'unit': 'kg',
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('overload_recommendations', {
      'id': generateId(),
      'exercise_id': exerciseId,
      'session_id': sessionId,
      'recommended_weight_kg': 102.5,
      'recommended_reps': 5,
      'previous_weight_kg': 100.0,
      'previous_reps': 5,
      'reasoning': 'All reps completed, increase weight',
      'status': 'pending',
      'created_at': now,
    });

    await db.insert('meal_templates', {
      'id': templateId,
      'name': 'Post Workout',
      'meal_type': 'snack',
      'notes': '',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('meal_template_items', {
      'id': generateId(),
      'template_id': templateId,
      'food_id': foodId,
      'servings': 2.0,
      'created_at': now,
    });
  }

  group('full backup/restore round-trip', () {
    test('all 16 tables survive export → reset → restore', () async {
      await seedFullDataset();

      final backup = await service.exportToJson();
      final jsonStr = service.encodeJson(backup);
      final parsed = service.parseBackupJson(jsonStr)!;

      final preview = service.getRestorePreview(parsed);
      expect(preview, isNotNull);
      expect(preview!.totalRecords, greaterThan(0));

      await service.resetAllData();
      for (final table in kTableInsertOrder) {
        final rows = await db.query(table);
        expect(rows, isEmpty, reason: '$table not empty after reset');
      }

      final result = await service.restoreFromJson(parsed);
      expect(result.success, true);
      expect(result.recordsRestored, preview.totalRecords);

      final exercises = await db.query('exercises');
      expect(exercises.length, 1);
      expect(exercises.first['name'], 'Squat');

      final sets = await db.query('workout_sets');
      expect(sets.length, 1);
      expect(sets.first['weight_kg'], 100.0);

      final foods = await db.query('foods');
      expect(foods.length, 1);
      expect(foods.first['name'], 'Chicken Breast');

      final templateItems = await db.query('meal_template_items');
      expect(templateItems.length, 1);
    });

    test('double restore yields same data', () async {
      await seedFullDataset();
      final backup = await service.exportToJson();

      await service.restoreFromJson(backup);
      final firstExercises = await db.query('exercises');

      await service.restoreFromJson(backup);
      final secondExercises = await db.query('exercises');

      expect(firstExercises.length, secondExercises.length);
      expect(firstExercises.first['id'], secondExercises.first['id']);
    });
  });

  group('restore does not leave partial data on failure', () {
    test('transaction rolls back on corrupt row data', () async {
      final now = ts();
      await db.insert('exercises', {
        'id': generateId(),
        'name': 'Original',
        'category': 'legs',
        'muscle_group': 'legs',
        'notes': '',
        'is_custom': 1,
        'is_archived': 0,
        'equipment': '',
        'created_at': now,
        'updated_at': now,
      });

      final exercisesBefore = await db.query('exercises');
      expect(exercisesBefore.length, 1);

      // Create a backup with a NOT NULL violation:
      // exercises.name is NOT NULL, but we pass null
      final backup = {
        'format': kBackupFormat,
        'version': kBackupVersion,
        'schemaVersion': currentSchemaVersion,
        'exportedAt': now,
        'appVersion': '1.0.0',
        'tables': {
          for (final t in kTableInsertOrder) t: <dynamic>[],
          'exercises': [
            {
              'id': generateId(),
              'name': null,
              'category': 'legs',
              'muscle_group': 'legs',
              'notes': '',
              'is_custom': 1,
              'is_archived': 0,
              'equipment': '',
              'created_at': now,
              'updated_at': now,
            },
          ],
        },
      };

      try {
        await service.restoreFromJson(backup);
      } catch (_) {
        // Expected — NOT NULL constraint failure
      }

      // Original data should still be gone because the transaction
      // deletes first, then inserts. On insert failure the entire
      // transaction rolls back, restoring original data.
      final exercisesAfter = await db.query('exercises');
      expect(exercisesAfter.length, 1);
      expect(exercisesAfter.first['name'], 'Original');
    });
  });

  group('reset behaviour', () {
    test('reset clears every table', () async {
      await seedFullDataset();

      var nonEmpty = 0;
      for (final table in kTableInsertOrder) {
        final rows = await db.query(table);
        if (rows.isNotEmpty) nonEmpty++;
      }
      expect(nonEmpty, greaterThan(5));

      await service.resetAllData();

      for (final table in kTableInsertOrder) {
        final rows = await db.query(table);
        expect(rows, isEmpty, reason: '$table not empty');
      }
    });

    test('foreign keys work after reset', () async {
      await seedFullDataset();
      await service.resetAllData();

      final now = ts();
      await db.insert('routines', {
        'id': 'r1',
        'name': 'Test',
        'sort_order': 0,
        'notes': '',
        'is_archived': 0,
        'created_at': now,
        'updated_at': now,
      });

      // routine_exercises.exercise_id references exercises(id) RESTRICT
      // Inserting with non-existent exercise should fail
      expect(
        () async => db.insert('routine_exercises', {
          'id': generateId(),
          'routine_id': 'r1',
          'exercise_id': 'nonexistent',
          'target_sets': 3,
          'target_reps': 10,
          'rest_seconds': 60,
          'sort_order': 0,
          'notes': '',
          'created_at': now,
          'updated_at': now,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('CSV export integration', () {
    test('CSV contains all seeded weight entries', () async {
      final now = ts();
      for (var i = 0; i < 3; i++) {
        await db.insert('body_weight_entries', {
          'id': generateId(),
          'date': '2025-07-${10 + i}',
          'weight_kg': 80.0 + i,
          'notes': '',
          'created_at': now,
          'updated_at': now,
        });
      }

      final csv = await service.exportTableToCsv('body_weight_entries');
      final lines = csv.trim().split('\n');
      expect(lines.length, 4);
    });
  });

  group('validation edge cases', () {
    test('rejects completely empty object', () {
      final result = service.validateBackup(<String, dynamic>{});
      expect(result.isValid, false);
    });

    test('rejects backup with tables as string', () {
      final result = service.validateBackup({
        'format': kBackupFormat,
        'version': kBackupVersion,
        'schemaVersion': currentSchemaVersion,
        'tables': 'not a map',
      });
      expect(result.isValid, false);
    });

    test('accepts backup with empty tables', () {
      final result = service.validateBackup({
        'format': kBackupFormat,
        'version': kBackupVersion,
        'schemaVersion': currentSchemaVersion,
        'tables': <String, dynamic>{},
      });
      expect(result.isValid, true);
    });
  });

  group('preserve workout history', () {
    test(
      'workout sessions persist after routine deletion via backup',
      () async {
        final now = ts();
        final routineId = generateId();
        final sessionId = generateId();
        final exerciseId = generateId();

        await db.insert('exercises', {
          'id': exerciseId,
          'name': 'Bench',
          'category': 'chest',
          'muscle_group': 'chest',
          'notes': '',
          'is_custom': 0,
          'is_archived': 0,
          'equipment': 'barbell',
          'created_at': now,
          'updated_at': now,
        });

        await db.insert('routines', {
          'id': routineId,
          'name': 'Push Day',
          'sort_order': 0,
          'notes': '',
          'is_archived': 0,
          'created_at': now,
          'updated_at': now,
        });

        await db.insert('workout_sessions', {
          'id': sessionId,
          'routine_id': routineId,
          'routine_name': 'Push Day',
          'started_at': now,
          'completed_at': now,
          'notes': '',
          'created_at': now,
          'updated_at': now,
        });

        // Delete routine — session.routine_id becomes NULL (ON DELETE SET NULL)
        await db.delete('routines', where: 'id = ?', whereArgs: [routineId]);

        final sessions = await db.query('workout_sessions');
        expect(sessions.length, 1);
        expect(sessions.first['routine_id'], isNull);
        expect(sessions.first['routine_name'], 'Push Day');

        // Backup and restore — workout history preserved
        final backup = await service.exportToJson();
        await service.resetAllData();
        await service.restoreFromJson(backup);

        final restored = await db.query('workout_sessions');
        expect(restored.length, 1);
        expect(restored.first['routine_name'], 'Push Day');
      },
    );
  });
}
