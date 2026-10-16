import 'package:flutter/foundation.dart';

const _sentinel = Object();

@immutable
class WorkoutSet {
  final String id;
  final String sessionId;
  final String exerciseId;
  final String exerciseName;
  final int setNumber;
  final int? reps;
  final double? weightKg;
  final bool completed;
  final double? rpe;
  final String notes;
  final DateTime? completedAt;
  final bool isWarmup;

  const WorkoutSet({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    this.exerciseName = '',
    required this.setNumber,
    this.reps,
    this.weightKg,
    this.completed = false,
    this.rpe,
    this.notes = '',
    this.completedAt,
    this.isWarmup = false,
  });

  WorkoutSet copyWith({
    String? id,
    String? sessionId,
    String? exerciseId,
    String? exerciseName,
    int? setNumber,
    Object? reps = _sentinel,
    Object? weightKg = _sentinel,
    bool? completed,
    Object? rpe = _sentinel,
    String? notes,
    Object? completedAt = _sentinel,
    bool? isWarmup,
  }) => WorkoutSet(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    exerciseId: exerciseId ?? this.exerciseId,
    exerciseName: exerciseName ?? this.exerciseName,
    setNumber: setNumber ?? this.setNumber,
    reps: reps == _sentinel ? this.reps : reps as int?,
    weightKg: weightKg == _sentinel ? this.weightKg : weightKg as double?,
    completed: completed ?? this.completed,
    rpe: rpe == _sentinel ? this.rpe : rpe as double?,
    notes: notes ?? this.notes,
    completedAt: completedAt == _sentinel
        ? this.completedAt
        : completedAt as DateTime?,
    isWarmup: isWarmup ?? this.isWarmup,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'session_id': sessionId,
    'exercise_id': exerciseId,
    'exercise_name': exerciseName,
    'set_number': setNumber,
    'reps': reps,
    'weight_kg': weightKg,
    'completed': completed ? 1 : 0,
    'rpe': rpe,
    'notes': notes,
    'completed_at': completedAt?.toIso8601String(),
    'is_warmup': isWarmup ? 1 : 0,
  };

  factory WorkoutSet.fromMap(Map<String, dynamic> map) => WorkoutSet(
    id: map['id'] as String,
    sessionId: map['session_id'] as String,
    exerciseId: map['exercise_id'] as String,
    exerciseName: map['exercise_name'] as String? ?? '',
    setNumber: map['set_number'] as int,
    reps: map['reps'] as int?,
    weightKg: (map['weight_kg'] as num?)?.toDouble(),
    completed: (map['completed'] as int?) == 1,
    rpe: (map['rpe'] as num?)?.toDouble(),
    notes: map['notes'] as String? ?? '',
    completedAt: map['completed_at'] != null
        ? DateTime.parse(map['completed_at'] as String)
        : null,
    isWarmup: (map['is_warmup'] as int?) == 1,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSet &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          exerciseId == other.exerciseId &&
          setNumber == other.setNumber &&
          reps == other.reps &&
          weightKg == other.weightKg &&
          completed == other.completed &&
          isWarmup == other.isWarmup;

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    exerciseId,
    setNumber,
    reps,
    weightKg,
    completed,
    isWarmup,
  );

  @override
  String toString() =>
      'WorkoutSet(id: $id, exerciseName: $exerciseName, set: $setNumber, '
      'reps: $reps, weight: $weightKg${isWarmup ? ', warmup' : ''})';
}
