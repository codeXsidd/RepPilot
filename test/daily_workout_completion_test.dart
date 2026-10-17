import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:rep_pilot/core/constants.dart';
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
      Routine(id: 'r-1', name: 'Push Day', createdAt: now, updatedAt: now),
    );
    await routineRepo.create(
      Routine(id: 'r-2', name: 'Pull Day', createdAt: now, updatedAt: now),
    );
    await exerciseRepo.create(
      Exercise(id: 'ex-1', name: 'Bench Press', createdAt: now, updatedAt: now),
    );
  }

  WorkoutSession makeSession({
    String id = 's-1',
    String? routineId = 'r-1',
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

  List<WorkoutSet> makeSets(String sessionId) => [
    WorkoutSet(
      id: '$sessionId-ws-1',
      sessionId: sessionId,
      exerciseId: 'ex-1',
      exerciseName: 'Bench Press',
      setNumber: 1,
      reps: 10,
      weightKg: 60,
    ),
    WorkoutSet(
      id: '$sessionId-ws-2',
      sessionId: sessionId,
      exerciseId: 'ex-1',
      exerciseName: 'Bench Press',
      setNumber: 2,
      reps: 8,
      weightKg: 60,
    ),
  ];

  group('planned_date column', () {
    test('WorkoutSession stores and retrieves plannedDate', () async {
      await seed();
      final session = makeSession(plannedDate: '2026-10-17');
      await sessionRepo.create(session);
      final fetched = await sessionRepo.getById('s-1');
      expect(fetched, isNotNull);
      expect(fetched!.plannedDate, '2026-10-17');
    });

    test('plannedDate defaults to null', () async {
      await seed();
      final session = makeSession();
      await sessionRepo.create(session);
      final fetched = await sessionRepo.getById('s-1');
      expect(fetched!.plannedDate, isNull);
    });
  });

  group('getForRoutineDate', () {
    test('returns session matching routine and date', () async {
      await seed();
      final session = makeSession(plannedDate: '2026-10-17');
      await sessionRepo.create(session);
      final found = await sessionRepo.getForRoutineDate('r-1', '2026-10-17');
      expect(found, isNotNull);
      expect(found!.id, 's-1');
    });

    test('returns null when no match', () async {
      await seed();
      final found = await sessionRepo.getForRoutineDate('r-1', '2026-10-17');
      expect(found, isNull);
    });

    test('distinguishes different dates', () async {
      await seed();
      await sessionRepo.create(
        makeSession(id: 's-1', plannedDate: '2026-10-17'),
      );
      await sessionRepo.create(
        makeSession(id: 's-2', plannedDate: '2026-10-18'),
      );

      final d17 = await sessionRepo.getForRoutineDate('r-1', '2026-10-17');
      final d18 = await sessionRepo.getForRoutineDate('r-1', '2026-10-18');
      expect(d17!.id, 's-1');
      expect(d18!.id, 's-2');
    });

    test('distinguishes different routines on same date', () async {
      await seed();
      await sessionRepo.create(
        makeSession(
          id: 's-1',
          routineId: 'r-1',
          routineName: 'Push Day',
          plannedDate: '2026-10-17',
        ),
      );
      await sessionRepo.create(
        makeSession(
          id: 's-2',
          routineId: 'r-2',
          routineName: 'Pull Day',
          plannedDate: '2026-10-17',
        ),
      );

      final push = await sessionRepo.getForRoutineDate('r-1', '2026-10-17');
      final pull = await sessionRepo.getForRoutineDate('r-2', '2026-10-17');
      expect(push!.id, 's-1');
      expect(pull!.id, 's-2');
    });
  });

  group('getForPlannedDate', () {
    test('returns all sessions for a date', () async {
      await seed();
      await sessionRepo.create(
        makeSession(id: 's-1', routineId: 'r-1', plannedDate: '2026-10-17'),
      );
      await sessionRepo.create(
        makeSession(
          id: 's-2',
          routineId: 'r-2',
          routineName: 'Pull Day',
          plannedDate: '2026-10-17',
        ),
      );

      final sessions = await sessionRepo.getForPlannedDate('2026-10-17');
      expect(sessions.length, 2);
    });

    test('returns empty for date with no sessions', () async {
      final sessions = await sessionRepo.getForPlannedDate('2026-10-17');
      expect(sessions, isEmpty);
    });
  });

  group('getOrCreateForRoutine (duplicate prevention)', () {
    test('creates new session when none exists', () async {
      await seed();
      final session = makeSession(plannedDate: '2026-10-17');
      final result = await sessionRepo.getOrCreateForRoutine(
        session: session,
        sets: makeSets('s-1'),
      );
      expect(result.id, 's-1');

      final sets = await setRepo.getBySessionId('s-1');
      expect(sets.length, 2);
    });

    test('returns existing session without creating duplicate', () async {
      await seed();
      final session1 = makeSession(id: 's-1', plannedDate: '2026-10-17');
      await sessionRepo.getOrCreateForRoutine(
        session: session1,
        sets: makeSets('s-1'),
      );

      final session2 = makeSession(id: 's-2', plannedDate: '2026-10-17');
      final result = await sessionRepo.getOrCreateForRoutine(
        session: session2,
        sets: makeSets('s-2'),
      );
      expect(result.id, 's-1');

      final sets2 = await setRepo.getBySessionId('s-2');
      expect(sets2, isEmpty);
    });

    test('allows same routine on different dates', () async {
      await seed();
      final s1 = makeSession(id: 's-1', plannedDate: '2026-10-17');
      final s2 = makeSession(id: 's-2', plannedDate: '2026-10-18');

      final r1 = await sessionRepo.getOrCreateForRoutine(
        session: s1,
        sets: makeSets('s-1'),
      );
      final r2 = await sessionRepo.getOrCreateForRoutine(
        session: s2,
        sets: makeSets('s-2'),
      );

      expect(r1.id, 's-1');
      expect(r2.id, 's-2');
    });

    test('allows different routines on same date', () async {
      await seed();
      final s1 = makeSession(
        id: 's-1',
        routineId: 'r-1',
        plannedDate: '2026-10-17',
      );
      final s2 = makeSession(
        id: 's-2',
        routineId: 'r-2',
        routineName: 'Pull Day',
        plannedDate: '2026-10-17',
      );

      final r1 = await sessionRepo.getOrCreateForRoutine(
        session: s1,
        sets: makeSets('s-1'),
      );
      final r2 = await sessionRepo.getOrCreateForRoutine(
        session: s2,
        sets: makeSets('s-2'),
      );

      expect(r1.id, 's-1');
      expect(r2.id, 's-2');
    });
  });

  group('unique index enforcement', () {
    test('rejects duplicate routine+date via direct insert', () async {
      await seed();
      await sessionRepo.create(
        makeSession(id: 's-1', plannedDate: '2026-10-17'),
      );

      expect(
        () => sessionRepo.create(
          makeSession(id: 's-dup', plannedDate: '2026-10-17'),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('allows null plannedDate without conflict', () async {
      await seed();
      await sessionRepo.create(makeSession(id: 's-1'));
      await sessionRepo.create(makeSession(id: 's-2'));

      final all = await sessionRepo.getAll();
      expect(all.length, 2);
    });
  });

  group('completeIfActive (idempotent completion)', () {
    test('marks active session as completed', () async {
      await seed();
      await sessionRepo.create(makeSession(plannedDate: '2026-10-17'));

      final result = await sessionRepo.completeIfActive('s-1');
      expect(result, isNotNull);
      expect(result!.isActive, false);
      expect(result.completedAt, isNotNull);
    });

    test('returns already-completed session without error', () async {
      await seed();
      await sessionRepo.create(makeSession(plannedDate: '2026-10-17'));

      final first = await sessionRepo.completeIfActive('s-1');
      expect(first!.isActive, false);

      final second = await sessionRepo.completeIfActive('s-1');
      expect(second, isNotNull);
      expect(second!.isActive, false);
    });

    test('returns null for nonexistent session', () async {
      final result = await sessionRepo.completeIfActive('nonexistent');
      expect(result, isNull);
    });

    test('does not change completedAt on second call', () async {
      await seed();
      await sessionRepo.create(makeSession(plannedDate: '2026-10-17'));

      final first = await sessionRepo.completeIfActive('s-1');
      final firstTime = first!.completedAt;

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final second = await sessionRepo.completeIfActive('s-1');
      expect(second!.completedAt, firstTime);
    });
  });

  group('uncomplete', () {
    test('clears completedAt', () async {
      await seed();
      await sessionRepo.create(makeSession(plannedDate: '2026-10-17'));
      await sessionRepo.completeIfActive('s-1');

      await sessionRepo.uncomplete('s-1');
      final fetched = await sessionRepo.getById('s-1');
      expect(fetched!.isActive, true);
      expect(fetched.completedAt, isNull);
    });

    test('preserves workout sets after uncompleting', () async {
      await seed();
      final session = makeSession(plannedDate: '2026-10-17');
      await sessionRepo.createWithSets(session, makeSets('s-1'));
      await sessionRepo.completeIfActive('s-1');
      await sessionRepo.uncomplete('s-1');

      final sets = await setRepo.getBySessionId('s-1');
      expect(sets.length, 2);
    });
  });

  group('WorkoutSession model', () {
    test('toMap/fromMap round-trips plannedDate', () {
      final session = makeSession(plannedDate: '2026-10-17');
      final map = session.toMap();
      final restored = WorkoutSession.fromMap(map);
      expect(restored.plannedDate, '2026-10-17');
    });

    test('copyWith can set plannedDate', () {
      final session = makeSession();
      expect(session.plannedDate, isNull);
      final updated = session.copyWith(plannedDate: '2026-10-17');
      expect(updated.plannedDate, '2026-10-17');
    });

    test('copyWith can clear plannedDate', () {
      final session = makeSession(plannedDate: '2026-10-17');
      final cleared = session.copyWith(plannedDate: null);
      expect(cleared.plannedDate, isNull);
    });

    test('isActive reflects completedAt correctly', () {
      final active = makeSession();
      expect(active.isActive, true);

      final completed = active.copyWith(completedAt: now);
      expect(completed.isActive, false);
    });

    test('equality includes plannedDate', () {
      final s1 = makeSession(plannedDate: '2026-10-17');
      final s2 = makeSession(plannedDate: '2026-10-18');
      expect(s1 == s2, false);

      final s3 = makeSession(plannedDate: '2026-10-17');
      expect(s1 == s3, true);
    });
  });

  group('formatDateOnly', () {
    test('produces YYYY-MM-DD', () {
      expect(formatDateOnly(DateTime(2026, 10, 17)), '2026-10-17');
      expect(formatDateOnly(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('ignores time component', () {
      final morning = formatDateOnly(DateTime(2026, 10, 17, 0, 0, 1));
      final evening = formatDateOnly(DateTime(2026, 10, 17, 23, 59, 59));
      expect(morning, evening);
    });
  });

  group('completion persistence', () {
    test('completed session survives reopen', () async {
      await seed();
      await sessionRepo.create(makeSession(plannedDate: '2026-10-17'));
      await sessionRepo.completeIfActive('s-1');

      final fetched = await sessionRepo.getById('s-1');
      expect(fetched!.isActive, false);
      expect(fetched.completedAt, isNotNull);
    });

    test('sets preserved with completed session', () async {
      await seed();
      final session = makeSession(plannedDate: '2026-10-17');
      await sessionRepo.createWithSets(session, makeSets('s-1'));
      await sessionRepo.completeIfActive('s-1');

      final sets = await setRepo.getBySessionId('s-1');
      expect(sets.length, 2);
      expect(sets.first.reps, 10);
    });
  });

  group('weekly schedule integration', () {
    test('getForPlannedDate works with week of sessions', () async {
      await seed();
      for (var i = 0; i < 5; i++) {
        final date = formatDateOnly(DateTime(2026, 10, 12 + i));
        await sessionRepo.create(makeSession(id: 's-$i', plannedDate: date));
      }

      final mon = await sessionRepo.getForPlannedDate('2026-10-12');
      final wed = await sessionRepo.getForPlannedDate('2026-10-14');
      final fri = await sessionRepo.getForPlannedDate('2026-10-16');
      final sat = await sessionRepo.getForPlannedDate('2026-10-17');

      expect(mon.length, 1);
      expect(wed.length, 1);
      expect(fri.length, 1);
      expect(sat.length, 0);
    });
  });
}
