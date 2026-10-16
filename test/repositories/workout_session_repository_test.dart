import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:rep_pilot/models/exercise.dart';
import 'package:rep_pilot/models/routine.dart';
import 'package:rep_pilot/models/workout_session.dart';
import 'package:rep_pilot/models/workout_set.dart';
import 'package:rep_pilot/repositories/exercise_repository.dart';
import 'package:rep_pilot/repositories/routine_repository.dart';
import 'package:rep_pilot/repositories/workout_session_repository.dart';
import 'package:rep_pilot/repositories/workout_set_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late WorkoutSessionRepository sessionRepo;
  late WorkoutSetRepository setRepo;
  late RoutineRepository routineRepo;
  late ExerciseRepository exerciseRepo;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = await openTestDatabase();
    sessionRepo = WorkoutSessionRepository(db);
    setRepo = WorkoutSetRepository(db);
    routineRepo = RoutineRepository(db);
    exerciseRepo = ExerciseRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedRoutineAndExercise() async {
    await routineRepo.create(
      Routine(id: 'r-1', name: 'Push', createdAt: now, updatedAt: now),
    );
    await exerciseRepo.create(
      Exercise(id: 'ex-1', name: 'Bench Press', createdAt: now, updatedAt: now),
    );
  }

  WorkoutSession makeSession({
    String id = 's-1',
    String? routineId = 'r-1',
    DateTime? startedAt,
  }) => WorkoutSession(
    id: id,
    routineId: routineId,
    routineName: 'Push',
    startedAt: startedAt ?? now,
    createdAt: now,
    updatedAt: now,
  );

  test('create and getById', () async {
    await seedRoutineAndExercise();
    await sessionRepo.create(makeSession());
    final fetched = await sessionRepo.getById('s-1');
    expect(fetched, isNotNull);
    expect(fetched!.routineName, 'Push');
    expect(fetched.isActive, true);
  });

  test('createWithSets uses transaction', () async {
    await seedRoutineAndExercise();
    final session = makeSession();
    final sets = [
      WorkoutSet(
        id: 'ws-1',
        sessionId: 's-1',
        exerciseId: 'ex-1',
        exerciseName: 'Bench Press',
        setNumber: 1,
        reps: 10,
        weightKg: 60,
      ),
      WorkoutSet(
        id: 'ws-2',
        sessionId: 's-1',
        exerciseId: 'ex-1',
        exerciseName: 'Bench Press',
        setNumber: 2,
        reps: 8,
        weightKg: 60,
      ),
    ];
    await sessionRepo.createWithSets(session, sets);

    final fetchedSets = await setRepo.getBySessionId('s-1');
    expect(fetchedSets.length, 2);
    expect(fetchedSets.first.reps, 10);
  });

  test('getActiveSession finds incomplete session', () async {
    await seedRoutineAndExercise();
    await sessionRepo.create(makeSession());
    final active = await sessionRepo.getActiveSession();
    expect(active, isNotNull);
    expect(active!.id, 's-1');
  });

  test('complete marks session finished', () async {
    await seedRoutineAndExercise();
    await sessionRepo.create(makeSession());
    final end = now.add(const Duration(hours: 1));
    await sessionRepo.complete('s-1', completedAt: end);

    final fetched = await sessionRepo.getById('s-1');
    expect(fetched!.isActive, false);

    final active = await sessionRepo.getActiveSession();
    expect(active, isNull);
  });

  test('getByDateRange filters correctly', () async {
    await seedRoutineAndExercise();
    await sessionRepo.create(
      makeSession(id: 's-1', startedAt: DateTime(2025, 6, 10)),
    );
    await sessionRepo.create(
      makeSession(id: 's-2', startedAt: DateTime(2025, 6, 20)),
    );

    final range = await sessionRepo.getByDateRange(
      DateTime(2025, 6, 1),
      DateTime(2025, 6, 15),
    );
    expect(range.length, 1);
    expect(range.first.id, 's-1');
  });

  test('deleting routine sets session routine_id to NULL', () async {
    await seedRoutineAndExercise();
    await sessionRepo.create(makeSession());
    await routineRepo.delete('r-1');

    final fetched = await sessionRepo.getById('s-1');
    expect(fetched, isNotNull);
    expect(fetched!.routineId, isNull);
    expect(fetched.routineName, 'Push');
  });

  test('deleting session cascades to sets', () async {
    await seedRoutineAndExercise();
    await sessionRepo.create(makeSession());
    await setRepo.create(
      WorkoutSet(
        id: 'ws-1',
        sessionId: 's-1',
        exerciseId: 'ex-1',
        exerciseName: 'Bench',
        setNumber: 1,
      ),
    );

    await sessionRepo.delete('s-1');
    final sets = await setRepo.getBySessionId('s-1');
    expect(sets, isEmpty);
  });

  test('countByDateRange counts completed sessions', () async {
    await seedRoutineAndExercise();
    final completed = makeSession(
      id: 's-1',
      startedAt: DateTime(2025, 6, 10),
    ).copyWith(completedAt: DateTime(2025, 6, 10, 11, 0));
    await sessionRepo.create(completed);
    await sessionRepo.create(
      makeSession(id: 's-2', startedAt: DateTime(2025, 6, 12)),
    );

    final count = await sessionRepo.countByDateRange(
      DateTime(2025, 6, 1),
      DateTime(2025, 6, 30),
    );
    expect(count, 1);
  });

  test('empty state', () async {
    expect(await sessionRepo.getAll(), isEmpty);
    expect(await sessionRepo.getActiveSession(), isNull);
  });
}
