import 'package:flutter_test/flutter_test.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/body_weight_entry.dart';
import 'package:rep_pilot/models/workout_set.dart';
import 'package:rep_pilot/services/weight_analytics_service.dart';

void main() {
  const analytics = WeightAnalyticsService();
  final now = DateTime(2025, 7, 1);

  BodyWeightEntry makeEntry({
    required DateTime date,
    required double weightKg,
  }) {
    return BodyWeightEntry(
      id: generateId(),
      date: stripTime(date),
      weightKg: weightKg,
      createdAt: now,
      updatedAt: now,
    );
  }

  WorkoutSet makeSet({
    String exerciseId = 'ex-1',
    String exerciseName = 'Bench Press',
    int? reps = 10,
    double? weightKg = 60.0,
    bool completed = true,
    bool isWarmup = false,
  }) {
    return WorkoutSet(
      id: generateId(),
      sessionId: 'sess-1',
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      setNumber: 1,
      reps: reps,
      weightKg: weightKg,
      completed: completed,
      isWarmup: isWarmup,
      completedAt: completed ? now : null,
    );
  }

  group('calculateMovingAverage', () {
    test('returns empty list for empty entries', () {
      final result = analytics.calculateMovingAverage([], 7);
      expect(result, isEmpty);
    });

    test('returns empty list for zero window', () {
      final entries = [makeEntry(date: now, weightKg: 70.0)];
      final result = analytics.calculateMovingAverage(entries, 0);
      expect(result, isEmpty);
    });

    test('returns same value for single entry', () {
      final entries = [makeEntry(date: now, weightKg: 70.0)];
      final result = analytics.calculateMovingAverage(entries, 7);
      expect(result.length, 1);
      expect(result[0].average, 70.0);
    });

    test('computes correct 3-day moving average', () {
      final entries = [
        makeEntry(date: DateTime(2025, 7, 1), weightKg: 70.0),
        makeEntry(date: DateTime(2025, 7, 2), weightKg: 71.0),
        makeEntry(date: DateTime(2025, 7, 3), weightKg: 72.0),
        makeEntry(date: DateTime(2025, 7, 4), weightKg: 73.0),
      ];

      final result = analytics.calculateMovingAverage(entries, 3);
      expect(result.length, 4);
      expect(result[0].average, 70.0);
      expect(result[1].average, closeTo(70.5, 0.01));
      expect(result[2].average, closeTo(71.0, 0.01));
      expect(result[3].average, closeTo(72.0, 0.01));
    });

    test('handles unsorted input', () {
      final entries = [
        makeEntry(date: DateTime(2025, 7, 3), weightKg: 72.0),
        makeEntry(date: DateTime(2025, 7, 1), weightKg: 70.0),
        makeEntry(date: DateTime(2025, 7, 2), weightKg: 71.0),
      ];

      final result = analytics.calculateMovingAverage(entries, 3);
      expect(result.length, 3);
      expect(result[0].date, DateTime(2025, 7, 1));
      expect(result[2].average, closeTo(71.0, 0.01));
    });

    test('handles gaps in dates', () {
      final entries = [
        makeEntry(date: DateTime(2025, 7, 1), weightKg: 70.0),
        makeEntry(date: DateTime(2025, 7, 5), weightKg: 72.0),
      ];

      final result = analytics.calculateMovingAverage(entries, 3);
      expect(result.length, 2);
      expect(result[0].average, 70.0);
      expect(result[1].average, 72.0);
    });

    test('7-day window averages correctly', () {
      final entries = List.generate(
        7,
        (i) => makeEntry(date: DateTime(2025, 7, 1 + i), weightKg: 70.0 + i),
      );

      final result = analytics.calculateMovingAverage(entries, 7);
      expect(result.length, 7);
      expect(result.last.average, closeTo(73.0, 0.01));
    });
  });

  group('getWeightChange', () {
    test('returns null for empty list', () {
      final result = analytics.getWeightChange([]);
      expect(result, isNull);
    });

    test('returns null for single entry', () {
      final result = analytics.getWeightChange([
        makeEntry(date: now, weightKg: 70.0),
      ]);
      expect(result, isNull);
    });

    test('computes positive change correctly', () {
      final entries = [
        makeEntry(date: DateTime(2025, 6, 1), weightKg: 70.0),
        makeEntry(date: DateTime(2025, 7, 1), weightKg: 72.5),
      ];

      final result = analytics.getWeightChange(entries)!;
      expect(result.change, closeTo(2.5, 0.01));
      expect(result.days, 30);
    });

    test('computes negative change correctly', () {
      final entries = [
        makeEntry(date: DateTime(2025, 6, 1), weightKg: 75.0),
        makeEntry(date: DateTime(2025, 7, 1), weightKg: 72.0),
      ];

      final result = analytics.getWeightChange(entries)!;
      expect(result.change, closeTo(-3.0, 0.01));
    });

    test('handles unsorted input', () {
      final entries = [
        makeEntry(date: DateTime(2025, 7, 1), weightKg: 72.0),
        makeEntry(date: DateTime(2025, 6, 1), weightKg: 70.0),
      ];

      final result = analytics.getWeightChange(entries)!;
      expect(result.change, closeTo(2.0, 0.01));
    });

    test('returns zero change for same weight', () {
      final entries = [
        makeEntry(date: DateTime(2025, 6, 1), weightKg: 70.0),
        makeEntry(date: DateTime(2025, 7, 1), weightKg: 70.0),
      ];

      final result = analytics.getWeightChange(entries)!;
      expect(result.change, 0.0);
      expect(result.days, 30);
    });
  });

  group('getSevenDayAverage', () {
    test('returns null for empty entries', () {
      final result = analytics.getSevenDayAverage([], now);
      expect(result, isNull);
    });

    test('returns value for single entry within window', () {
      final entries = [makeEntry(date: now, weightKg: 70.0)];
      final result = analytics.getSevenDayAverage(entries, now);
      expect(result, 70.0);
    });

    test('averages entries within 7-day window', () {
      final entries = [
        makeEntry(date: DateTime(2025, 6, 25), weightKg: 70.0),
        makeEntry(date: DateTime(2025, 6, 27), weightKg: 72.0),
        makeEntry(date: DateTime(2025, 6, 30), weightKg: 74.0),
        makeEntry(date: DateTime(2025, 7, 1), weightKg: 76.0),
      ];

      final result = analytics.getSevenDayAverage(entries, now);
      expect(result, isNotNull);
      expect(result, closeTo(73.0, 0.01));
    });

    test('excludes entries outside 7-day window', () {
      final entries = [
        makeEntry(date: DateTime(2025, 6, 20), weightKg: 60.0),
        makeEntry(date: DateTime(2025, 7, 1), weightKg: 70.0),
      ];

      final result = analytics.getSevenDayAverage(entries, now);
      expect(result, 70.0);
    });

    test('returns null when all entries outside window', () {
      final entries = [makeEntry(date: DateTime(2025, 6, 1), weightKg: 70.0)];

      final result = analytics.getSevenDayAverage(entries, now);
      expect(result, isNull);
    });
  });

  group('prepareChartData', () {
    test('returns empty list for empty entries', () {
      final result = analytics.prepareChartData([], 'kg');
      expect(result, isEmpty);
    });

    test('returns kg values for kg unit', () {
      final entries = [
        makeEntry(date: DateTime(2025, 7, 1), weightKg: 70.0),
        makeEntry(date: DateTime(2025, 7, 2), weightKg: 71.0),
      ];

      final result = analytics.prepareChartData(entries, 'kg');
      expect(result.length, 2);
      expect(result[0].value, 70.0);
      expect(result[1].value, 71.0);
    });

    test('converts to lb for lb unit', () {
      final entries = [makeEntry(date: DateTime(2025, 7, 1), weightKg: 70.0)];

      final result = analytics.prepareChartData(entries, 'lb');
      expect(result.length, 1);
      expect(result[0].value, closeTo(kgToLb(70.0), 0.01));
    });

    test('sorts entries by date ascending', () {
      final entries = [
        makeEntry(date: DateTime(2025, 7, 3), weightKg: 72.0),
        makeEntry(date: DateTime(2025, 7, 1), weightKg: 70.0),
        makeEntry(date: DateTime(2025, 7, 2), weightKg: 71.0),
      ];

      final result = analytics.prepareChartData(entries, 'kg');
      expect(result[0].date, DateTime(2025, 7, 1));
      expect(result[1].date, DateTime(2025, 7, 2));
      expect(result[2].date, DateTime(2025, 7, 3));
    });
  });

  group('getWorkoutConsistency', () {
    test('returns "no workouts" for 0/0', () {
      final result = analytics.getWorkoutConsistency(0, 0);
      expect(result, contains('No workouts'));
    });

    test('shows improvement', () {
      final result = analytics.getWorkoutConsistency(4, 2);
      expect(result, contains('up from'));
      expect(result, contains('4'));
    });

    test('shows decline', () {
      final result = analytics.getWorkoutConsistency(2, 4);
      expect(result, contains('down from'));
    });

    test('shows same as last week', () {
      final result = analytics.getWorkoutConsistency(3, 3);
      expect(result, contains('same'));
    });

    test('shows only this week when last week is 0', () {
      final result = analytics.getWorkoutConsistency(3, 0);
      expect(result, contains('3'));
      expect(result, isNot(contains('last week')));
    });
  });

  group('calculateTotalVolume', () {
    test('returns 0 for empty list', () {
      expect(analytics.calculateTotalVolume([]), 0.0);
    });

    test('sums weight * reps for completed working sets', () {
      final sets = [
        makeSet(reps: 10, weightKg: 60.0),
        makeSet(reps: 8, weightKg: 60.0),
        makeSet(reps: 6, weightKg: 60.0),
      ];
      final volume = analytics.calculateTotalVolume(sets);
      expect(volume, closeTo(1440.0, 0.01));
    });

    test('excludes warmup sets', () {
      final sets = [
        makeSet(reps: 10, weightKg: 60.0),
        makeSet(reps: 10, weightKg: 40.0, isWarmup: true),
      ];
      final volume = analytics.calculateTotalVolume(sets);
      expect(volume, closeTo(600.0, 0.01));
    });

    test('excludes incomplete sets', () {
      final sets = [
        makeSet(reps: 10, weightKg: 60.0),
        makeSet(reps: 10, weightKg: 60.0, completed: false),
      ];
      final volume = analytics.calculateTotalVolume(sets);
      expect(volume, closeTo(600.0, 0.01));
    });

    test('excludes sets with null weight or reps', () {
      final sets = [
        makeSet(reps: 10, weightKg: 60.0),
        makeSet(reps: 10, weightKg: null),
        makeSet(reps: null, weightKg: 60.0),
      ];
      final volume = analytics.calculateTotalVolume(sets);
      expect(volume, closeTo(600.0, 0.01));
    });
  });

  group('findPersonalRecords', () {
    test('returns empty map for empty list', () {
      expect(analytics.findPersonalRecords([]), isEmpty);
    });

    test('finds PR for single exercise', () {
      final sets = [
        makeSet(reps: 10, weightKg: 60.0),
        makeSet(reps: 8, weightKg: 65.0),
        makeSet(reps: 5, weightKg: 70.0),
      ];

      final records = analytics.findPersonalRecords(sets);
      expect(records.length, 1);
      expect(records['ex-1']!.maxWeight, 70.0);
      expect(records['ex-1']!.maxReps, 5);
    });

    test('prefers higher weight over more reps', () {
      final sets = [
        makeSet(reps: 12, weightKg: 60.0),
        makeSet(reps: 5, weightKg: 80.0),
      ];

      final records = analytics.findPersonalRecords(sets);
      expect(records['ex-1']!.maxWeight, 80.0);
      expect(records['ex-1']!.maxReps, 5);
    });

    test('at same weight, prefers more reps', () {
      final sets = [
        makeSet(reps: 8, weightKg: 60.0),
        makeSet(reps: 12, weightKg: 60.0),
      ];

      final records = analytics.findPersonalRecords(sets);
      expect(records['ex-1']!.maxWeight, 60.0);
      expect(records['ex-1']!.maxReps, 12);
    });

    test('tracks multiple exercises independently', () {
      final sets = [
        makeSet(
          exerciseId: 'ex-1',
          exerciseName: 'Bench',
          reps: 10,
          weightKg: 60.0,
        ),
        makeSet(
          exerciseId: 'ex-2',
          exerciseName: 'Squat',
          reps: 5,
          weightKg: 100.0,
        ),
      ];

      final records = analytics.findPersonalRecords(sets);
      expect(records.length, 2);
      expect(records['ex-1']!.maxWeight, 60.0);
      expect(records['ex-2']!.maxWeight, 100.0);
    });

    test('excludes incomplete sets from PRs', () {
      final sets = [
        makeSet(reps: 10, weightKg: 60.0),
        makeSet(reps: 5, weightKg: 100.0, completed: false),
      ];

      final records = analytics.findPersonalRecords(sets);
      expect(records['ex-1']!.maxWeight, 60.0);
    });

    test('excludes warmup sets from PRs', () {
      final sets = [
        makeSet(reps: 10, weightKg: 60.0),
        makeSet(reps: 10, weightKg: 100.0, isWarmup: true),
      ];

      final records = analytics.findPersonalRecords(sets);
      expect(records['ex-1']!.maxWeight, 60.0);
    });

    test('excludes sets with null weight', () {
      final sets = [
        makeSet(reps: 10, weightKg: 60.0),
        makeSet(reps: 10, weightKg: null),
      ];

      final records = analytics.findPersonalRecords(sets);
      expect(records['ex-1']!.maxWeight, 60.0);
    });
  });
}
