import 'package:flutter/foundation.dart';

const _sentinel = Object();

@immutable
class ExerciseSettings {
  final String id;
  final String exerciseId;
  final int minReps;
  final int maxReps;
  final double weightIncrementKg;
  final bool isBodyweight;
  final double? machineIncrementKg;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExerciseSettings({
    required this.id,
    required this.exerciseId,
    this.minReps = 8,
    this.maxReps = 12,
    this.weightIncrementKg = 2.5,
    this.isBodyweight = false,
    this.machineIncrementKg,
    required this.createdAt,
    required this.updatedAt,
  });

  double get effectiveIncrement => machineIncrementKg ?? weightIncrementKg;

  ExerciseSettings copyWith({
    String? id,
    String? exerciseId,
    int? minReps,
    int? maxReps,
    double? weightIncrementKg,
    bool? isBodyweight,
    Object? machineIncrementKg = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ExerciseSettings(
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    minReps: minReps ?? this.minReps,
    maxReps: maxReps ?? this.maxReps,
    weightIncrementKg: weightIncrementKg ?? this.weightIncrementKg,
    isBodyweight: isBodyweight ?? this.isBodyweight,
    machineIncrementKg: machineIncrementKg == _sentinel
        ? this.machineIncrementKg
        : (machineIncrementKg as num?)?.toDouble(),
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'exercise_id': exerciseId,
    'min_reps': minReps,
    'max_reps': maxReps,
    'weight_increment_kg': weightIncrementKg,
    'is_bodyweight': isBodyweight ? 1 : 0,
    'machine_increment_kg': machineIncrementKg,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ExerciseSettings.fromMap(Map<String, dynamic> map) =>
      ExerciseSettings(
        id: map['id'] as String,
        exerciseId: map['exercise_id'] as String,
        minReps: map['min_reps'] as int? ?? 8,
        maxReps: map['max_reps'] as int? ?? 12,
        weightIncrementKg:
            (map['weight_increment_kg'] as num?)?.toDouble() ?? 2.5,
        isBodyweight: (map['is_bodyweight'] as int?) == 1,
        machineIncrementKg: (map['machine_increment_kg'] as num?)?.toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseSettings &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          exerciseId == other.exerciseId &&
          minReps == other.minReps &&
          maxReps == other.maxReps &&
          weightIncrementKg == other.weightIncrementKg &&
          isBodyweight == other.isBodyweight &&
          machineIncrementKg == other.machineIncrementKg;

  @override
  int get hashCode => Object.hash(
    id,
    exerciseId,
    minReps,
    maxReps,
    weightIncrementKg,
    isBodyweight,
    machineIncrementKg,
  );

  @override
  String toString() =>
      'ExerciseSettings(id: $id, exerciseId: $exerciseId, '
      'reps: $minReps-$maxReps, increment: ${effectiveIncrement}kg)';
}
