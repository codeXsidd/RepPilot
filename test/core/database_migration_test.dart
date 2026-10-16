import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:rep_pilot/core/database/database_helper.dart';
import 'package:rep_pilot/core/database/schema.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('schema version matches currentSchemaVersion', () {
    expect(currentSchemaVersion, 6);
  });

  test('onCreate creates all tables', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: currentSchemaVersion,
        onConfigure: DatabaseHelper.onConfigure,
        onCreate: DatabaseHelper.onCreate,
      ),
    );

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' "
      "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );
    final tableNames = tables.map((r) => r['name'] as String).toSet();

    expect(
      tableNames,
      containsAll([
        'user_profile',
        'exercises',
        'routines',
        'routine_exercises',
        'workout_sessions',
        'workout_sets',
        'body_weight_entries',
        'food_entries',
        'water_entries',
        'personal_goals',
        'exercise_settings',
        'overload_recommendations',
        'body_measurements',
        'foods',
        'meal_templates',
        'meal_template_items',
      ]),
    );

    await db.close();
  });

  test('onCreate creates all indexes', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: currentSchemaVersion,
        onConfigure: DatabaseHelper.onConfigure,
        onCreate: DatabaseHelper.onCreate,
      ),
    );

    final indexes = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index' "
      "AND name LIKE 'idx_%'",
    );
    final indexNames = indexes.map((r) => r['name'] as String).toSet();

    expect(
      indexNames,
      containsAll([
        'idx_exercises_category',
        'idx_exercises_name',
        'idx_exercises_equipment',
        'idx_exercises_muscle_group',
        'idx_routines_day_of_week',
        'idx_routine_exercises_routine_id',
        'idx_workout_sessions_started_at',
        'idx_workout_sessions_routine_id',
        'idx_workout_sets_session_id',
        'idx_workout_sets_exercise_id',
        'idx_body_weight_entries_date',
        'idx_food_entries_date',
        'idx_water_entries_date',
        'idx_personal_goals_goal_type',
        'idx_exercise_settings_exercise_id',
        'idx_overload_recommendations_exercise_id',
        'idx_body_measurements_date',
        'idx_foods_name',
        'idx_foods_category',
        'idx_meal_template_items_template_id',
      ]),
    );

    await db.close();
  });

  test('foreign keys are enabled after onConfigure', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: currentSchemaVersion,
        onConfigure: DatabaseHelper.onConfigure,
        onCreate: DatabaseHelper.onCreate,
      ),
    );

    final result = await db.rawQuery('PRAGMA foreign_keys');
    expect(result.first.values.first, 1);

    await db.close();
  });

  test('v1Tables and v1Indexes counts', () {
    expect(v1Tables.length, 10);
    expect(v1Indexes.length, 12);
  });

  test('v1ToV2Migration adds expected columns', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: currentSchemaVersion,
        onConfigure: DatabaseHelper.onConfigure,
        onCreate: DatabaseHelper.onCreate,
      ),
    );

    final exerciseCols = await db.rawQuery('PRAGMA table_info(exercises)');
    final exerciseColNames = exerciseCols
        .map((r) => r['name'] as String)
        .toSet();
    expect(exerciseColNames, contains('equipment'));

    final reCols = await db.rawQuery('PRAGMA table_info(routine_exercises)');
    final reColNames = reCols.map((r) => r['name'] as String).toSet();
    expect(reColNames, contains('target_reps_min'));
    expect(reColNames, contains('target_reps_max'));

    await db.close();
  });

  test('onUpgrade from v1 to v2 adds new columns', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: DatabaseHelper.onConfigure,
        onCreate: (db, version) async {
          for (final sql in v1Tables) {
            await db.execute(sql);
          }
          for (final sql in v1Indexes) {
            await db.execute(sql);
          }
        },
      ),
    );

    // Simulate upgrade on the same open database
    await DatabaseHelper.onUpgrade(db, 1, 2);

    final exerciseCols = await db.rawQuery('PRAGMA table_info(exercises)');
    final exerciseColNames = exerciseCols
        .map((r) => r['name'] as String)
        .toSet();
    expect(exerciseColNames, contains('equipment'));

    final reCols = await db.rawQuery('PRAGMA table_info(routine_exercises)');
    final reColNames = reCols.map((r) => r['name'] as String).toSet();
    expect(reColNames, contains('target_reps_min'));
    expect(reColNames, contains('target_reps_max'));

    await db.close();
  });
}
