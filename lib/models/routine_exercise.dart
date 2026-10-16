import 'package:flutter/foundation.dart';

const _sentinel = Object();

@immutable
class RoutineExercise {
  final String id;
  final String routineId;
  final String exerciseId;
  final int targetSets;
  final int targetReps;
  final int? targetRepsMin;
  final int? targetRepsMax;
  final double? targetWeightKg;
  final int restSeconds;
  final int sortOrder;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoutineExercise({
    required this.id,
    required this.routineId,
    required this.exerciseId,
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetRepsMin,
    this.targetRepsMax,
    this.targetWeightKg,
    this.restSeconds = 60,
    this.sortOrder = 0,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  String get repsDisplay {
    if (targetRepsMin != null && targetRepsMax != null) {
      if (targetRepsMin == targetRepsMax) return '$targetRepsMin';
      return '$targetRepsMin-$targetRepsMax';
    }
    return '$targetReps';
  }

  RoutineExercise copyWith({
    String? id,
    String? routineId,
    String? exerciseId,
    int? targetSets,
    int? targetReps,
    Object? targetRepsMin = _sentinel,
    Object? targetRepsMax = _sentinel,
    Object? targetWeightKg = _sentinel,
    int? restSeconds,
    int? sortOrder,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RoutineExercise(
    id: id ?? this.id,
    routineId: routineId ?? this.routineId,
    exerciseId: exerciseId ?? this.exerciseId,
    targetSets: targetSets ?? this.targetSets,
    targetReps: targetReps ?? this.targetReps,
    targetRepsMin: targetRepsMin == _sentinel
        ? this.targetRepsMin
        : targetRepsMin as int?,
    targetRepsMax: targetRepsMax == _sentinel
        ? this.targetRepsMax
        : targetRepsMax as int?,
    targetWeightKg: targetWeightKg == _sentinel
        ? this.targetWeightKg
        : (targetWeightKg as num?)?.toDouble(),
    restSeconds: restSeconds ?? this.restSeconds,
    sortOrder: sortOrder ?? this.sortOrder,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'routine_id': routineId,
    'exercise_id': exerciseId,
    'target_sets': targetSets,
    'target_reps': targetReps,
    'target_reps_min': targetRepsMin,
    'target_reps_max': targetRepsMax,
    'target_weight_kg': targetWeightKg,
    'rest_seconds': restSeconds,
    'sort_order': sortOrder,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory RoutineExercise.fromMap(Map<String, dynamic> map) => RoutineExercise(
    id: map['id'] as String,
    routineId: map['routine_id'] as String,
    exerciseId: map['exercise_id'] as String,
    targetSets: map['target_sets'] as int? ?? 3,
    targetReps: map['target_reps'] as int? ?? 10,
    targetRepsMin: map['target_reps_min'] as int?,
    targetRepsMax: map['target_reps_max'] as int?,
    targetWeightKg: (map['target_weight_kg'] as num?)?.toDouble(),
    restSeconds: map['rest_seconds'] as int? ?? 60,
    sortOrder: map['sort_order'] as int? ?? 0,
    notes: map['notes'] as String? ?? '',
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineExercise &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          routineId == other.routineId &&
          exerciseId == other.exerciseId &&
          targetSets == other.targetSets &&
          targetReps == other.targetReps &&
          targetRepsMin == other.targetRepsMin &&
          targetRepsMax == other.targetRepsMax &&
          targetWeightKg == other.targetWeightKg &&
          restSeconds == other.restSeconds &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode => Object.hash(
    id,
    routineId,
    exerciseId,
    targetSets,
    targetReps,
    targetRepsMin,
    targetRepsMax,
    targetWeightKg,
    restSeconds,
    sortOrder,
  );

  @override
  String toString() =>
      'RoutineExercise(id: $id, routineId: $routineId, exerciseId: $exerciseId)';
}
