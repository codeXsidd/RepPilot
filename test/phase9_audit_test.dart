import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/core/database/schema.dart';
import 'package:rep_pilot/models/exercise_settings.dart';
import 'package:rep_pilot/models/food_entry.dart';
import 'package:rep_pilot/models/personal_goal.dart';
import 'package:rep_pilot/models/routine_exercise.dart';
import 'package:rep_pilot/models/user_profile.dart';
import 'package:rep_pilot/models/workout_session.dart';
import 'package:rep_pilot/models/workout_set.dart';
import 'package:rep_pilot/repositories/workout_set_repository.dart';
import 'package:rep_pilot/services/backup_service.dart';
import 'package:rep_pilot/services/overload_service.dart';

import 'helpers/test_database.dart';

void main() {
  final now = DateTime(2025, 7, 10, 14, 30);

  group('FoodEntry copyWith sentinel pattern', () {
    test('can clear calories to null', () {
      final entry = FoodEntry(
        id: 'fe-1',
        date: DateTime(2025, 7, 10),
        calories: 500.0,
        proteinGrams: 30.0,
        createdAt: now,
        updatedAt: now,
      );
      final cleared = entry.copyWith(calories: null);
      expect(cleared.calories, isNull);
      expect(cleared.proteinGrams, 30.0);
    });

    test('can clear all macros to null', () {
      final entry = FoodEntry(
        id: 'fe-1',
        date: DateTime(2025, 7, 10),
        calories: 500.0,
        proteinGrams: 30.0,
        carbsGrams: 50.0,
        fatGrams: 20.0,
        createdAt: now,
        updatedAt: now,
      );
      final cleared = entry.copyWith(
        calories: null,
        proteinGrams: null,
        carbsGrams: null,
        fatGrams: null,
      );
      expect(cleared.calories, isNull);
      expect(cleared.proteinGrams, isNull);
      expect(cleared.carbsGrams, isNull);
      expect(cleared.fatGrams, isNull);
    });

    test('omitting nullable params preserves existing values', () {
      final entry = FoodEntry(
        id: 'fe-1',
        date: DateTime(2025, 7, 10),
        calories: 500.0,
        proteinGrams: 30.0,
        createdAt: now,
        updatedAt: now,
      );
      final updated = entry.copyWith(description: 'New desc');
      expect(updated.calories, 500.0);
      expect(updated.proteinGrams, 30.0);
      expect(updated.description, 'New desc');
    });

    test('accepts int values for double fields', () {
      final entry = FoodEntry(
        id: 'fe-1',
        date: DateTime(2025, 7, 10),
        createdAt: now,
        updatedAt: now,
      );
      final updated = entry.copyWith(calories: 280, proteinGrams: 8);
      expect(updated.calories, 280.0);
      expect(updated.proteinGrams, 8.0);
    });
  });

  group('WorkoutSession copyWith sentinel pattern', () {
    test('can clear completedAt to null', () {
      final session = WorkoutSession(
        id: 's-1',
        startedAt: now,
        completedAt: now.add(const Duration(hours: 1)),
        createdAt: now,
        updatedAt: now,
      );
      final reopened = session.copyWith(completedAt: null);
      expect(reopened.completedAt, isNull);
      expect(reopened.isActive, true);
    });

    test('can clear routineId to null', () {
      final session = WorkoutSession(
        id: 's-1',
        routineId: 'r-1',
        startedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final orphaned = session.copyWith(routineId: null);
      expect(orphaned.routineId, isNull);
    });

    test('omitting nullable params preserves existing values', () {
      final session = WorkoutSession(
        id: 's-1',
        routineId: 'r-1',
        completedAt: now,
        startedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final updated = session.copyWith(notes: 'Great workout');
      expect(updated.routineId, 'r-1');
      expect(updated.completedAt, now);
    });
  });

  group('RoutineExercise copyWith sentinel pattern', () {
    test('can clear targetWeightKg to null', () {
      final re = RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'e-1',
        targetWeightKg: 100.0,
        createdAt: now,
        updatedAt: now,
      );
      final cleared = re.copyWith(targetWeightKg: null);
      expect(cleared.targetWeightKg, isNull);
    });

    test('can clear rep range to null', () {
      final re = RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'e-1',
        targetRepsMin: 8,
        targetRepsMax: 12,
        createdAt: now,
        updatedAt: now,
      );
      final cleared = re.copyWith(targetRepsMin: null, targetRepsMax: null);
      expect(cleared.targetRepsMin, isNull);
      expect(cleared.targetRepsMax, isNull);
    });

    test('accepts int for targetWeightKg', () {
      final re = RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'e-1',
        createdAt: now,
        updatedAt: now,
      );
      final updated = re.copyWith(targetWeightKg: 100);
      expect(updated.targetWeightKg, 100.0);
    });
  });

  group('ExerciseSettings copyWith sentinel pattern', () {
    test('can clear machineIncrementKg to null', () {
      final settings = ExerciseSettings(
        id: 'es-1',
        exerciseId: 'e-1',
        machineIncrementKg: 5.0,
        createdAt: now,
        updatedAt: now,
      );
      final cleared = settings.copyWith(machineIncrementKg: null);
      expect(cleared.machineIncrementKg, isNull);
      expect(cleared.effectiveIncrement, 2.5);
    });

    test('omitting machineIncrementKg preserves existing', () {
      final settings = ExerciseSettings(
        id: 'es-1',
        exerciseId: 'e-1',
        machineIncrementKg: 5.0,
        createdAt: now,
        updatedAt: now,
      );
      final updated = settings.copyWith(minReps: 6);
      expect(updated.machineIncrementKg, 5.0);
      expect(updated.minReps, 6);
    });
  });

  group('PersonalGoal copyWith sentinel pattern', () {
    test('can clear dates to null', () {
      final goal = PersonalGoal(
        id: 'pg-1',
        goalType: 'weight',
        targetValue: 80.0,
        startDate: now,
        endDate: now.add(const Duration(days: 90)),
        createdAt: now,
        updatedAt: now,
      );
      final cleared = goal.copyWith(startDate: null, endDate: null);
      expect(cleared.startDate, isNull);
      expect(cleared.endDate, isNull);
    });
  });

  group('UserProfile copyWith sentinel pattern', () {
    test('can clear heightCm and dateOfBirth to null', () {
      final profile = UserProfile(
        id: 'up-1',
        heightCm: 180.0,
        dateOfBirth: DateTime(1990, 1, 1),
        createdAt: now,
        updatedAt: now,
      );
      final cleared = profile.copyWith(heightCm: null, dateOfBirth: null);
      expect(cleared.heightCm, isNull);
      expect(cleared.dateOfBirth, isNull);
    });

    test('accepts int for heightCm', () {
      final profile = UserProfile(id: 'up-1', createdAt: now, updatedAt: now);
      final updated = profile.copyWith(heightCm: 180);
      expect(updated.heightCm, 180.0);
    });
  });

  group('date boundary edge cases', () {
    test('stripTime removes time component', () {
      final dt = DateTime(2025, 7, 14, 15, 30, 45, 123);
      final stripped = stripTime(dt);
      expect(stripped.hour, 0);
      expect(stripped.minute, 0);
      expect(stripped.second, 0);
      expect(stripped.millisecond, 0);
      expect(stripped.year, 2025);
      expect(stripped.month, 7);
      expect(stripped.day, 14);
    });

    test('Monday weekday calculation is correct', () {
      final monday = DateTime(2025, 7, 14);
      expect(monday.weekday, 1);
      final weekStart = stripTime(
        monday.subtract(Duration(days: monday.weekday - 1)),
      );
      expect(weekStart, DateTime(2025, 7, 14));
    });

    test('Sunday weekday calculation is correct', () {
      final sunday = DateTime(2025, 7, 20, 23, 59, 59);
      expect(sunday.weekday, 7);
      final weekStart = stripTime(
        sunday.subtract(Duration(days: sunday.weekday - 1)),
      );
      expect(weekStart, DateTime(2025, 7, 14));
    });

    test('formatDateOnly produces correct format', () {
      final dt = DateTime(2025, 1, 5);
      expect(formatDateOnly(dt), '2025-01-05');
    });

    test('formatDateOnly handles December 31', () {
      final dt = DateTime(2025, 12, 31);
      expect(formatDateOnly(dt), '2025-12-31');
    });
  });

  group('overload service null-rep filtering', () {
    test('filters out sets with null reps', () {
      final service = OverloadService();
      final settings = ExerciseSettings(
        id: 'es-1',
        exerciseId: 'e-1',
        createdAt: now,
        updatedAt: now,
      );

      final sets = [
        const WorkoutSet(
          id: 's1',
          sessionId: 'sess-1',
          exerciseId: 'e-1',
          exerciseName: 'Bench',
          setNumber: 1,
          reps: null,
          weightKg: 60.0,
          completed: true,
        ),
        const WorkoutSet(
          id: 's2',
          sessionId: 'sess-1',
          exerciseId: 'e-1',
          exerciseName: 'Bench',
          setNumber: 2,
          reps: 0,
          weightKg: 60.0,
          completed: true,
        ),
      ];

      final result = service.generateRecommendation(
        exerciseId: 'e-1',
        settings: settings,
        recentSets: sets,
      );
      expect(result, isNull);
    });

    test('includes sets with valid reps', () {
      final service = OverloadService();
      final settings = ExerciseSettings(
        id: 'es-1',
        exerciseId: 'e-1',
        minReps: 8,
        maxReps: 12,
        createdAt: now,
        updatedAt: now,
      );

      final sets = [
        const WorkoutSet(
          id: 's1',
          sessionId: 'sess-1',
          exerciseId: 'e-1',
          exerciseName: 'Bench',
          setNumber: 1,
          reps: 10,
          weightKg: 60.0,
          completed: true,
        ),
        const WorkoutSet(
          id: 's2',
          sessionId: 'sess-1',
          exerciseId: 'e-1',
          exerciseName: 'Bench',
          setNumber: 2,
          reps: 10,
          weightKg: 60.0,
          completed: true,
        ),
        const WorkoutSet(
          id: 's3',
          sessionId: 'sess-1',
          exerciseId: 'e-1',
          exerciseName: 'Bench',
          setNumber: 3,
          reps: 10,
          weightKg: 60.0,
          completed: true,
        ),
      ];

      final result = service.generateRecommendation(
        exerciseId: 'e-1',
        settings: settings,
        recentSets: sets,
      );
      expect(result, isNotNull);
    });
  });

  group('backup sanitizer non-primitive handling', () {
    late Database db;
    late BackupService service;

    setUp(() async {
      db = await openTestDatabase();
      service = BackupService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('converts list values to strings instead of dropping them', () async {
      final ts = DateTime.now().toIso8601String();
      final backup = {
        'format': kBackupFormat,
        'version': kBackupVersion,
        'schemaVersion': currentSchemaVersion,
        'exportedAt': ts,
        'appVersion': '1.0.0',
        'tables': {
          for (final t in kTableInsertOrder) t: <dynamic>[],
          'exercises': [
            {
              'id': generateId(),
              'name': ['Bench Press'],
              'category': 'chest',
              'muscle_group': 'chest',
              'notes': '',
              'is_custom': 0,
              'is_archived': 0,
              'equipment': 'barbell',
              'created_at': ts,
              'updated_at': ts,
            },
          ],
        },
      };

      final result = await service.restoreFromJson(backup);
      expect(result.success, true);
      expect(result.recordsRestored, 1);

      final exercises = await db.query('exercises');
      expect(exercises.length, 1);
      expect(exercises.first['name'], contains('Bench Press'));
    });

    test('converts map values to strings', () async {
      final ts = DateTime.now().toIso8601String();
      final backup = {
        'format': kBackupFormat,
        'version': kBackupVersion,
        'schemaVersion': currentSchemaVersion,
        'exportedAt': ts,
        'appVersion': '1.0.0',
        'tables': {
          for (final t in kTableInsertOrder) t: <dynamic>[],
          'body_weight_entries': [
            {
              'id': generateId(),
              'date': '2025-07-10',
              'weight_kg': 80.0,
              'notes': {'key': 'value'},
              'created_at': ts,
              'updated_at': ts,
            },
          ],
        },
      };

      final result = await service.restoreFromJson(backup);
      expect(result.success, true);
      expect(result.recordsRestored, 1);
    });
  });

  group('getAllCompleted repository', () {
    late Database db;
    late WorkoutSetRepository setRepo;

    setUp(() async {
      db = await openTestDatabase();
      setRepo = WorkoutSetRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('returns only sets from completed sessions', () async {
      final ts = DateTime.now().toIso8601String();
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
        'created_at': ts,
        'updated_at': ts,
      });

      final completedSessionId = generateId();
      await db.insert('workout_sessions', {
        'id': completedSessionId,
        'routine_name': 'Leg Day',
        'started_at': ts,
        'completed_at': ts,
        'notes': '',
        'created_at': ts,
        'updated_at': ts,
      });
      await db.insert('workout_sets', {
        'id': generateId(),
        'session_id': completedSessionId,
        'exercise_id': exerciseId,
        'exercise_name': 'Squat',
        'set_number': 1,
        'reps': 5,
        'weight_kg': 100.0,
        'completed': 1,
        'is_warmup': 0,
      });

      final activeSessionId = generateId();
      await db.insert('workout_sessions', {
        'id': activeSessionId,
        'routine_name': 'Push Day',
        'started_at': ts,
        'notes': '',
        'created_at': ts,
        'updated_at': ts,
      });
      await db.insert('workout_sets', {
        'id': generateId(),
        'session_id': activeSessionId,
        'exercise_id': exerciseId,
        'exercise_name': 'Squat',
        'set_number': 1,
        'reps': 3,
        'weight_kg': 80.0,
        'completed': 0,
        'is_warmup': 0,
      });

      final allCompleted = await setRepo.getAllCompleted();
      expect(allCompleted.length, 1);
      expect(allCompleted.first.weightKg, 100.0);
    });

    test('returns empty list when no completed sessions', () async {
      final allCompleted = await setRepo.getAllCompleted();
      expect(allCompleted, isEmpty);
    });
  });

  group('empty state edge cases', () {
    test('FoodEntry with all null macros round-trips', () {
      final entry = FoodEntry(
        id: 'fe-1',
        date: DateTime(2025, 7, 10),
        createdAt: now,
        updatedAt: now,
      );
      final restored = FoodEntry.fromMap(entry.toMap());
      expect(restored.calories, isNull);
      expect(restored.proteinGrams, isNull);
      expect(restored.carbsGrams, isNull);
      expect(restored.fatGrams, isNull);
    });

    test('WorkoutSession with no routine round-trips', () {
      final session = WorkoutSession(
        id: 's-1',
        startedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final restored = WorkoutSession.fromMap(session.toMap());
      expect(restored.routineId, isNull);
      expect(restored.completedAt, isNull);
      expect(restored.isActive, true);
    });

    test('WorkoutSet with null reps and weight round-trips', () {
      const set = WorkoutSet(
        id: 'ws-1',
        sessionId: 's-1',
        exerciseId: 'e-1',
        setNumber: 1,
      );
      final restored = WorkoutSet.fromMap(set.toMap());
      expect(restored.reps, isNull);
      expect(restored.weightKg, isNull);
      expect(restored.rpe, isNull);
      expect(restored.completed, false);
    });

    test('ExerciseSettings defaults are sensible', () {
      final settings = ExerciseSettings(
        id: 'es-1',
        exerciseId: 'e-1',
        createdAt: now,
        updatedAt: now,
      );
      expect(settings.minReps, 8);
      expect(settings.maxReps, 12);
      expect(settings.weightIncrementKg, 2.5);
      expect(settings.isBodyweight, false);
      expect(settings.machineIncrementKg, isNull);
      expect(settings.effectiveIncrement, 2.5);
    });
  });
}
