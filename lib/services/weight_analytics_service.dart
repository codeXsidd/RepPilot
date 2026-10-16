import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/body_weight_entry.dart';
import 'package:rep_pilot/models/workout_set.dart';

class WeightAnalyticsService {
  const WeightAnalyticsService();

  List<({DateTime date, double average})> calculateMovingAverage(
    List<BodyWeightEntry> entries,
    int windowDays,
  ) {
    if (entries.isEmpty || windowDays <= 0) return [];

    final sorted = List<BodyWeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final results = <({DateTime date, double average})>[];
    for (final entry in sorted) {
      final windowStart = entry.date.subtract(Duration(days: windowDays - 1));
      final inWindow = sorted.where(
        (e) =>
            !stripTime(e.date).isBefore(stripTime(windowStart)) &&
            !stripTime(e.date).isAfter(stripTime(entry.date)),
      );
      if (inWindow.isEmpty) continue;
      final avg =
          inWindow.map((e) => e.weightKg).reduce((a, b) => a + b) /
          inWindow.length;
      results.add((date: entry.date, average: avg));
    }
    return results;
  }

  ({double change, int days})? getWeightChange(List<BodyWeightEntry> entries) {
    if (entries.length < 2) return null;

    final sorted = List<BodyWeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final first = sorted.first;
    final last = sorted.last;
    final change = last.weightKg - first.weightKg;
    final days = stripTime(last.date).difference(stripTime(first.date)).inDays;
    return (change: change, days: days);
  }

  double? getSevenDayAverage(List<BodyWeightEntry> entries, DateTime asOf) {
    final cutoff = stripTime(asOf).subtract(const Duration(days: 6));
    final inWindow = entries.where(
      (e) =>
          !stripTime(e.date).isBefore(cutoff) &&
          !stripTime(e.date).isAfter(stripTime(asOf)),
    );
    if (inWindow.isEmpty) return null;
    return inWindow.map((e) => e.weightKg).reduce((a, b) => a + b) /
        inWindow.length;
  }

  List<({DateTime date, double value})> prepareChartData(
    List<BodyWeightEntry> entries,
    String weightUnit,
  ) {
    if (entries.isEmpty) return [];

    final sorted = List<BodyWeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    return sorted
        .map(
          (e) => (date: e.date, value: displayWeight(e.weightKg, weightUnit)),
        )
        .toList();
  }

  String getWorkoutConsistency(int sessionsThisWeek, int sessionsLastWeek) {
    final buffer = StringBuffer('$sessionsThisWeek this week');
    if (sessionsLastWeek == 0 && sessionsThisWeek == 0) {
      return 'No workouts recorded recently';
    }
    if (sessionsLastWeek > 0) {
      if (sessionsThisWeek > sessionsLastWeek) {
        buffer.write(', up from $sessionsLastWeek last week');
      } else if (sessionsThisWeek < sessionsLastWeek) {
        buffer.write(', down from $sessionsLastWeek last week');
      } else {
        buffer.write(', same as last week');
      }
    }
    return buffer.toString();
  }

  double calculateTotalVolume(List<WorkoutSet> sets) {
    var total = 0.0;
    for (final s in sets) {
      if (s.completed && !s.isWarmup && s.weightKg != null && s.reps != null) {
        total += s.weightKg! * s.reps!;
      }
    }
    return total;
  }

  Map<String, ({double maxWeight, int maxReps, String exerciseName})>
  findPersonalRecords(List<WorkoutSet> allSets) {
    final records =
        <String, ({double maxWeight, int maxReps, String exerciseName})>{};

    for (final s in allSets) {
      if (!s.completed || s.isWarmup || s.weightKg == null || s.reps == null) {
        continue;
      }
      final existing = records[s.exerciseId];
      if (existing == null) {
        records[s.exerciseId] = (
          maxWeight: s.weightKg!,
          maxReps: s.reps!,
          exerciseName: s.exerciseName,
        );
      } else {
        var updated = false;
        var weight = existing.maxWeight;
        var reps = existing.maxReps;
        if (s.weightKg! > existing.maxWeight) {
          weight = s.weightKg!;
          reps = s.reps!;
          updated = true;
        } else if (s.weightKg! == existing.maxWeight &&
            s.reps! > existing.maxReps) {
          reps = s.reps!;
          updated = true;
        }
        if (updated) {
          records[s.exerciseId] = (
            maxWeight: weight,
            maxReps: reps,
            exerciseName: s.exerciseName,
          );
        }
      }
    }
    return records;
  }
}
