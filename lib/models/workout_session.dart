import 'package:flutter/foundation.dart';

const _sentinel = Object();

@immutable
class WorkoutSession {
  final String id;
  final String? routineId;
  final String routineName;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutSession({
    required this.id,
    this.routineId,
    this.routineName = '',
    required this.startedAt,
    this.completedAt,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => completedAt == null;

  Duration? get duration => completedAt?.difference(startedAt);

  WorkoutSession copyWith({
    String? id,
    Object? routineId = _sentinel,
    String? routineName,
    DateTime? startedAt,
    Object? completedAt = _sentinel,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WorkoutSession(
    id: id ?? this.id,
    routineId: routineId == _sentinel ? this.routineId : routineId as String?,
    routineName: routineName ?? this.routineName,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt == _sentinel
        ? this.completedAt
        : completedAt as DateTime?,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'routine_id': routineId,
    'routine_name': routineName,
    'started_at': startedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory WorkoutSession.fromMap(Map<String, dynamic> map) => WorkoutSession(
    id: map['id'] as String,
    routineId: map['routine_id'] as String?,
    routineName: map['routine_name'] as String? ?? '',
    startedAt: DateTime.parse(map['started_at'] as String),
    completedAt: map['completed_at'] != null
        ? DateTime.parse(map['completed_at'] as String)
        : null,
    notes: map['notes'] as String? ?? '',
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          routineId == other.routineId &&
          routineName == other.routineName &&
          startedAt == other.startedAt &&
          completedAt == other.completedAt &&
          notes == other.notes;

  @override
  int get hashCode =>
      Object.hash(id, routineId, routineName, startedAt, completedAt, notes);

  @override
  String toString() =>
      'WorkoutSession(id: $id, routineName: $routineName, isActive: $isActive)';
}
