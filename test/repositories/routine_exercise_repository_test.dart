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

  Future<void> seedRoutineAndExercise() async {
    await exerciseRepo.create(
      Exercise(id: 'ex-1', name: 'Bench', createdAt: now, updatedAt: now),
    );
    await routineRepo.create(
      Routine(id: 'r-1', name: 'Push', createdAt: now, updatedAt: now),
    );
  }

  test('create and getById', () async {
    await seedRoutineAndExercise();
    final re = RoutineExercise(
      id: 're-1',
      routineId: 'r-1',
      exerciseId: 'ex-1',
      targetSets: 4,
      targetReps: 10,
      targetRepsMin: 8,
      targetRepsMax: 12,
      targetWeightKg: 60.0,
      restSeconds: 90,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );
    await reRepo.create(re);

    final fetched = await reRepo.getById('re-1');
    expect(fetched, isNotNull);
    expect(fetched!.targetSets, 4);
    expect(fetched.targetReps, 10);
    expect(fetched.targetRepsMin, 8);
    expect(fetched.targetRepsMax, 12);
    expect(fetched.targetWeightKg, 60.0);
    expect(fetched.restSeconds, 90);
  });

  test('getByRoutineId returns sorted list', () async {
    await seedRoutineAndExercise();
    await exerciseRepo.create(
      Exercise(id: 'ex-2', name: 'Fly', createdAt: now, updatedAt: now),
    );

    await reRepo.create(
      RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'ex-1',
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await reRepo.create(
      RoutineExercise(
        id: 're-2',
        routineId: 'r-1',
        exerciseId: 'ex-2',
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final list = await reRepo.getByRoutineId('r-1');
    expect(list.length, 2);
    expect(list.first.id, 're-2');
    expect(list.last.id, 're-1');
  });

  test('update modifies fields', () async {
    await seedRoutineAndExercise();
    await reRepo.create(
      RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'ex-1',
        targetSets: 3,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final updated = RoutineExercise(
      id: 're-1',
      routineId: 'r-1',
      exerciseId: 'ex-1',
      targetSets: 5,
      targetRepsMin: 6,
      targetRepsMax: 8,
      targetWeightKg: 100.0,
      restSeconds: 180,
      createdAt: now,
      updatedAt: DateTime.now(),
    );
    await reRepo.update(updated);

    final fetched = await reRepo.getById('re-1');
    expect(fetched!.targetSets, 5);
    expect(fetched.targetRepsMin, 6);
    expect(fetched.targetRepsMax, 8);
    expect(fetched.targetWeightKg, 100.0);
    expect(fetched.restSeconds, 180);
  });

  test('delete removes single entry', () async {
    await seedRoutineAndExercise();
    await reRepo.create(
      RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'ex-1',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await reRepo.delete('re-1');
    final fetched = await reRepo.getById('re-1');
    expect(fetched, isNull);
  });

  test('deleteAllForRoutine removes all entries for routine', () async {
    await seedRoutineAndExercise();
    await exerciseRepo.create(
      Exercise(id: 'ex-2', name: 'OHP', createdAt: now, updatedAt: now),
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
    await reRepo.create(
      RoutineExercise(
        id: 're-2',
        routineId: 'r-1',
        exerciseId: 'ex-2',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await reRepo.deleteAllForRoutine('r-1');
    final list = await reRepo.getByRoutineId('r-1');
    expect(list, isEmpty);
  });

  test('reorder changes sort_order', () async {
    await seedRoutineAndExercise();
    await exerciseRepo.create(
      Exercise(id: 'ex-2', name: 'Fly', createdAt: now, updatedAt: now),
    );
    await exerciseRepo.create(
      Exercise(id: 'ex-3', name: 'OHP', createdAt: now, updatedAt: now),
    );

    await reRepo.create(
      RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'ex-1',
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
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await reRepo.create(
      RoutineExercise(
        id: 're-3',
        routineId: 'r-1',
        exerciseId: 'ex-3',
        sortOrder: 2,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await reRepo.reorder('r-1', ['re-3', 're-1', 're-2']);
    final list = await reRepo.getByRoutineId('r-1');
    expect(list[0].id, 're-3');
    expect(list[1].id, 're-1');
    expect(list[2].id, 're-2');
  });

  test('rep range nullable fields persist correctly', () async {
    await seedRoutineAndExercise();
    await reRepo.create(
      RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'ex-1',
        targetReps: 10,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final fetched = await reRepo.getById('re-1');
    expect(fetched!.targetRepsMin, isNull);
    expect(fetched.targetRepsMax, isNull);
    expect(fetched.repsDisplay, '10');
  });

  test('cannot reference nonexistent routine', () async {
    await exerciseRepo.create(
      Exercise(id: 'ex-1', name: 'Bench', createdAt: now, updatedAt: now),
    );
    expect(
      () => reRepo.create(
        RoutineExercise(
          id: 're-1',
          routineId: 'nonexistent',
          exerciseId: 'ex-1',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('cannot reference nonexistent exercise', () async {
    await routineRepo.create(
      Routine(id: 'r-1', name: 'Push', createdAt: now, updatedAt: now),
    );
    expect(
      () => reRepo.create(
        RoutineExercise(
          id: 're-1',
          routineId: 'r-1',
          exerciseId: 'nonexistent',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsA(isA<DatabaseException>()),
    );
  });
}
