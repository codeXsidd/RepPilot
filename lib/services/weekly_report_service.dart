import '../core/constants.dart';
import '../models/weekly_report.dart';
import '../models/workout_set.dart';
import '../repositories/body_weight_repository.dart';
import '../repositories/food_entry_repository.dart';
import '../repositories/water_entry_repository.dart';
import '../repositories/workout_session_repository.dart';
import '../repositories/workout_set_repository.dart';
import '../services/streak_service.dart';

class WeeklyReportService {
  final StreakService _streakService;

  const WeeklyReportService(this._streakService);

  Future<WeeklyReport> generateReport({
    required DateTime weekStart,
    required WorkoutSessionRepository sessionRepo,
    required WorkoutSetRepository setRepo,
    required BodyWeightRepository weightRepo,
    required FoodEntryRepository foodRepo,
    required WaterEntryRepository waterRepo,
  }) async {
    final monday = _mondayOf(stripTime(weekStart));
    final sunday = monday.add(const Duration(days: 6));

    final sessions = await sessionRepo.getByDateRange(
      monday,
      sunday.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
    );
    final completedSessions = sessions
        .where((s) => s.completedAt != null)
        .toList();

    var totalVolume = 0.0;
    final prRecords = <PersonalRecordEntry>[];
    final allSets = <WorkoutSet>[];

    for (final session in completedSessions) {
      final sets = await setRepo.getBySessionId(session.id);
      allSets.addAll(sets);
      for (final s in sets) {
        if (s.completed &&
            !s.isWarmup &&
            s.weightKg != null &&
            s.reps != null) {
          totalVolume += s.weightKg! * s.reps!;
        }
      }
    }

    final allSessionsEver = await sessionRepo.getAll();
    final allSetsEver = await setRepo.getAllCompleted();

    final prsBefore = _findPRs(
      allSetsEver
          .where(
            (s) => s.completedAt != null && s.completedAt!.isBefore(monday),
          )
          .toList(),
    );
    final prsIncluding = _findPRs(allSetsEver);

    for (final entry in prsIncluding.entries) {
      final old = prsBefore[entry.key];
      if (old == null ||
          entry.value.maxWeight > old.maxWeight ||
          (entry.value.maxWeight == old.maxWeight &&
              entry.value.maxReps > old.maxReps)) {
        final thisWeekSets = allSets
            .where(
              (s) => s.exerciseId == entry.key && s.completed && !s.isWarmup,
            )
            .toList();
        if (thisWeekSets.isNotEmpty) {
          prRecords.add(
            PersonalRecordEntry(
              exerciseName: entry.value.exerciseName,
              weightKg: entry.value.maxWeight,
              reps: entry.value.maxReps,
            ),
          );
        }
      }
    }

    final weightEntries = await weightRepo.getByDateRange(monday, sunday);
    final sortedWeights = weightEntries.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    double? weeklyCalories;
    double? weeklyProtein;
    double? weeklyWater;
    var foodDaysCount = 0;
    var waterDaysCount = 0;
    var totalCals = 0.0;
    var totalPro = 0.0;
    var totalWater = 0.0;

    for (var i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final dayTotals = await foodRepo.getDailyTotals(day);
      final dayCal = dayTotals['calories'] ?? 0;
      final dayPro = dayTotals['protein'] ?? 0;
      if (dayCal > 0 || dayPro > 0) {
        totalCals += dayCal;
        totalPro += dayPro;
        foodDaysCount++;
      }

      final dayWater = await waterRepo.getDailyTotalMl(day);
      if (dayWater > 0) {
        totalWater += dayWater;
        waterDaysCount++;
      }
    }

    if (foodDaysCount > 0) {
      weeklyCalories = totalCals / foodDaysCount;
      weeklyProtein = totalPro / foodDaysCount;
    }
    if (waterDaysCount > 0) {
      weeklyWater = totalWater / waterDaysCount;
    }

    final currentStreak = _streakService.getCurrentStreak(
      allSessionsEver,
      sunday,
    );
    final longestStreak = _streakService.getLongestStreak(allSessionsEver);

    return WeeklyReport(
      weekStart: monday,
      weekEnd: sunday,
      workoutsCompleted: completedSessions.length,
      totalVolumeKg: totalVolume,
      personalRecordsCount: prRecords.length,
      newPersonalRecords: prRecords,
      weightStart: sortedWeights.isNotEmpty
          ? sortedWeights.first.weightKg
          : null,
      weightEnd: sortedWeights.length > 1 ? sortedWeights.last.weightKg : null,
      averageCalories: weeklyCalories,
      averageProtein: weeklyProtein,
      averageWaterMl: weeklyWater,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }

  Map<String, ({double maxWeight, int maxReps, String exerciseName})> _findPRs(
    List<WorkoutSet> sets,
  ) {
    final records =
        <String, ({double maxWeight, int maxReps, String exerciseName})>{};
    for (final s in sets) {
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
        if (s.weightKg! > existing.maxWeight ||
            (s.weightKg! == existing.maxWeight && s.reps! > existing.maxReps)) {
          records[s.exerciseId] = (
            maxWeight: s.weightKg!,
            maxReps: s.reps!,
            exerciseName: s.exerciseName,
          );
        }
      }
    }
    return records;
  }

  DateTime _mondayOf(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
}
