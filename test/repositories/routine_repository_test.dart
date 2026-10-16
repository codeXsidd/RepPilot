import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:rep_pilot/models/exercise.dart';
import 'package:rep_pilot/models/routine.dart';
import 'package:rep_pilot/models/routine_exercise.dart';
import 'package:rep_pilot/repositories/exercise_repository.dart';
import 'package:rep_pilot/repositories/routine_exercise_repository.dart';
import 'package:rep_pilot/repositories/routine_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late RoutineRepository routineRepo;
  late RoutineExerciseRepository reRepo;
  late ExerciseRepository exerciseRepo;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = await openTestDatabase();
    routineRepo = RoutineRepository(db);
    reRepo = RoutineExerciseRepository(db);
    exerciseRepo = ExerciseRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Routine makeRoutine({String id = 'r-1', String name = 'Push Day'}) =>
      Routine(id: id, name: name, dayOfWeek: 1, createdAt: now, updatedAt: now);

  Exercise makeExercise({String id = 'ex-1', String name = 'Bench'}) =>
      Exercise(id: id, name: name, createdAt: now, updatedAt: now);

  test('create and getById', () async {
    await routineRepo.create(makeRoutine());
    final fetched = await routineRepo.getById('r-1');
    expect(fetched, isNotNull);
    expect(fetched!.name, 'Push Day');
  });

  test('getAll returns ordered by sort_order', () async {
    await routineRepo.create(
      makeRoutine(id: 'b', name: 'B').copyWith(sortOrder: 2),
    );
    await routineRepo.create(
      makeRoutine(id: 'a', name: 'A').copyWith(sortOrder: 1),
    );
    final all = await routineRepo.getAll();
    expect(all.first.name, 'A');
  });

  test('getByDayOfWeek filters correctly', () async {
    await routineRepo.create(
      makeRoutine(id: '1', name: 'Mon').copyWith(dayOfWeek: 1),
    );
    await routineRepo.create(
      makeRoutine(id: '2', name: 'Tue').copyWith(dayOfWeek: 2),
    );
    final monday = await routineRepo.getByDayOfWeek(1);
    expect(monday.length, 1);
    expect(monday.first.name, 'Mon');
  });

  test('delete routine cascades to routine_exercises', () async {
    await exerciseRepo.create(makeExercise());
    await routineRepo.create(makeRoutine());
    await reRepo.create(
      RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'ex-1',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await routineRepo.delete('r-1');
    final exercises = await reRepo.getByRoutineId('r-1');
    expect(exercises, isEmpty);
  });

  test('routine_exercise reorder works', () async {
    await exerciseRepo.create(makeExercise(id: 'e1'));
    await exerciseRepo.create(makeExercise(id: 'e2'));
    await routineRepo.create(makeRoutine());
    await reRepo.create(
      RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'e1',
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await reRepo.create(
      RoutineExercise(
        id: 're-2',
        routineId: 'r-1',
        exerciseId: 'e2',
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await reRepo.reorder('r-1', ['re-2', 're-1']);
    final ordered = await reRepo.getByRoutineId('r-1');
    expect(ordered.first.id, 're-2');
    expect(ordered.last.id, 're-1');
  });

  test('cannot add routine_exercise with invalid exercise_id', () async {
    await routineRepo.create(makeRoutine());
    expect(
      () => reRepo.create(
        RoutineExercise(
          id: 're-bad',
          routineId: 'r-1',
          exerciseId: 'nonexistent',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('empty state returns empty lists', () async {
    expect(await routineRepo.getAll(), isEmpty);
    expect(await routineRepo.getByDayOfWeek(1), isEmpty);
  });

  group('schedule and unschedule', () {
    test('schedule assigns day of week', () async {
      await routineRepo.create(makeRoutine().copyWith(dayOfWeek: null));
      await routineRepo.schedule('r-1', 3);

      final fetched = await routineRepo.getById('r-1');
      expect(fetched!.dayOfWeek, 3);
    });

    test('unschedule removes day of week', () async {
      await routineRepo.create(makeRoutine());
      await routineRepo.unschedule('r-1');

      final fetched = await routineRepo.getById('r-1');
      expect(fetched!.dayOfWeek, isNull);
    });

    test('schedule then unschedule round-trips', () async {
      await routineRepo.create(makeRoutine());
      await routineRepo.schedule('r-1', 5);
      await routineRepo.unschedule('r-1');

      final fetched = await routineRepo.getById('r-1');
      expect(fetched!.dayOfWeek, isNull);
    });
  });

  group('getWeeklySchedule', () {
    test('returns routines grouped by day', () async {
      await routineRepo.create(
        makeRoutine(id: 'r-1', name: 'Push').copyWith(dayOfWeek: 1),
      );
      await routineRepo.create(
        makeRoutine(id: 'r-2', name: 'Pull').copyWith(dayOfWeek: 2),
      );
      await routineRepo.create(
        makeRoutine(id: 'r-3', name: 'Legs').copyWith(dayOfWeek: 3),
      );

      final schedule = await routineRepo.getWeeklySchedule();
      expect(schedule.keys.length, 3);
      expect(schedule[1]!.first.name, 'Push');
      expect(schedule[2]!.first.name, 'Pull');
      expect(schedule[3]!.first.name, 'Legs');
    });

    test('excludes unscheduled and archived routines', () async {
      await routineRepo.create(makeRoutine(id: 'r-1', name: 'Scheduled'));
      await routineRepo.create(
        makeRoutine(id: 'r-2', name: 'Unscheduled').copyWith(dayOfWeek: null),
      );
      await routineRepo.create(makeRoutine(id: 'r-3', name: 'Archived'));
      await routineRepo.archive('r-3');

      final schedule = await routineRepo.getWeeklySchedule();
      final allRoutines = schedule.values.expand((list) => list).toList();
      expect(allRoutines.length, 1);
      expect(allRoutines.first.name, 'Scheduled');
    });
  });

  group('duplicate', () {
    test('creates copy with new id and name', () async {
      await routineRepo.create(makeRoutine());
      final copy = await routineRepo.duplicate('r-1');

      expect(copy.id, isNot('r-1'));
      expect(copy.name, 'Push Day (Copy)');
      expect(copy.dayOfWeek, isNull);
      expect(copy.isArchived, false);
    });

    test('duplicate with custom name', () async {
      await routineRepo.create(makeRoutine());
      final copy = await routineRepo.duplicate('r-1', newName: 'Push Day v2');
      expect(copy.name, 'Push Day v2');
    });

    test('copies routine_exercises', () async {
      await exerciseRepo.create(makeExercise(id: 'e1', name: 'Bench'));
      await exerciseRepo.create(makeExercise(id: 'e2', name: 'OHP'));
      await routineRepo.create(makeRoutine());
      await reRepo.create(
        RoutineExercise(
          id: 're-1',
          routineId: 'r-1',
          exerciseId: 'e1',
          targetSets: 4,
          targetReps: 8,
          targetRepsMin: 6,
          targetRepsMax: 10,
          targetWeightKg: 80.0,
          restSeconds: 120,
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await reRepo.create(
        RoutineExercise(
          id: 're-2',
          routineId: 'r-1',
          exerciseId: 'e2',
          sortOrder: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final copy = await routineRepo.duplicate('r-1');
      final copyExercises = await reRepo.getByRoutineId(copy.id);

      expect(copyExercises.length, 2);
      expect(copyExercises[0].exerciseId, 'e1');
      expect(copyExercises[0].targetSets, 4);
      expect(copyExercises[0].targetWeightKg, 80.0);
      expect(copyExercises[0].targetRepsMin, 6);
      expect(copyExercises[0].targetRepsMax, 10);
      expect(copyExercises[1].exerciseId, 'e2');
      expect(copyExercises[0].routineId, copy.id);
      expect(copyExercises[0].id, isNot('re-1'));
    });

    test('throws for nonexistent routine', () async {
      expect(
        () => routineRepo.duplicate('nonexistent'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('archive', () {
    test('archived routines excluded from getAll by default', () async {
      await routineRepo.create(makeRoutine(id: 'r-1', name: 'Active'));
      await routineRepo.create(makeRoutine(id: 'r-2', name: 'To Archive'));
      await routineRepo.archive('r-2');

      final active = await routineRepo.getAll();
      expect(active.length, 1);
      expect(active.first.name, 'Active');

      final all = await routineRepo.getAll(includeArchived: true);
      expect(all.length, 2);
    });

    test('archived routines excluded from getByDayOfWeek', () async {
      await routineRepo.create(makeRoutine(id: 'r-1'));
      await routineRepo.archive('r-1');

      final day = await routineRepo.getByDayOfWeek(1);
      expect(day, isEmpty);
    });
  });
}
