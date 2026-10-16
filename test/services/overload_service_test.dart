import 'package:flutter_test/flutter_test.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/exercise_settings.dart';
import 'package:rep_pilot/models/workout_set.dart';
import 'package:rep_pilot/services/overload_service.dart';

void main() {
  late OverloadService service;
  final now = DateTime(2025, 7, 1);

  ExerciseSettings makeSettings({
    int minReps = 8,
    int maxReps = 12,
    double increment = 2.5,
    bool isBodyweight = false,
    double? machineIncrement,
  }) {
    return ExerciseSettings(
      id: 'settings-1',
      exerciseId: 'ex-1',
      minReps: minReps,
      maxReps: maxReps,
      weightIncrementKg: increment,
      isBodyweight: isBodyweight,
      machineIncrementKg: machineIncrement,
      createdAt: now,
      updatedAt: now,
    );
  }

  WorkoutSet makeSet({
    String id = 's1',
    String sessionId = 'sess-1',
    String exerciseId = 'ex-1',
    int setNumber = 1,
    int? reps = 10,
    double? weightKg = 60.0,
    bool completed = true,
    double? rpe,
    bool isWarmup = false,
  }) {
    return WorkoutSet(
      id: id,
      sessionId: sessionId,
      exerciseId: exerciseId,
      exerciseName: 'Bench Press',
      setNumber: setNumber,
      reps: reps,
      weightKg: weightKg,
      completed: completed,
      rpe: rpe,
      isWarmup: isWarmup,
      completedAt: completed ? now : null,
    );
  }

  setUp(() {
    service = OverloadService();
  });

  group('weight increase', () {
    test('suggests increase when all sets meet max reps', () {
      final settings = makeSettings(maxReps: 12, minReps: 8, increment: 2.5);
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 12, weightKg: 60.0),
        makeSet(id: 's2', setNumber: 2, reps: 12, weightKg: 60.0),
        makeSet(id: 's3', setNumber: 3, reps: 12, weightKg: 60.0),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedWeightKg, 62.5);
      expect(rec.recommendedReps, 8);
      expect(rec.previousWeightKg, 60.0);
      expect(rec.reasoning, contains('62.5'));
      expect(rec.reasoning, contains('8 reps'));
    });

    test('uses effective increment for machines', () {
      final settings = makeSettings(
        maxReps: 10,
        minReps: 8,
        increment: 2.5,
        machineIncrement: 5.0,
      );
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: 40.0),
        makeSet(id: 's2', setNumber: 2, reps: 10, weightKg: 40.0),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedWeightKg, 45.0);
      expect(rec.recommendedReps, 8);
    });

    test('exceeding max reps still triggers increase', () {
      final settings = makeSettings(maxReps: 10, minReps: 6);
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 13, weightKg: 50.0),
        makeSet(id: 's2', setNumber: 2, reps: 11, weightKg: 50.0),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedWeightKg, 52.5);
      expect(rec.recommendedReps, 6);
    });
  });

  group('maintain and build reps', () {
    test('suggests building reps when below max', () {
      final settings = makeSettings(maxReps: 12, minReps: 8);
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: 60.0),
        makeSet(id: 's2', setNumber: 2, reps: 10, weightKg: 60.0),
        makeSet(id: 's3', setNumber: 3, reps: 9, weightKg: 60.0),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedWeightKg, 60.0);
      final expectedTarget = 11;
      expect(rec.recommendedReps, expectedTarget);
      expect(rec.reasoning, contains('Maintain'));
    });

    test('caps rep suggestion at max reps', () {
      final settings = makeSettings(maxReps: 10, minReps: 8);
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 9, weightKg: 60.0),
        makeSet(id: 's2', setNumber: 2, reps: 10, weightKg: 60.0),
        makeSet(id: 's3', setNumber: 3, reps: 9, weightKg: 60.0),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedReps, lessThanOrEqualTo(10));
    });

    test('mixed reps across sets recommend average+1', () {
      final settings = makeSettings(maxReps: 12, minReps: 8);
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 8, weightKg: 70.0),
        makeSet(id: 's2', setNumber: 2, reps: 7, weightKg: 70.0),
        makeSet(id: 's3', setNumber: 3, reps: 6, weightKg: 70.0),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedWeightKg, 70.0);
      expect(rec.recommendedReps, 8);
    });
  });

  group('high effort', () {
    test('high RPE prevents weight increase even if reps met', () {
      final settings = makeSettings(maxReps: 10);
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: 80.0, rpe: 9.5),
        makeSet(id: 's2', setNumber: 2, reps: 10, weightKg: 80.0, rpe: 9.0),
        makeSet(id: 's3', setNumber: 3, reps: 10, weightKg: 80.0, rpe: 9.5),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedWeightKg, 80.0);
      expect(rec.reasoning, contains('RPE'));
      expect(rec.reasoning, contains('Maintain'));
    });

    test('moderate RPE allows normal progression', () {
      final settings = makeSettings(maxReps: 10, minReps: 6);
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: 80.0, rpe: 8.0),
        makeSet(id: 's2', setNumber: 2, reps: 10, weightKg: 80.0, rpe: 8.5),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedWeightKg, 82.5);
    });

    test('exactly RPE 9.0 triggers high effort path', () {
      final settings = makeSettings(maxReps: 10);
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: 60.0, rpe: 9.0),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedWeightKg, 60.0);
      expect(rec.reasoning, contains('RPE'));
    });

    test('sets without RPE are not counted in RPE average', () {
      final settings = makeSettings(maxReps: 10, minReps: 6);
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: 60.0),
        makeSet(id: 's2', setNumber: 2, reps: 10, weightKg: 60.0, rpe: 8.0),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedWeightKg, 62.5);
    });
  });

  group('incomplete sets', () {
    test('incomplete sets prevent weight increase', () {
      final settings = makeSettings(maxReps: 10);
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: 60.0),
        makeSet(
          id: 's2',
          setNumber: 2,
          reps: 10,
          weightKg: 60.0,
          completed: false,
        ),
        makeSet(id: 's3', setNumber: 3, reps: 10, weightKg: 60.0),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedWeightKg, 60.0);
      expect(rec.reasoning, contains('not completed'));
    });

    test('all incomplete returns maintain recommendation', () {
      final settings = makeSettings(maxReps: 10);
      final sets = [
        makeSet(
          id: 's1',
          setNumber: 1,
          reps: 10,
          weightKg: 60.0,
          completed: false,
        ),
        makeSet(
          id: 's2',
          setNumber: 2,
          reps: 8,
          weightKg: 60.0,
          completed: false,
        ),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.reasoning, contains('not completed'));
    });
  });

  group('empty history', () {
    test('returns null for empty set list', () {
      final settings = makeSettings();
      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: [],
      );
      expect(rec, isNull);
    });

    test('returns null when only warmup sets exist', () {
      final settings = makeSettings();
      final sets = [
        makeSet(id: 's1', setNumber: 1, isWarmup: true),
        makeSet(id: 's2', setNumber: 2, isWarmup: true),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );
      expect(rec, isNull);
    });

    test('returns null when only skipped (reps=0) sets exist', () {
      final settings = makeSettings();
      final sets = [makeSet(id: 's1', setNumber: 1, reps: 0)];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );
      expect(rec, isNull);
    });

    test('shouldSuggest returns false for empty list', () {
      expect(service.shouldSuggest(recentSets: []), false);
    });

    test('shouldSuggest returns false for only warmups', () {
      final sets = [makeSet(id: 's1', isWarmup: true)];
      expect(service.shouldSuggest(recentSets: sets), false);
    });

    test('shouldSuggest returns true for working sets', () {
      final sets = [makeSet(id: 's1', reps: 10, weightKg: 60.0)];
      expect(service.shouldSuggest(recentSets: sets), true);
    });
  });

  group('bodyweight exercises', () {
    test('suggests rep increase when hitting max reps', () {
      final settings = makeSettings(
        maxReps: 15,
        minReps: 10,
        isBodyweight: true,
      );
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 15, weightKg: null),
        makeSet(id: 's2', setNumber: 2, reps: 15, weightKg: null),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedWeightKg, isNull);
      expect(rec.recommendedReps, 16);
      expect(rec.reasoning, contains('Bodyweight'));
    });

    test('suggests building reps when below max', () {
      final settings = makeSettings(
        maxReps: 20,
        minReps: 10,
        isBodyweight: true,
      );
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 12, weightKg: null),
        makeSet(id: 's2', setNumber: 2, reps: 14, weightKg: null),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedWeightKg, isNull);
      expect(rec.recommendedReps, 14);
      expect(rec.reasoning, contains('building'));
    });
  });

  group('unit conversion', () {
    test('explainRecommendation adds lb conversion for lb users', () {
      final settings = makeSettings(maxReps: 10, minReps: 8);
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: 60.0),
        makeSet(id: 's2', setNumber: 2, reps: 10, weightKg: 60.0),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      )!;

      final explanation = service.explainRecommendation(rec, 'lb');
      final expectedLb = displayWeight(rec.recommendedWeightKg!, 'lb');
      expect(explanation, contains('lb'));
      expect(explanation, contains(expectedLb.toStringAsFixed(1)));
    });

    test('explainRecommendation has no lb suffix for kg users', () {
      final settings = makeSettings(maxReps: 10, minReps: 8);
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: 60.0),
        makeSet(id: 's2', setNumber: 2, reps: 10, weightKg: 60.0),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      )!;

      final explanation = service.explainRecommendation(rec, 'kg');
      expect(explanation, isNot(contains('lb')));
    });

    test('explainRecommendation handles null weight recommendation', () {
      final settings = makeSettings(maxReps: 15, isBodyweight: true);
      final sets = [makeSet(id: 's1', setNumber: 1, reps: 15, weightKg: null)];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      )!;

      final explanation = service.explainRecommendation(rec, 'lb');
      expect(explanation, isNot(contains('lb')));
    });
  });

  group('edge cases', () {
    test('filters warmup sets from analysis', () {
      final settings = makeSettings(maxReps: 10, minReps: 8);
      final sets = [
        makeSet(
          id: 's0',
          setNumber: 0,
          reps: 10,
          weightKg: 40.0,
          isWarmup: true,
        ),
        makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: 60.0),
        makeSet(id: 's2', setNumber: 2, reps: 10, weightKg: 60.0),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedWeightKg, 62.5);
    });

    test('only uses latest session from multi-session history', () {
      final settings = makeSettings(maxReps: 10, minReps: 8);
      final sets = [
        makeSet(
          id: 's1',
          sessionId: 'sess-2',
          setNumber: 1,
          reps: 10,
          weightKg: 65.0,
        ),
        makeSet(
          id: 's2',
          sessionId: 'sess-2',
          setNumber: 2,
          reps: 10,
          weightKg: 65.0,
        ),
        makeSet(
          id: 's3',
          sessionId: 'sess-1',
          setNumber: 1,
          reps: 8,
          weightKg: 60.0,
        ),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedWeightKg, 67.5);
      expect(rec.previousWeightKg, 65.0);
    });

    test('uses dominant weight when sets have mixed weights', () {
      final settings = makeSettings(maxReps: 10, minReps: 8);
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: 60.0),
        makeSet(id: 's2', setNumber: 2, reps: 10, weightKg: 60.0),
        makeSet(id: 's3', setNumber: 3, reps: 10, weightKg: 62.5),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.previousWeightKg, 60.0);
      expect(rec.recommendedWeightKg, 62.5);
    });

    test('stores session id in recommendation', () {
      final settings = makeSettings(maxReps: 10, minReps: 8);
      final sets = [makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: 60.0)];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
        sessionId: 'sess-99',
      );

      expect(rec, isNotNull);
      expect(rec!.sessionId, 'sess-99');
    });

    test('recommendation has pending status', () {
      final settings = makeSettings(maxReps: 10, minReps: 8);
      final sets = [makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: 60.0)];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.status, 'pending');
    });

    test('skipped sets (reps=0) are excluded from analysis', () {
      final settings = makeSettings(maxReps: 10, minReps: 8);
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: 60.0),
        makeSet(id: 's2', setNumber: 2, reps: 0, weightKg: 60.0),
        makeSet(id: 's3', setNumber: 3, reps: 10, weightKg: 60.0),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedWeightKg, 62.5);
    });

    test('single set triggers recommendation', () {
      final settings = makeSettings(maxReps: 10, minReps: 8);
      final sets = [makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: 80.0)];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      );

      expect(rec, isNotNull);
      expect(rec!.recommendedWeightKg, 82.5);
    });

    test(
      'null weight with non-bodyweight returns build-reps recommendation',
      () {
        final settings = makeSettings(maxReps: 12, minReps: 8);
        final sets = [
          makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: null),
        ];

        final rec = service.generateRecommendation(
          exerciseId: 'ex-1',
          settings: settings,
          recentSets: sets,
        );

        expect(rec, isNull);
      },
    );
  });

  group('recommendation actions', () {
    test('explainRecommendation returns reasoning text', () {
      final settings = makeSettings(maxReps: 10, minReps: 8);
      final sets = [
        makeSet(id: 's1', setNumber: 1, reps: 10, weightKg: 60.0),
        makeSet(id: 's2', setNumber: 2, reps: 10, weightKg: 60.0),
      ];

      final rec = service.generateRecommendation(
        exerciseId: 'ex-1',
        settings: settings,
        recentSets: sets,
      )!;

      final explanation = service.explainRecommendation(rec, 'kg');
      expect(explanation, isNotEmpty);
      expect(explanation, rec.reasoning);
    });
  });
}
