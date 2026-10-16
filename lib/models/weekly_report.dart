import 'package:flutter/foundation.dart';

@immutable
class WeeklyReport {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int workoutsCompleted;
  final double totalVolumeKg;
  final int personalRecordsCount;
  final List<PersonalRecordEntry> newPersonalRecords;
  final double? weightStart;
  final double? weightEnd;
  final double? averageCalories;
  final double? averageProtein;
  final double? averageWaterMl;
  final int currentStreak;
  final int longestStreak;

  const WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    this.workoutsCompleted = 0,
    this.totalVolumeKg = 0,
    this.personalRecordsCount = 0,
    this.newPersonalRecords = const [],
    this.weightStart,
    this.weightEnd,
    this.averageCalories,
    this.averageProtein,
    this.averageWaterMl,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  double? get weightChange {
    if (weightStart == null || weightEnd == null) return null;
    return weightEnd! - weightStart!;
  }

  bool get hasWorkoutData => workoutsCompleted > 0;
  bool get hasWeightData => weightStart != null || weightEnd != null;
  bool get hasNutritionData => averageCalories != null;
  bool get hasWaterData => averageWaterMl != null;
  bool get hasAnyData =>
      hasWorkoutData || hasWeightData || hasNutritionData || hasWaterData;
}

@immutable
class PersonalRecordEntry {
  final String exerciseName;
  final double weightKg;
  final int reps;

  const PersonalRecordEntry({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
  });
}
