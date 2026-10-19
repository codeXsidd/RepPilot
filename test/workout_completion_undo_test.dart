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

import 'helpers/test_database.dart';

void main() {
  late Database db;
  late WorkoutSessionRepository sessionRepo;
  late WorkoutSetRepository setRepo;
  late RoutineRepository routineRepo;
  late ExerciseRepository exerciseRepo;
  final now = DateTime(2026, 10, 17, 10, 0);

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

  Future<void> seed() async {
    await routineRepo.create(
      Routine(id: 'r-push', name: 'Push Day', createdAt: now, updatedAt: now),
    );
    await routineRepo.create(
      Routine(id: 'r-pull', name: 'Pull Day', createdAt: now, updatedAt: now),
    );
    await exerciseRepo.create(
      Exercise(
        id: 'ex-bench',
        name: 'Bench Press',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await exerciseRepo.create(
      Exercise(
        id: 'ex-row',
        name: 'Barbell Row',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  WorkoutSession makeSession({
    String id = 's-1',
    String routineId = 'r-push',
    String routineName = 'Push Day',
    DateTime? startedAt,
    String? plannedDate,
  }) => WorkoutSession(
    id: id,
    routineId: routineId,
    routineName: routineName,
    startedAt: startedAt ?? now,
    plannedDate: plannedDate,
    createdAt: now,
    updatedAt: now,
  );

  List<WorkoutSet> makeSets(
    String sessionId, {
    String exerciseId = 'ex-bench',
  }) => [
    WorkoutSet(
      id: '$sessionId-ws-1',
      sessionId: sessionId,
      exerciseId: exerciseId,
      exerciseName: exerciseId == 'ex-bench' ? 'Bench Press' : 'Barbell Row',
      setNumber: 1,
      reps: 10,
      weightKg: 60,
      completed: true,
      completedAt: now,
    ),
    WorkoutSet(
      id: '$sessionId-ws-2',
      sessionId: sessionId,
      exerciseId: exerciseId,
      exerciseName: exerciseId == 'ex-bench' ? 'Bench Press' : 'Barbell Row',
      setNumber: 2,
      reps: 8,
      weightKg: 60,
      completed: true,
      completedAt: now,
    ),
  ];

  group('Completing a workout saves its status', () {
    test('finishWorkout marks session as completed', () async {
      await seed();
      final session = makeSession(plannedDate: '2026-10-17');
      await sessionRepo.createWithSets(session, makeSets('s-1'));

      final completed = await sessionRepo.completeIfActive('s-1');
      expect(completed, isNotNull);
      expect(completed!.isActive, false);
      expect(completed.completedAt, isNotNull);
    });

    test('incomplete workout remains incomplete', () async {
      await seed();
      final session = makeSession(plannedDate: '2026-10-17');
      await sessionRepo.create(session);

      final fetched = await sessionRepo.getById('s-1');
      expect(fetched!.isActive, true);
      expect(fetched.completedAt, isNull);
    });

    test('completion persists after re-query', () async {
      await seed();
      final session = makeSession(plannedDate: '2026-10-17');
      await sessionRepo.createWithSets(session, makeSets('s-1'));
      await sessionRepo.completeIfActive('s-1');

      final fetched = await sessionRepo.getById('s-1');
      expect(fetched!.isActive, false);
      expect(fetched.completedAt, isNotNull);
    });

    test('rapid repeated completions do not create duplicates', () async {
      await seed();
      final session = makeSession(plannedDate: '2026-10-17');
      await sessionRepo.createWithSets(session, makeSets('s-1'));

      final r1 = await sessionRepo.completeIfActive('s-1');
      final r2 = await sessionRepo.completeIfActive('s-1');
      final r3 = await sessionRepo.completeIfActive('s-1');

      expect(r1!.completedAt, r2!.completedAt);
      expect(r2.completedAt, r3!.completedAt);

      final allForDate = await sessionRepo.getForPlannedDate('2026-10-17');
      expect(allForDate.length, 1);
    });
  });

  group('Completion is date-specific', () {
    test(
      'completion today does not block same routine on another date',
      () async {
        await seed();
        await sessionRepo.createWithSets(
          makeSession(id: 's-today', plannedDate: '2026-10-17'),
          makeSets('s-today'),
        );
        await sessionRepo.completeIfActive('s-today');

        final tomorrow = await sessionRepo.getForRoutineDate(
          'r-push',
          '2026-10-18',
        );
        expect(tomorrow, isNull);

        final newSession = makeSession(
          id: 's-tomorrow',
          plannedDate: '2026-10-18',
        );
        await sessionRepo.create(newSession);
        final fetched = await sessionRepo.getForRoutineDate(
          'r-push',
          '2026-10-18',
        );
        expect(fetched, isNotNull);
        expect(fetched!.isActive, true);
      },
    );

    test('different routines have independent completion states', () async {
      await seed();
      await sessionRepo.createWithSets(
        makeSession(
          id: 's-push',
          routineId: 'r-push',
          routineName: 'Push Day',
          plannedDate: '2026-10-17',
        ),
        makeSets('s-push'),
      );
      await sessionRepo.createWithSets(
        makeSession(
          id: 's-pull',
          routineId: 'r-pull',
          routineName: 'Pull Day',
          plannedDate: '2026-10-17',
        ),
        makeSets('s-pull', exerciseId: 'ex-row'),
      );

      await sessionRepo.completeIfActive('s-push');

      final push = await sessionRepo.getForRoutineDate('r-push', '2026-10-17');
      final pull = await sessionRepo.getForRoutineDate('r-pull', '2026-10-17');
      expect(push!.isActive, false);
      expect(pull!.isActive, true);
    });
  });

  group('Undo completion', () {
    test('undo changes routine back to active for correct date', () async {
      await seed();
      final session = makeSession(plannedDate: '2026-10-17');
      await sessionRepo.createWithSets(session, makeSets('s-1'));
      await sessionRepo.completeIfActive('s-1');

      await sessionRepo.uncomplete('s-1');
      final fetched = await sessionRepo.getById('s-1');
      expect(fetched!.isActive, true);
      expect(fetched.completedAt, isNull);
    });

    test('undo preserves logged sets', () async {
      await seed();
      final session = makeSession(plannedDate: '2026-10-17');
      await sessionRepo.createWithSets(session, makeSets('s-1'));
      await sessionRepo.completeIfActive('s-1');
      await sessionRepo.uncomplete('s-1');

      final sets = await setRepo.getBySessionId('s-1');
      expect(sets.length, 2);
      expect(sets.first.reps, 10);
      expect(sets.first.weightKg, 60);
    });

    test('undoing one routine does not affect another routine', () async {
      await seed();
      await sessionRepo.createWithSets(
        makeSession(
          id: 's-push',
          routineId: 'r-push',
          routineName: 'Push Day',
          plannedDate: '2026-10-17',
        ),
        makeSets('s-push'),
      );
      await sessionRepo.createWithSets(
        makeSession(
          id: 's-pull',
          routineId: 'r-pull',
          routineName: 'Pull Day',
          plannedDate: '2026-10-17',
        ),
        makeSets('s-pull', exerciseId: 'ex-row'),
      );

      await sessionRepo.completeIfActive('s-push');
      await sessionRepo.completeIfActive('s-pull');

      await sessionRepo.uncomplete('s-push');

      final push = await sessionRepo.getForRoutineDate('r-push', '2026-10-17');
      final pull = await sessionRepo.getForRoutineDate('r-pull', '2026-10-17');
      expect(push!.isActive, true);
      expect(pull!.isActive, false);
    });

    test('double undo is safe (no error on already-active session)', () async {
      await seed();
      final session = makeSession(plannedDate: '2026-10-17');
      await sessionRepo.createWithSets(session, makeSets('s-1'));
      await sessionRepo.completeIfActive('s-1');

      await sessionRepo.uncomplete('s-1');
      await sessionRepo.uncomplete('s-1');

      final fetched = await sessionRepo.getById('s-1');
      expect(fetched!.isActive, true);
    });

    test('undo updates getForPlannedDate results', () async {
      await seed();
      final session = makeSession(plannedDate: '2026-10-17');
      await sessionRepo.createWithSets(session, makeSets('s-1'));
      await sessionRepo.completeIfActive('s-1');

      var sessions = await sessionRepo.getForPlannedDate('2026-10-17');
      expect(sessions.first.isActive, false);

      await sessionRepo.uncomplete('s-1');

      sessions = await sessionRepo.getForPlannedDate('2026-10-17');
      expect(sessions.first.isActive, true);
    });

    test('undo updates countByDateRange', () async {
      await seed();
      final session = makeSession(
        plannedDate: '2026-10-17',
        startedAt: DateTime(2026, 10, 17, 10, 0),
      );
      await sessionRepo.createWithSets(session, makeSets('s-1'));
      await sessionRepo.completeIfActive('s-1');

      final start = DateTime(2026, 10, 17);
      final end = DateTime(2026, 10, 17, 23, 59, 59);
      var count = await sessionRepo.countByDateRange(start, end);
      expect(count, 1);

      await sessionRepo.uncomplete('s-1');
      count = await sessionRepo.countByDateRange(start, end);
      expect(count, 0);
    });
  });

  group('Rest timer removal (data layer)', () {
    test('completing a set does not require rest timer interaction', () async {
      await seed();
      final session = makeSession(plannedDate: '2026-10-17');
      await sessionRepo.createWithSets(session, makeSets('s-1'));

      final sets = await setRepo.getBySessionId('s-1');
      expect(sets.first.completed, true);

      final updated = sets.first.copyWith(completed: false);
      await setRepo.update(updated);

      final refetched = await setRepo.getBySessionId('s-1');
      expect(refetched.first.completed, false);

      final reCompleted = refetched.first.copyWith(
        completed: true,
        completedAt: DateTime.now(),
      );
      await setRepo.update(reCompleted);
      final final_ = await setRepo.getBySessionId('s-1');
      expect(final_.first.completed, true);
    });

    test('completing a set allows logging the next set', () async {
      await seed();
      final session = makeSession(plannedDate: '2026-10-17');
      await sessionRepo.createWithSets(session, makeSets('s-1'));

      final sets = await setRepo.getBySessionId('s-1');
      expect(sets.length, 2);

      final set1 = sets[0].copyWith(completed: true, completedAt: now);
      await setRepo.update(set1);

      final set2 = sets[1].copyWith(
        completed: true,
        completedAt: now.add(const Duration(seconds: 30)),
      );
      await setRepo.update(set2);

      final updatedSets = await setRepo.getBySessionId('s-1');
      expect(updatedSets.where((s) => s.completed).length, 2);
    });
  });
}
