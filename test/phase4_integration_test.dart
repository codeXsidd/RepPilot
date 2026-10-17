import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:rep_pilot/models/exercise.dart';
import 'package:rep_pilot/models/routine.dart';
import 'package:rep_pilot/models/routine_exercise.dart';
import 'package:rep_pilot/repositories/exercise_repository.dart';
import 'package:rep_pilot/repositories/exercise_settings_repository.dart';
import 'package:rep_pilot/repositories/overload_recommendation_repository.dart';
import 'package:rep_pilot/repositories/routine_exercise_repository.dart';
import 'package:rep_pilot/repositories/routine_repository.dart';
import 'package:rep_pilot/repositories/workout_session_repository.dart';
import 'package:rep_pilot/repositories/workout_set_repository.dart';
import 'package:rep_pilot/services/active_workout_service.dart';
import 'package:rep_pilot/services/overload_service.dart';

import 'helpers/test_database.dart';

void main() {
  late Database db;
  late ExerciseRepository exerciseRepo;
  late RoutineRepository routineRepo;
  late RoutineExerciseRepository reRepo;
  late WorkoutSessionRepository sessionRepo;
  late WorkoutSetRepository setRepo;
  late ExerciseSettingsRepository settingsRepo;
  late OverloadRecommendationRepository recRepo;
  late ActiveWorkoutService workoutService;
  late OverloadService overloadService;
  final now = DateTime(2025, 7, 1, 9, 0);

  setUp(() async {
    db = await openTestDatabase();
    exerciseRepo = ExerciseRepository(db);
    routineRepo = RoutineRepository(db);
    reRepo = RoutineExerciseRepository(db);
    sessionRepo = WorkoutSessionRepository(db);
    setRepo = WorkoutSetRepository(db);
    settingsRepo = ExerciseSettingsRepository(db);
    recRepo = OverloadRecommendationRepository(db);
    workoutService = ActiveWorkoutService();
    overloadService = OverloadService();
  });

  tearDown(() async {
    workoutService.dispose();
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

  group('finish workout generates recommendations', () {
    test(
      'completing all sets at max reps generates increase suggestion',
      () async {
        await seedPushDay();

        final benchSettings = await settingsRepo.getOrCreateForExercise(
          'ex-bench',
        );
        await settingsRepo.update(
          benchSettings.copyWith(minReps: 8, maxReps: 10),
        );

        await workoutService.startFromRoutine(
          routineId: 'r-push',
          routineRepo: routineRepo,
          reRepo: reRepo,
          exerciseRepo: exerciseRepo,
          sessionRepo: sessionRepo,
          setRepo: setRepo,
        );

        for (final s in workoutService.sets) {
          await workoutService.updateSet(
            setId: s.id,
            reps: s.exerciseId == 'ex-bench' ? 10 : 8,
            setRepo: setRepo,
          );
          await workoutService.completeSet(setId: s.id, setRepo: setRepo);
        }

        final completed = await workoutService.finishWorkout(
          sessionRepo: sessionRepo,
          overloadService: overloadService,
          settingsRepo: settingsRepo,
          setRepo: setRepo,
          recRepo: recRepo,
        );

        expect(completed, isNotNull);

        final recs = workoutService.lastRecommendations;
        expect(recs, isNotEmpty);

        final benchRec = recs.firstWhere((r) => r.exerciseId == 'ex-bench');
        expect(benchRec.recommendedWeightKg, 82.5);
        expect(benchRec.recommendedReps, 8);
        expect(benchRec.status, 'pending');

        final dbRecs = await recRepo.getByExerciseId('ex-bench');
        expect(dbRecs.length, 1);
        expect(dbRecs.first.id, benchRec.id);
      },
    );

    test(
      'finish without overload service produces no recommendations',
      () async {
        await seedPushDay();

        await workoutService.startFromRoutine(
          routineId: 'r-push',
          routineRepo: routineRepo,
          reRepo: reRepo,
          exerciseRepo: exerciseRepo,
          sessionRepo: sessionRepo,
          setRepo: setRepo,
        );

        for (final s in workoutService.sets) {
          await workoutService.completeSet(setId: s.id, setRepo: setRepo);
        }

        await workoutService.finishWorkout(sessionRepo: sessionRepo);

        expect(workoutService.lastRecommendations, isEmpty);
      },
    );
  });

  group('accepted recommendations apply to next workout', () {
    test('accepted weight increase pre-fills next session', () async {
      await seedPushDay();

      await settingsRepo.update(
        (await settingsRepo.getOrCreateForExercise('ex-bench'))
            .copyWith(minReps: 8, maxReps: 10),
      );

      await workoutService.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        plannedDate: '2025-07-01',
      );

      for (final s in workoutService.sets) {
        await workoutService.updateSet(
          setId: s.id,
          reps: s.exerciseId == 'ex-bench' ? 10 : 8,
          setRepo: setRepo,
        );
        await workoutService.completeSet(setId: s.id, setRepo: setRepo);
      }

      await workoutService.finishWorkout(
        sessionRepo: sessionRepo,
        overloadService: overloadService,
        settingsRepo: settingsRepo,
        setRepo: setRepo,
        recRepo: recRepo,
      );

      final benchRec = workoutService.lastRecommendations.firstWhere(
        (r) => r.exerciseId == 'ex-bench',
      );
      await overloadService.applyRecommendation(benchRec, recRepo);

      await workoutService.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        recRepo: recRepo,
        plannedDate: '2025-07-02',
      );

      final benchSets = workoutService.setsForExercise('ex-bench');
      expect(benchSets.length, 3);
      expect(benchSets.first.weightKg, 82.5);
      expect(benchSets.first.reps, 8);

      final ohpSets = workoutService.setsForExercise('ex-ohp');
      expect(ohpSets.first.weightKg, 50.0);
      expect(ohpSets.first.reps, 8);
    });

    test('dismissed recommendation does not apply', () async {
      await seedPushDay();

      await settingsRepo.update(
        (await settingsRepo.getOrCreateForExercise('ex-bench'))
            .copyWith(minReps: 8, maxReps: 10),
      );

      await workoutService.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      for (final s in workoutService.sets) {
        await workoutService.updateSet(setId: s.id, reps: 10, setRepo: setRepo);
        await workoutService.completeSet(setId: s.id, setRepo: setRepo);
      }

      await workoutService.finishWorkout(
        sessionRepo: sessionRepo,
        overloadService: overloadService,
        settingsRepo: settingsRepo,
        setRepo: setRepo,
        recRepo: recRepo,
      );

      final benchRec = workoutService.lastRecommendations.firstWhere(
        (r) => r.exerciseId == 'ex-bench',
      );
      await overloadService.dismissRecommendation(benchRec, recRepo);

      await workoutService.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        recRepo: recRepo,
      );

      final benchSets = workoutService.setsForExercise('ex-bench');
      expect(benchSets.first.weightKg, 80.0);
      expect(benchSets.first.reps, 10);
    });

    test('edited recommendation applies custom values', () async {
      await seedPushDay();

      await settingsRepo.update(
        (await settingsRepo.getOrCreateForExercise('ex-bench'))
            .copyWith(minReps: 8, maxReps: 10),
      );

      await workoutService.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        plannedDate: '2025-07-01',
      );

      for (final s in workoutService.sets) {
        await workoutService.updateSet(setId: s.id, reps: 10, setRepo: setRepo);
        await workoutService.completeSet(setId: s.id, setRepo: setRepo);
      }

      await workoutService.finishWorkout(
        sessionRepo: sessionRepo,
        overloadService: overloadService,
        settingsRepo: settingsRepo,
        setRepo: setRepo,
        recRepo: recRepo,
      );

      final benchRec = workoutService.lastRecommendations.firstWhere(
        (r) => r.exerciseId == 'ex-bench',
      );
      await overloadService.editRecommendation(
        benchRec,
        newWeight: 85.0,
        newReps: 6,
        repo: recRepo,
      );

      await workoutService.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        recRepo: recRepo,
        plannedDate: '2025-07-02',
      );

      final benchSets = workoutService.setsForExercise('ex-bench');
      expect(benchSets.first.weightKg, 85.0);
      expect(benchSets.first.reps, 6);
    });
  });

  group('exercise settings', () {
    test('default settings are created automatically', () async {
      await seedPushDay();

      final settings = await settingsRepo.getOrCreateForExercise('ex-bench');
      expect(settings.minReps, 8);
      expect(settings.maxReps, 12);
      expect(settings.weightIncrementKg, 2.5);
      expect(settings.isBodyweight, false);
    });

    test('custom settings change recommendation thresholds', () async {
      await seedPushDay();

      final settings = await settingsRepo.getOrCreateForExercise('ex-bench');
      await settingsRepo.update(
        settings.copyWith(minReps: 5, maxReps: 5, weightIncrementKg: 5.0),
      );

      await workoutService.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      for (final s in workoutService.setsForExercise('ex-bench')) {
        await workoutService.updateSet(setId: s.id, reps: 5, setRepo: setRepo);
        await workoutService.completeSet(setId: s.id, setRepo: setRepo);
      }
      for (final s in workoutService.setsForExercise('ex-ohp')) {
        await workoutService.completeSet(setId: s.id, setRepo: setRepo);
      }

      await workoutService.finishWorkout(
        sessionRepo: sessionRepo,
        overloadService: overloadService,
        settingsRepo: settingsRepo,
        setRepo: setRepo,
        recRepo: recRepo,
      );

      final recs = workoutService.lastRecommendations;
      final benchRec = recs.firstWhere((r) => r.exerciseId == 'ex-bench');
      expect(benchRec.recommendedWeightKg, 85.0);
      expect(benchRec.recommendedReps, 5);
    });

    test('machine increment overrides default', () async {
      await seedPushDay();

      final settings = await settingsRepo.getOrCreateForExercise('ex-bench');
      await settingsRepo.update(
        settings.copyWith(
          minReps: 8,
          maxReps: 10,
          weightIncrementKg: 2.5,
          machineIncrementKg: 4.5,
        ),
      );

      await workoutService.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      for (final s in workoutService.setsForExercise('ex-bench')) {
        await workoutService.updateSet(setId: s.id, reps: 10, setRepo: setRepo);
        await workoutService.completeSet(setId: s.id, setRepo: setRepo);
      }
      for (final s in workoutService.setsForExercise('ex-ohp')) {
        await workoutService.completeSet(setId: s.id, setRepo: setRepo);
      }

      await workoutService.finishWorkout(
        sessionRepo: sessionRepo,
        overloadService: overloadService,
        settingsRepo: settingsRepo,
        setRepo: setRepo,
        recRepo: recRepo,
      );

      final benchRec = workoutService.lastRecommendations.firstWhere(
        (r) => r.exerciseId == 'ex-bench',
      );
      expect(benchRec.recommendedWeightKg, 84.5);
    });
  });

  group('recommendation history persistence', () {
    test('recommendations persist across sessions', () async {
      await seedPushDay();

      await settingsRepo.update(
        (await settingsRepo.getOrCreateForExercise('ex-bench'))
            .copyWith(minReps: 8, maxReps: 10),
      );

      await workoutService.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      for (final s in workoutService.sets) {
        await workoutService.updateSet(setId: s.id, reps: 10, setRepo: setRepo);
        await workoutService.completeSet(setId: s.id, setRepo: setRepo);
      }

      await workoutService.finishWorkout(
        sessionRepo: sessionRepo,
        overloadService: overloadService,
        settingsRepo: settingsRepo,
        setRepo: setRepo,
        recRepo: recRepo,
      );

      final benchHistory = await recRepo.getByExerciseId('ex-bench');
      expect(benchHistory.length, 1);
      expect(benchHistory.first.reasoning, isNotEmpty);
      expect(benchHistory.first.previousWeightKg, 80.0);
      expect(benchHistory.first.recommendedWeightKg, 82.5);
    });

    test('multiple workouts accumulate recommendation history', () async {
      await seedPushDay();

      await settingsRepo.update(
        (await settingsRepo.getOrCreateForExercise('ex-bench'))
            .copyWith(minReps: 8, maxReps: 10),
      );

      for (var workout = 0; workout < 2; workout++) {
        await workoutService.startFromRoutine(
          routineId: 'r-push',
          routineRepo: routineRepo,
          reRepo: reRepo,
          exerciseRepo: exerciseRepo,
          sessionRepo: sessionRepo,
          setRepo: setRepo,
        );

        for (final s in workoutService.sets) {
          await workoutService.updateSet(
            setId: s.id,
            reps: 10,
            setRepo: setRepo,
          );
          await workoutService.completeSet(setId: s.id, setRepo: setRepo);
        }

        await workoutService.finishWorkout(
          sessionRepo: sessionRepo,
          overloadService: overloadService,
          settingsRepo: settingsRepo,
          setRepo: setRepo,
          recRepo: recRepo,
        );
      }

      final benchHistory = await recRepo.getByExerciseId('ex-bench');
      expect(benchHistory.length, 2);
    });
  });

  group('high effort and incomplete sets', () {
    test('high RPE workout suggests maintaining load', () async {
      await seedPushDay();

      await settingsRepo.update(
        (await settingsRepo.getOrCreateForExercise('ex-bench'))
            .copyWith(minReps: 8, maxReps: 10),
      );

      await workoutService.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      for (final s in workoutService.setsForExercise('ex-bench')) {
        await workoutService.updateSet(
          setId: s.id,
          reps: 10,
          rpe: 9.5,
          setRepo: setRepo,
        );
        await workoutService.completeSet(setId: s.id, setRepo: setRepo);
      }
      for (final s in workoutService.setsForExercise('ex-ohp')) {
        await workoutService.completeSet(setId: s.id, setRepo: setRepo);
      }

      await workoutService.finishWorkout(
        sessionRepo: sessionRepo,
        overloadService: overloadService,
        settingsRepo: settingsRepo,
        setRepo: setRepo,
        recRepo: recRepo,
      );

      final benchRec = workoutService.lastRecommendations.firstWhere(
        (r) => r.exerciseId == 'ex-bench',
      );
      expect(benchRec.recommendedWeightKg, 80.0);
      expect(benchRec.reasoning, contains('RPE'));
    });

    test('partially completed workout suggests maintaining', () async {
      await seedPushDay();

      await workoutService.startFromRoutine(
        routineId: 'r-push',
        routineRepo: routineRepo,
        reRepo: reRepo,
        exerciseRepo: exerciseRepo,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
      );

      final benchSets = workoutService.setsForExercise('ex-bench');
      await workoutService.completeSet(
        setId: benchSets[0].id,
        setRepo: setRepo,
      );
      await workoutService.completeSet(
        setId: benchSets[1].id,
        setRepo: setRepo,
      );

      for (final s in workoutService.setsForExercise('ex-ohp')) {
        await workoutService.completeSet(setId: s.id, setRepo: setRepo);
      }

      await workoutService.finishWorkout(
        sessionRepo: sessionRepo,
        overloadService: overloadService,
        settingsRepo: settingsRepo,
        setRepo: setRepo,
        recRepo: recRepo,
      );

      final benchRec = workoutService.lastRecommendations.firstWhere(
        (r) => r.exerciseId == 'ex-bench',
      );
      expect(benchRec.reasoning, contains('not completed'));
      expect(benchRec.recommendedWeightKg, 80.0);
    });
  });

  group('bodyweight exercise integration', () {
    test('bodyweight exercise gets rep-only recommendation', () async {
      await exerciseRepo.create(
        Exercise(
          id: 'ex-pullup',
          name: 'Pull-ups',
          category: 'back',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final settings = await settingsRepo.getOrCreateForExercise('ex-pullup');
      await settingsRepo.update(
        settings.copyWith(isBodyweight: true, minReps: 5, maxReps: 10),
      );

      await workoutService.startStandalone(
        name: 'Pull Day',
        sessionRepo: sessionRepo,
      );

      await workoutService.addExerciseSets(
        exerciseId: 'ex-pullup',
        exerciseName: 'Pull-ups',
        count: 3,
        setRepo: setRepo,
      );

      for (final s in workoutService.sets) {
        await workoutService.updateSet(setId: s.id, reps: 10, setRepo: setRepo);
        await workoutService.completeSet(setId: s.id, setRepo: setRepo);
      }

      await workoutService.finishWorkout(
        sessionRepo: sessionRepo,
        overloadService: overloadService,
        settingsRepo: settingsRepo,
        setRepo: setRepo,
        recRepo: recRepo,
      );

      final recs = workoutService.lastRecommendations;
      expect(recs.length, 1);
      expect(recs.first.recommendedWeightKg, isNull);
      expect(recs.first.recommendedReps, 11);
      expect(recs.first.reasoning, contains('Bodyweight'));
    });
  });
}
