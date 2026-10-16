import 'package:flutter/foundation.dart';

const _sentinel = Object();

@immutable
class PersonalGoal {
  final String id;
  final String goalType;
  final double targetValue;
  final String unit;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PersonalGoal({
    required this.id,
    required this.goalType,
    required this.targetValue,
    this.unit = '',
    this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  PersonalGoal copyWith({
    String? id,
    String? goalType,
    double? targetValue,
    String? unit,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PersonalGoal(
    id: id ?? this.id,
    goalType: goalType ?? this.goalType,
    targetValue: targetValue ?? this.targetValue,
    unit: unit ?? this.unit,
    startDate: startDate == _sentinel ? this.startDate : startDate as DateTime?,
    endDate: endDate == _sentinel ? this.endDate : endDate as DateTime?,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'goal_type': goalType,
    'target_value': targetValue,
    'unit': unit,
    'start_date': startDate?.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory PersonalGoal.fromMap(Map<String, dynamic> map) => PersonalGoal(
    id: map['id'] as String,
    goalType: map['goal_type'] as String,
    targetValue: (map['target_value'] as num).toDouble(),
    unit: map['unit'] as String? ?? '',
    startDate: map['start_date'] != null
        ? DateTime.parse(map['start_date'] as String)
        : null,
    endDate: map['end_date'] != null
        ? DateTime.parse(map['end_date'] as String)
        : null,
    isActive: (map['is_active'] as int?) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalGoal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          goalType == other.goalType &&
          targetValue == other.targetValue &&
          unit == other.unit &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(id, goalType, targetValue, unit, isActive);

  @override
  String toString() =>
      'PersonalGoal(id: $id, goalType: $goalType, '
      'targetValue: $targetValue, isActive: $isActive)';
}
