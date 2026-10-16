import 'package:flutter/foundation.dart';

const _sentinel = Object();

@immutable
class OverloadRecommendation {
  final String id;
  final String exerciseId;
  final String? sessionId;
  final double? recommendedWeightKg;
  final int? recommendedReps;
  final double? previousWeightKg;
  final int? previousReps;
  final String reasoning;
  final String status;
  final DateTime createdAt;

  const OverloadRecommendation({
    required this.id,
    required this.exerciseId,
    this.sessionId,
    this.recommendedWeightKg,
    this.recommendedReps,
    this.previousWeightKg,
    this.previousReps,
    this.reasoning = '',
    this.status = 'pending',
    required this.createdAt,
  });

  OverloadRecommendation copyWith({
    String? id,
    String? exerciseId,
    Object? sessionId = _sentinel,
    Object? recommendedWeightKg = _sentinel,
    Object? recommendedReps = _sentinel,
    Object? previousWeightKg = _sentinel,
    Object? previousReps = _sentinel,
    String? reasoning,
    String? status,
    DateTime? createdAt,
  }) => OverloadRecommendation(
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    sessionId: sessionId == _sentinel ? this.sessionId : sessionId as String?,
    recommendedWeightKg: recommendedWeightKg == _sentinel
        ? this.recommendedWeightKg
        : recommendedWeightKg as double?,
    recommendedReps: recommendedReps == _sentinel
        ? this.recommendedReps
        : recommendedReps as int?,
    previousWeightKg: previousWeightKg == _sentinel
        ? this.previousWeightKg
        : previousWeightKg as double?,
    previousReps: previousReps == _sentinel
        ? this.previousReps
        : previousReps as int?,
    reasoning: reasoning ?? this.reasoning,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'exercise_id': exerciseId,
    'session_id': sessionId,
    'recommended_weight_kg': recommendedWeightKg,
    'recommended_reps': recommendedReps,
    'previous_weight_kg': previousWeightKg,
    'previous_reps': previousReps,
    'reasoning': reasoning,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };

  factory OverloadRecommendation.fromMap(Map<String, dynamic> map) =>
      OverloadRecommendation(
        id: map['id'] as String,
        exerciseId: map['exercise_id'] as String,
        sessionId: map['session_id'] as String?,
        recommendedWeightKg: (map['recommended_weight_kg'] as num?)?.toDouble(),
        recommendedReps: map['recommended_reps'] as int?,
        previousWeightKg: (map['previous_weight_kg'] as num?)?.toDouble(),
        previousReps: map['previous_reps'] as int?,
        reasoning: map['reasoning'] as String? ?? '',
        status: map['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverloadRecommendation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          exerciseId == other.exerciseId &&
          sessionId == other.sessionId &&
          recommendedWeightKg == other.recommendedWeightKg &&
          recommendedReps == other.recommendedReps &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
    id,
    exerciseId,
    sessionId,
    recommendedWeightKg,
    recommendedReps,
    status,
  );

  @override
  String toString() =>
      'OverloadRecommendation(id: $id, exerciseId: $exerciseId, '
      'weight: $recommendedWeightKg, reps: $recommendedReps, '
      'status: $status)';
}
