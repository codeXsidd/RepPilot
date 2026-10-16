import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:rep_pilot/core/data/default_exercises.dart';
import 'package:rep_pilot/models/exercise.dart';
import 'package:rep_pilot/models/routine.dart';
import 'package:rep_pilot/models/routine_exercise.dart';
import 'package:rep_pilot/models/workout_session.dart';
import 'package:rep_pilot/models/workout_set.dart';
import 'package:rep_pilot/repositories/exercise_repository.dart';
import 'package:rep_pilot/repositories/routine_exercise_repository.dart';
import 'package:rep_pilot/repositories/routine_repository.dart';
import 'package:rep_pilot/repositories/workout_session_repository.dart';
import 'package:rep_pilot/repositories/workout_set_repository.dart';

import 'helpers/test_database.dart';

void main() {
  late Database db;
  late ExerciseRepository exerciseRepo;
  late RoutineRepository routineRepo;
  late RoutineExerciseRepository reRepo;
  late WorkoutSessionRepository sessionRepo;
  late WorkoutSetRepository setRepo;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = await openTestDatabase();
    exerciseRepo = ExerciseRepository(db);
    routineRepo = RoutineRepository(db);
    reRepo = RoutineExerciseRepository(db);
    sessionRepo = WorkoutSessionRepository(db);
    setRepo = WorkoutSetRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('default exercise library', () {
    test('buildDefaultExercises returns 58+ exercises', () {
      final defaults = buildDefaultExercises();
      expect(defaults.length, greaterThanOrEqualTo(58));
    });

    test('all default exercises have isCustom = false', () {
      final defaults = buildDefaultExercises();
      expect(defaults.every((e) => !e.isCustom), true);
    });

    test('all default exercises have unique IDs', () {
      final defaults = buildDefaultExercises();
      final ids = defaults.map((e) => e.id).toSet();
      expect(ids.length, defaults.length);
    });

    test('all categories covered', () {
      final defaults = buildDefaultExercises();
      final cats = defaults.map((e) => e.category).toSet();
      expect(
        cats,
        containsAll(['chest', 'back', 'shoulders', 'legs', 'arms', 'core']),
      );
    });

    test('exerciseCategories is sorted', () {
      final sorted = List<String>.from(exerciseCategories)..sort();
      expect(exerciseCategories, sorted);
    });

    test('equipmentTypes is sorted', () {
      final sorted = List<String>.from(equipmentTypes)..sort();
      expect(equipmentTypes, sorted);
    });

    test('seed defaults writes to database', () async {
      final defaults = buildDefaultExercises();
      await exerciseRepo.seedDefaults(defaults);

      final all = await exerciseRepo.getAll();
      expect(all.length, defaults.length);
    });

    test('seeded exercises are searchable', () async {
      await exerciseRepo.seedDefaults(buildDefaultExercises());

      final results = await exerciseRepo.search('bench');
      expect(results, isNotEmpty);
      expect(results.any((e) => e.name.toLowerCase().contains('bench')), true);
    });

    test('seeded exercises filterable by category', () async {
      await exerciseRepo.seedDefaults(buildDefaultExercises());

      final chest = await exerciseRepo.getByCategory('chest');
      expect(chest, isNotEmpty);
      expect(chest.every((e) => e.category == 'chest'), true);
    });
  });

  group('routine duplication with exercises', () {
    test('full duplication preserves exercise details', () async {
      await exerciseRepo.create(
        Exercise(
          id: 'ex-1',
          name: 'Bench',
          equipment: 'barbell',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await exerciseRepo.create(
        Exercise(
          id: 'ex-2',
          name: 'OHP',
          equipment: 'barbell',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await routineRepo.create(
        Routine(
          id: 'r-1',
          name: 'Push Day',
          dayOfWeek: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await reRepo.create(
        RoutineExercise(
          id: 're-1',
          routineId: 'r-1',
          exerciseId: 'ex-1',
          targetSets: 4,
          targetRepsMin: 6,
          targetRepsMax: 8,
          targetWeightKg: 100.0,
          restSeconds: 180,
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await reRepo.create(
        RoutineExercise(
          id: 're-2',
          routineId: 'r-1',
          exerciseId: 'ex-2',
          targetSets: 3,
          targetRepsMin: 8,
          targetRepsMax: 12,
          restSeconds: 90,
          sortOrder: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final copy = await routineRepo.duplicate('r-1');
      final copyExercises = await reRepo.getByRoutineId(copy.id);

      expect(copy.name, 'Push Day (Copy)');
      expect(copy.dayOfWeek, isNull);
      expect(copyExercises.length, 2);

      final first = copyExercises[0];
      expect(first.exerciseId, 'ex-1');
      expect(first.targetSets, 4);
      expect(first.targetRepsMin, 6);
      expect(first.targetRepsMax, 8);
      expect(first.targetWeightKg, 100.0);
      expect(first.restSeconds, 180);

      final second = copyExercises[1];
      expect(second.exerciseId, 'ex-2');
      expect(second.sortOrder, 1);
    });
  });

  group('historical data preservation', () {
    test('deleting routine preserves workout sessions', () async {
      await exerciseRepo.create(
        Exercise(id: 'ex-1', name: 'Bench', createdAt: now, updatedAt: now),
      );
      await routineRepo.create(
        Routine(
          id: 'r-1',
          name: 'Push Day',
          dayOfWeek: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await sessionRepo.create(
        WorkoutSession(
          id: 's-1',
          routineId: 'r-1',
          routineName: 'Push Day',
          startedAt: now,
          completedAt: now.add(const Duration(hours: 1)),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await setRepo.create(
        WorkoutSet(
          id: 'ws-1',
          sessionId: 's-1',
          exerciseId: 'ex-1',
          exerciseName: 'Bench',
          setNumber: 1,
          reps: 10,
          weightKg: 80.0,
          completed: true,
        ),
      );

      await routineRepo.delete('r-1');

      final session = await sessionRepo.getById('s-1');
      expect(session, isNotNull);
      expect(session!.routineId, isNull);
      expect(session.routineName, 'Push Day');

      final sets = await setRepo.getBySessionId('s-1');
      expect(sets.length, 1);
      expect(sets.first.exerciseName, 'Bench');
      expect(sets.first.weightKg, 80.0);
    });

    test('archiving routine preserves it and its data', () async {
      await exerciseRepo.create(
        Exercise(id: 'ex-1', name: 'Bench', createdAt: now, updatedAt: now),
      );
      await routineRepo.create(
        Routine(
          id: 'r-1',
          name: 'Push Day',
          dayOfWeek: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await reRepo.create(
        RoutineExercise(
          id: 're-1',
          routineId: 'r-1',
          exerciseId: 'ex-1',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await routineRepo.archive('r-1');

      final routine = await routineRepo.getById('r-1');
      expect(routine, isNotNull);
      expect(routine!.isArchived, true);

      final exercises = await reRepo.getByRoutineId('r-1');
      expect(exercises.length, 1);
    });

    test('changing routine schedule does not affect sessions', () async {
      await routineRepo.create(
        Routine(
          id: 'r-1',
          name: 'Push Day',
          dayOfWeek: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await sessionRepo.create(
        WorkoutSession(
          id: 's-1',
          routineId: 'r-1',
          routineName: 'Push Day',
          startedAt: now,
          completedAt: now.add(const Duration(hours: 1)),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await routineRepo.schedule('r-1', 5);

      final routine = await routineRepo.getById('r-1');
      expect(routine!.dayOfWeek, 5);

      final session = await sessionRepo.getById('s-1');
      expect(session!.routineId, 'r-1');
    });
  });

  group('validation scenarios', () {
    test('routine with empty name can be created at DB level', () async {
      final routine = Routine(
        id: 'r-1',
        name: '',
        createdAt: now,
        updatedAt: now,
      );
      await routineRepo.create(routine);
      final fetched = await routineRepo.getById('r-1');
      expect(fetched, isNotNull);
    });

    test('exercise with empty name can be created at DB level', () async {
      final exercise = Exercise(
        id: 'ex-1',
        name: '',
        createdAt: now,
        updatedAt: now,
      );
      await exerciseRepo.create(exercise);
      final fetched = await exerciseRepo.getById('ex-1');
      expect(fetched, isNotNull);
    });

    test('routine_exercise with zero sets persists', () async {
      await exerciseRepo.create(
        Exercise(id: 'ex-1', name: 'Bench', createdAt: now, updatedAt: now),
      );
      await routineRepo.create(
        Routine(id: 'r-1', name: 'Push', createdAt: now, updatedAt: now),
      );
      await reRepo.create(
        RoutineExercise(
          id: 're-1',
          routineId: 'r-1',
          exerciseId: 'ex-1',
          targetSets: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final fetched = await reRepo.getById('re-1');
      expect(fetched!.targetSets, 0);
    });
  });

  group('scheduling', () {
    test('multiple routines on same day', () async {
      await routineRepo.create(
        Routine(
          id: 'r-1',
          name: 'Morning',
          dayOfWeek: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await routineRepo.create(
        Routine(
          id: 'r-2',
          name: 'Evening',
          dayOfWeek: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final monday = await routineRepo.getByDayOfWeek(1);
      expect(monday.length, 2);
    });

    test('full week schedule', () async {
      for (var day = 1; day <= 5; day++) {
        await routineRepo.create(
          Routine(
            id: 'r-$day',
            name: 'Day $day',
            dayOfWeek: day,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final schedule = await routineRepo.getWeeklySchedule();
      expect(schedule.keys.length, 5);
      for (var day = 1; day <= 5; day++) {
        expect(schedule[day]!.length, 1);
      }
      expect(schedule[6], isNull);
      expect(schedule[7], isNull);
    });

    test('reschedule routine from one day to another', () async {
      await routineRepo.create(
        Routine(
          id: 'r-1',
          name: 'Push Day',
          dayOfWeek: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await routineRepo.schedule('r-1', 3);

      final monday = await routineRepo.getByDayOfWeek(1);
      expect(monday, isEmpty);

      final wednesday = await routineRepo.getByDayOfWeek(3);
      expect(wednesday.length, 1);
      expect(wednesday.first.name, 'Push Day');
    });
  });
}
