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

import '../helpers/test_database.dart';

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

  Future<void> seedRoutineWithExercises() async {
    await exerciseRepo.create(
      Exercise(id: 'ex-1', name: 'Bench Press', createdAt: now, updatedAt: now),
    );
    await exerciseRepo.create(
      Exercise(
        id: 'ex-2',
        name: 'Overhead Press',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await routineRepo.create(
      Routine(id: 'r-1', name: 'Push Day', createdAt: now, updatedAt: now),
    );
    await reRepo.create(
      RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'ex-1',
        targetSets: 3,
        targetReps: 10,
        targetWeightKg: 60.0,
        restSeconds: 90,
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
        targetReps: 8,
        targetWeightKg: 40.0,
        restSeconds: 60,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  group('startFromRoutine', () {
    test('creates session and sets from routine template', () async {
      await seedRoutineWithExercises();

      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      expect(service.hasActiveSession, true);
      expect(service.currentSession, isNotNull);
      expect(service.currentSession!.routineName, 'Push Day');
      expect(service.sets.length, 6);
      expect(service.exerciseOrder, ['ex-1', 'ex-2']);
      expect(service.lastError, isNull);
    });

    test('sets have correct exercise data', () async {
      await seedRoutineWithExercises();

      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final benchSets = service.setsForExercise('ex-1');
      expect(benchSets.length, 3);
      expect(benchSets[0].weightKg, 60.0);
      expect(benchSets[0].exerciseName, 'Bench Press');
      expect(benchSets[0].setNumber, 1);
      expect(benchSets[2].setNumber, 3);

      final ohpSets = service.setsForExercise('ex-2');
      expect(ohpSets.length, 3);
      expect(ohpSets[0].weightKg, 40.0);
    });

    test('persists session and sets to database', () async {
      await seedRoutineWithExercises();

      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final dbSession = await sessionRepo.getById(service.currentSession!.id);
      expect(dbSession, isNotNull);
      expect(dbSession!.isActive, true);

      final dbSets = await setRepo.getBySessionId(dbSession.id);
      expect(dbSets.length, 6);
    });

    test('sets error for nonexistent routine', () async {
      await service.startFromRoutine(
        routineId: 'nonexistent',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      expect(service.hasActiveSession, false);
      expect(service.lastError, 'Routine not found');
    });
  });

  group('startStandalone', () {
    test('creates empty session', () async {
      await service.startStandalone(
        name: 'Quick Workout',
        sessionRepo: sessionRepo,
      );

      expect(service.hasActiveSession, true);
      expect(service.currentSession!.routineName, 'Quick Workout');
      expect(service.currentSession!.routineId, isNull);
      expect(service.sets, isEmpty);
      expect(service.exerciseOrder, isEmpty);
    });

    test('persists standalone session to database', () async {
      await service.startStandalone(
        name: 'Evening Session',
        sessionRepo: sessionRepo,
      );

      final dbSession = await sessionRepo.getActiveSession();
      expect(dbSession, isNotNull);
      expect(dbSession!.routineName, 'Evening Session');
    });
  });

  group('completeSet and uncompleteSet', () {
    test('completing a set updates state and database', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final setId = service.sets.first.id;
      await service.completeSet(setId: setId, setRepo: setRepo);

      expect(service.sets.first.completed, true);
      expect(service.sets.first.completedAt, isNotNull);

      final dbSet = await setRepo.getById(setId);
      expect(dbSet!.completed, true);
    });

    test('uncompleting a set clears completion', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final setId = service.sets.first.id;
      await service.completeSet(setId: setId, setRepo: setRepo);
      await service.uncompleteSet(setId: setId, setRepo: setRepo);

      expect(service.sets.first.completed, false);
      expect(service.sets.first.completedAt, isNull);
    });

    test('completedSetCount and progressPercent track correctly', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      expect(service.completedSetCount, 0);
      expect(service.progressPercent, 0.0);
      expect(service.totalSetCount, 6);

      await service.completeSet(setId: service.sets[0].id, setRepo: setRepo);
      await service.completeSet(setId: service.sets[1].id, setRepo: setRepo);
      await service.completeSet(setId: service.sets[2].id, setRepo: setRepo);

      expect(service.completedSetCount, 3);
      expect(service.progressPercent, closeTo(0.5, 0.01));
    });
  });

  group('updateSet', () {
    test('updates weight without affecting reps', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final setId = service.sets.first.id;
      final originalReps = service.sets.first.reps;

      await service.updateSet(setId: setId, weightKg: 80.0, setRepo: setRepo);

      expect(service.sets.first.weightKg, 80.0);
      expect(service.sets.first.reps, originalReps);
    });

    test('updates reps without affecting weight', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final setId = service.sets.first.id;
      final originalWeight = service.sets.first.weightKg;

      await service.updateSet(setId: setId, reps: 12, setRepo: setRepo);

      expect(service.sets.first.reps, 12);
      expect(service.sets.first.weightKg, originalWeight);
    });

    test('updates RPE independently', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final setId = service.sets.first.id;
      await service.updateSet(setId: setId, rpe: 8.5, setRepo: setRepo);

      expect(service.sets.first.rpe, 8.5);
      expect(service.sets.first.weightKg, 60.0);
      expect(service.sets.first.reps, 10);
    });

    test('updates warmup flag independently', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final setId = service.sets.first.id;
      await service.updateSet(setId: setId, isWarmup: true, setRepo: setRepo);

      expect(service.sets.first.isWarmup, true);
      expect(service.sets.first.weightKg, 60.0);
    });

    test('persists update to database', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final setId = service.sets.first.id;
      await service.updateSet(
        setId: setId,
        reps: 15,
        weightKg: 70.0,
        setRepo: setRepo,
      );

      final dbSet = await setRepo.getById(setId);
      expect(dbSet!.reps, 15);
      expect(dbSet.weightKg, 70.0);
    });

    test('ignores nonexistent set id', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      await service.updateSet(setId: 'nonexistent', reps: 99, setRepo: setRepo);

      expect(service.lastError, isNull);
    });

    test('can explicitly clear a nullable field', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final setId = service.sets.first.id;
      expect(service.sets.first.weightKg, 60.0);

      await service.updateSet(setId: setId, weightKg: null, setRepo: setRepo);

      expect(service.sets.first.weightKg, isNull);
    });
  });

  group('addSet and removeSet', () {
    test('addSet appends a set for exercise', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      expect(service.setsForExercise('ex-1').length, 3);

      await service.addSet(exerciseId: 'ex-1', setRepo: setRepo);

      final benchSets = service.setsForExercise('ex-1');
      expect(benchSets.length, 4);
      expect(benchSets.last.setNumber, 4);
      expect(benchSets.last.weightKg, 60.0);
    });

    test('addSet persists to database', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      await service.addSet(exerciseId: 'ex-1', setRepo: setRepo);

      final dbSets = await setRepo.getBySessionId(service.currentSession!.id);
      expect(dbSets.length, 7);
    });

    test('removeSet deletes and renumbers', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final secondSetId = service.setsForExercise('ex-1')[1].id;
      await service.removeSet(setId: secondSetId, setRepo: setRepo);

      final benchSets = service.setsForExercise('ex-1');
      expect(benchSets.length, 2);
      expect(benchSets[0].setNumber, 1);
      expect(benchSets[1].setNumber, 2);
    });

    test('removing all sets for exercise removes from exerciseOrder', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final ohpSets = service.setsForExercise('ex-2');
      for (final s in ohpSets) {
        await service.removeSet(setId: s.id, setRepo: setRepo);
      }

      expect(service.exerciseOrder, ['ex-1']);
      expect(service.setsForExercise('ex-2'), isEmpty);
    });
  });

  group('addExerciseSets', () {
    test('adds new exercise to standalone session', () async {
      await exerciseRepo.create(
        Exercise(id: 'ex-1', name: 'Squat', createdAt: now, updatedAt: now),
      );

      await service.startStandalone(
        name: 'Quick Workout',
        sessionRepo: sessionRepo,
      );

      await service.addExerciseSets(
        exerciseId: 'ex-1',
        exerciseName: 'Squat',
        count: 4,
        weightKg: 100.0,
        setRepo: setRepo,
      );

      expect(service.exerciseOrder, ['ex-1']);
      expect(service.setsForExercise('ex-1').length, 4);
      expect(service.setsForExercise('ex-1').first.weightKg, 100.0);
    });
  });

  group('skipSet', () {
    test('marks set as completed with 0 reps', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final setId = service.sets.first.id;
      await service.skipSet(setId: setId, setRepo: setRepo);

      final skipped = service.sets.first;
      expect(skipped.completed, true);
      expect(skipped.reps, 0);
      expect(skipped.notes, 'Skipped');
    });
  });

  group('finishWorkout', () {
    test('completes the session and clears state', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final sessionId = service.currentSession!.id;
      final completed = await service.finishWorkout(sessionRepo: sessionRepo);

      expect(completed, isNotNull);
      expect(completed!.completedAt, isNotNull);
      expect(service.hasActiveSession, false);
      expect(service.sets, isEmpty);

      final dbSession = await sessionRepo.getById(sessionId);
      expect(dbSession!.isActive, false);
    });

    test('returns null and stays inactive when no session', () async {
      final result = await service.finishWorkout(sessionRepo: sessionRepo);
      expect(result, isNull);
    });

    test('prevents double finish via isFinishing flag', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final first = service.finishWorkout(sessionRepo: sessionRepo);
      final second = service.finishWorkout(sessionRepo: sessionRepo);

      final results = await Future.wait([first, second]);
      final nonNull = results.where((r) => r != null).toList();
      expect(nonNull.length, 1);
    });
  });

  group('cancelWorkout', () {
    test('deletes session and sets from database', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final sessionId = service.currentSession!.id;
      await service.cancelWorkout(sessionRepo: sessionRepo, setRepo: setRepo);

      expect(service.hasActiveSession, false);

      final dbSession = await sessionRepo.getById(sessionId);
      expect(dbSession, isNull);

      final dbSets = await setRepo.getBySessionId(sessionId);
      expect(dbSets, isEmpty);
    });
  });

  group('resumeSession', () {
    test('resumes an active session from database', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final sessionId = service.currentSession!.id;

      await service.completeSet(setId: service.sets.first.id, setRepo: setRepo);

      service.clearState();
      expect(service.hasActiveSession, false);

      final resumed = await service.resumeSession(
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      expect(resumed, true);
      expect(service.hasActiveSession, true);
      expect(service.currentSession!.id, sessionId);
      expect(service.sets.length, 6);
      expect(service.sets.first.completed, true);
    });

    test('returns false when no active session exists', () async {
      final resumed = await service.resumeSession(
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      expect(resumed, false);
      expect(service.hasActiveSession, false);
    });

    test('resumes after finish clears previous session', () async {
      await seedRoutineWithExercises();

      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      await service.finishWorkout(sessionRepo: sessionRepo);

      final resumed = await service.resumeSession(
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      expect(resumed, false);
    });
  });

  group('workoutDuration', () {
    test('returns zero when no session', () {
      expect(service.workoutDuration, Duration.zero);
    });

    test('returns duration for active session', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      expect(service.workoutDuration.inSeconds, greaterThanOrEqualTo(0));
    });
  });

  group('warmup sets excluded from counts', () {
    test('warmup sets do not count toward totalSetCount', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      expect(service.totalSetCount, 6);

      await service.updateSet(
        setId: service.sets[0].id,
        isWarmup: true,
        setRepo: setRepo,
      );

      expect(service.totalSetCount, 5);
    });

    test('warmup sets do not count toward completedSetCount', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
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
      await service.completeSet(setId: service.sets[0].id, setRepo: setRepo);

      expect(service.completedSetCount, 0);
    });
  });

  group('reorderExercises', () {
    test('changes exercise display order', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      expect(service.exerciseOrder, ['ex-1', 'ex-2']);

      service.reorderExercises(['ex-2', 'ex-1']);

      expect(service.exerciseOrder, ['ex-2', 'ex-1']);
    });
  });

  group('previousPerformance', () {
    test('loads previous sets for exercises', () async {
      await seedRoutineWithExercises();

      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      await service.completeSet(setId: service.sets[0].id, setRepo: setRepo);
      await service.finishWorkout(sessionRepo: sessionRepo);

      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      expect(service.previousSets['ex-1'], isNotNull);
      expect(service.previousSets['ex-1']!.isNotEmpty, true);
    });
  });

  group('clearState', () {
    test('resets all service state', () async {
      await seedRoutineWithExercises();
      await service.startFromRoutine(
        routineId: 'r-1',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      service.clearState();

      expect(service.hasActiveSession, false);
      expect(service.sets, isEmpty);
      expect(service.exerciseOrder, isEmpty);
      expect(service.previousSets, isEmpty);
      expect(service.lastError, isNull);
      expect(service.isSaving, false);
      expect(service.isFinishing, false);
    });
  });
}
