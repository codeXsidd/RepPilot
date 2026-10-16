import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:rep_pilot/models/exercise.dart';
import 'package:rep_pilot/models/routine.dart';
import 'package:rep_pilot/models/routine_exercise.dart';
import 'package:rep_pilot/repositories/exercise_repository.dart';
import 'package:rep_pilot/repositories/routine_exercise_repository.dart';
import 'package:rep_pilot/repositories/routine_repository.dart';
import 'package:rep_pilot/repositories/workout_session_repository.dart';
import 'package:rep_pilot/repositories/workout_set_repository.dart';
import 'package:rep_pilot/services/active_workout_service.dart';

import 'helpers/test_database.dart';

void main() {
  late Database db;
  late ExerciseRepository exerciseRepo;
  late RoutineRepository routineRepo;
  late RoutineExerciseRepository reRepo;
  late WorkoutSessionRepository sessionRepo;
  late WorkoutSetRepository setRepo;
  late ActiveWorkoutService service;
  final now = DateTime(2025, 7, 1, 9, 0);

  setUp(() async {
    db = await openTestDatabase();
    exerciseRepo = ExerciseRepository(db);
    routineRepo = RoutineRepository(db);
    reRepo = RoutineExerciseRepository(db);
    sessionRepo = WorkoutSessionRepository(db);
    setRepo = WorkoutSetRepository(db);
    service = ActiveWorkoutService();
  });

  tearDown(() async {
    service.dispose();
    await db.close();
  });

  Future<void> seedPushDay() async {
    await exerciseRepo.create(
      Exercise(
        id: 'ex-bench',
        name: 'Bench Press',
        category: 'chest',
        equipment: 'barbell',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await exerciseRepo.create(
      Exercise(
        id: 'ex-ohp',
        name: 'Overhead Press',
        category: 'shoulders',
        equipment: 'barbell',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await routineRepo.create(
      Routine(
        id: 'r-push',
        name: 'Push Day',
        dayOfWeek: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await reRepo.create(
      RoutineExercise(
        id: 're-1',
        routineId: 'r-push',
        exerciseId: 'ex-bench',
        targetSets: 3,
        targetReps: 10,
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
        routineId: 'r-push',
        exerciseId: 'ex-ohp',
        targetSets: 3,
        targetReps: 8,
        targetWeightKg: 50.0,
        restSeconds: 90,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  group('full workout lifecycle', () {
    test('start -> log sets -> finish -> verify history', () async {
      await seedPushDay();

      await service.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final sessionId = service.currentSession!.id;

      for (final s in service.sets) {
        await service.updateSet(setId: s.id, reps: 10, setRepo: setRepo);
        await service.completeSet(setId: s.id, setRepo: setRepo);
      }

      expect(service.completedSetCount, 6);
      expect(service.progressPercent, 1.0);

      final completed = await service.finishWorkout(sessionRepo: sessionRepo);
      expect(completed, isNotNull);
      expect(completed!.completedAt, isNotNull);

      final dbSession = await sessionRepo.getById(sessionId);
      expect(dbSession!.isActive, false);

      final dbSets = await setRepo.getBySessionId(sessionId);
      expect(dbSets.length, 6);
      expect(dbSets.every((s) => s.completed), true);
    });

    test('start -> partial completion -> cancel -> no history', () async {
      await seedPushDay();

      await service.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final sessionId = service.currentSession!.id;

      await service.completeSet(setId: service.sets.first.id, setRepo: setRepo);

      await service.cancelWorkout(sessionRepo: sessionRepo, setRepo: setRepo);

      expect(service.hasActiveSession, false);
      expect(await sessionRepo.getById(sessionId), isNull);
      expect(await setRepo.getBySessionId(sessionId), isEmpty);
    });
  });

  group('crash recovery simulation', () {
    test('session persists after service state loss', () async {
      await seedPushDay();

      await service.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      await service.updateSet(
        setId: service.sets[0].id,
        reps: 12,
        weightKg: 85.0,
        setRepo: setRepo,
      );
      await service.completeSet(setId: service.sets[0].id, setRepo: setRepo);

      service.clearState();

      final service2 = ActiveWorkoutService();
      final resumed = await service2.resumeSession(
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      expect(resumed, true);
      expect(service2.hasActiveSession, true);
      expect(service2.sets.length, 6);

      final firstSet = service2.sets.firstWhere(
        (s) => s.exerciseId == 'ex-bench' && s.setNumber == 1,
      );
      expect(firstSet.reps, 12);
      expect(firstSet.weightKg, 85.0);
      expect(firstSet.completed, true);

      final secondSet = service2.sets.firstWhere(
        (s) => s.exerciseId == 'ex-bench' && s.setNumber == 2,
      );
      expect(secondSet.completed, false);

      service2.dispose();
    });

    test('each set update persists immediately', () async {
      await seedPushDay();

      await service.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final setId = service.sets[0].id;
      await service.updateSet(
        setId: setId,
        reps: 8,
        weightKg: 90.0,
        rpe: 9.0,
        setRepo: setRepo,
      );

      final dbSet = await setRepo.getById(setId);
      expect(dbSet!.reps, 8);
      expect(dbSet.weightKg, 90.0);
      expect(dbSet.rpe, 9.0);
    });
  });

  group('multiple sessions preserve history', () {
    test('finishing two workouts creates two history entries', () async {
      await seedPushDay();

      await service.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );
      await service.finishWorkout(sessionRepo: sessionRepo);

      await service.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );
      await service.finishWorkout(sessionRepo: sessionRepo);

      final sessions = await sessionRepo.getAll();
      final completed = sessions.where((s) => !s.isActive).toList();
      expect(completed.length, 2);
    });

    test('deleting routine preserves completed sessions', () async {
      await seedPushDay();

      await service.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );
      final sessionId = service.currentSession!.id;
      await service.finishWorkout(sessionRepo: sessionRepo);

      await routineRepo.delete('r-push');

      final session = await sessionRepo.getById(sessionId);
      expect(session, isNotNull);
      expect(session!.routineName, 'Push Day');
      expect(session.routineId, isNull);
    });
  });

  group('standalone workout with dynamic exercises', () {
    test('start empty -> add exercises -> complete -> finish', () async {
      await exerciseRepo.create(
        Exercise(id: 'ex-sq', name: 'Squat', createdAt: now, updatedAt: now),
      );

      await service.startStandalone(name: 'Leg Day', sessionRepo: sessionRepo);

      expect(service.sets, isEmpty);

      await service.addExerciseSets(
        exerciseId: 'ex-sq',
        exerciseName: 'Squat',
        count: 5,
        weightKg: 100.0,
        setRepo: setRepo,
      );

      expect(service.sets.length, 5);
      expect(service.exerciseOrder, ['ex-sq']);

      for (final s in service.sets) {
        await service.updateSet(setId: s.id, reps: 5, setRepo: setRepo);
        await service.completeSet(setId: s.id, setRepo: setRepo);
      }

      final completed = await service.finishWorkout(sessionRepo: sessionRepo);
      expect(completed, isNotNull);
      expect(completed!.routineName, 'Leg Day');
    });
  });

  group('mixed warmup and working sets', () {
    test('warmup sets tracked separately in progress', () async {
      await seedPushDay();

      await service.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      await service.updateSet(
        setId: service.sets[0].id,
        isWarmup: true,
        setRepo: setRepo,
      );

      expect(service.totalSetCount, 5);

      await service.completeSet(setId: service.sets[0].id, setRepo: setRepo);

      expect(service.completedSetCount, 0);

      await service.completeSet(setId: service.sets[1].id, setRepo: setRepo);

      expect(service.completedSetCount, 1);
    });
  });

  group('set operations edge cases', () {
    test('add set copies weight from previous set', () async {
      await seedPushDay();

      await service.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      await service.updateSet(
        setId: service.setsForExercise('ex-bench').last.id,
        weightKg: 90.0,
        setRepo: setRepo,
      );

      await service.addSet(exerciseId: 'ex-bench', setRepo: setRepo);

      final newSet = service.setsForExercise('ex-bench').last;
      expect(newSet.weightKg, 90.0);
      expect(newSet.setNumber, 4);
    });

    test('remove and re-add maintains correct numbering', () async {
      await seedPushDay();

      await service.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final benchSets = service.setsForExercise('ex-bench');
      await service.removeSet(setId: benchSets[1].id, setRepo: setRepo);

      await service.addSet(exerciseId: 'ex-bench', setRepo: setRepo);

      final updatedSets = service.setsForExercise('ex-bench');
      expect(updatedSets.length, 3);
      expect(updatedSets[0].setNumber, 1);
      expect(updatedSets[1].setNumber, 2);
      expect(updatedSets[2].setNumber, 3);
    });
  });

  group('session summary data', () {
    test('completed session has all data for summary', () async {
      await seedPushDay();

      await service.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final sessionId = service.currentSession!.id;

      for (final s in service.sets) {
        await service.updateSet(setId: s.id, reps: 10, setRepo: setRepo);
        await service.completeSet(setId: s.id, setRepo: setRepo);
      }

      await service.finishWorkout(sessionRepo: sessionRepo);

      final session = await sessionRepo.getById(sessionId);
      expect(session!.completedAt, isNotNull);
      expect(session.routineName, 'Push Day');
      expect(session.duration, isNotNull);
      expect(session.duration!.inSeconds, greaterThanOrEqualTo(0));

      final sets = await setRepo.getBySessionId(sessionId);
      expect(sets.length, 6);

      final volume = sets.fold<double>(
        0,
        (sum, s) => sum + ((s.weightKg ?? 0) * (s.reps ?? 0)),
      );
      expect(volume, greaterThan(0));
    });
  });
}
