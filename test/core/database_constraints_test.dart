import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

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

import '../helpers/test_database.dart';

void main() {
  late Database db;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = await openTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('foreign key enforcement', () {
    test('foreign keys are enabled', () async {
      final result = await db.rawQuery('PRAGMA foreign_keys');
      expect(result.first.values.first, 1);
    });

    test('routine_exercise requires valid routine_id', () async {
      final exerciseRepo = ExerciseRepository(db);
      await exerciseRepo.create(
        Exercise(id: 'ex-1', name: 'Bench', createdAt: now, updatedAt: now),
      );

      final reRepo = RoutineExerciseRepository(db);
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

    test('routine_exercise requires valid exercise_id', () async {
      final routineRepo = RoutineRepository(db);
      await routineRepo.create(
        Routine(id: 'r-1', name: 'Push', createdAt: now, updatedAt: now),
      );

      final reRepo = RoutineExerciseRepository(db);
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

    test('cannot delete exercise referenced by workout_set', () async {
      final exerciseRepo = ExerciseRepository(db);
      final routineRepo = RoutineRepository(db);
      final sessionRepo = WorkoutSessionRepository(db);
      final setRepo = WorkoutSetRepository(db);

      await exerciseRepo.create(
        Exercise(id: 'ex-1', name: 'Bench', createdAt: now, updatedAt: now),
      );
      await routineRepo.create(
        Routine(id: 'r-1', name: 'Push', createdAt: now, updatedAt: now),
      );
      await sessionRepo.create(
        WorkoutSession(
          id: 's-1',
          routineId: 'r-1',
          startedAt: now,
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
        ),
      );

      expect(
        () => exerciseRepo.delete('ex-1'),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('deleting routine sets workout_session.routine_id to null', () async {
      final routineRepo = RoutineRepository(db);
      final sessionRepo = WorkoutSessionRepository(db);

      await routineRepo.create(
        Routine(id: 'r-1', name: 'Push', createdAt: now, updatedAt: now),
      );
      await sessionRepo.create(
        WorkoutSession(
          id: 's-1',
          routineId: 'r-1',
          routineName: 'Push',
          startedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await routineRepo.delete('r-1');

      final session = await sessionRepo.getById('s-1');
      expect(session, isNotNull);
      expect(session!.routineId, isNull);
      expect(session.routineName, 'Push');
    });

    test('deleting routine cascades to routine_exercises', () async {
      final routineRepo = RoutineRepository(db);
      final exerciseRepo = ExerciseRepository(db);
      final reRepo = RoutineExerciseRepository(db);

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
          createdAt: now,
          updatedAt: now,
        ),
      );

      await routineRepo.delete('r-1');
      final remaining = await reRepo.getByRoutineId('r-1');
      expect(remaining, isEmpty);
    });

    test('deleting session cascades to workout_sets', () async {
      final exerciseRepo = ExerciseRepository(db);
      final routineRepo = RoutineRepository(db);
      final sessionRepo = WorkoutSessionRepository(db);
      final setRepo = WorkoutSetRepository(db);

      await exerciseRepo.create(
        Exercise(id: 'ex-1', name: 'Bench', createdAt: now, updatedAt: now),
      );
      await routineRepo.create(
        Routine(id: 'r-1', name: 'Push', createdAt: now, updatedAt: now),
      );
      await sessionRepo.create(
        WorkoutSession(
          id: 's-1',
          routineId: 'r-1',
          startedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await setRepo.create(
        WorkoutSet(
          id: 'ws-1',
          sessionId: 's-1',
          exerciseId: 'ex-1',
          setNumber: 1,
        ),
      );

      await sessionRepo.delete('s-1');
      final sets = await setRepo.getBySessionId('s-1');
      expect(sets, isEmpty);
    });
  });

  group('unique constraints', () {
    test('body_weight_entries enforces one entry per date', () async {
      await db.insert('body_weight_entries', {
        'id': 'bw-1',
        'date': '2025-06-15',
        'weight_kg': 75.0,
        'notes': '',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      expect(
        () => db.insert('body_weight_entries', {
          'id': 'bw-2',
          'date': '2025-06-15',
          'weight_kg': 76.0,
          'notes': '',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
