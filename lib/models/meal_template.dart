import 'package:flutter/foundation.dart';

@immutable
class MealTemplate {
  final String id;
  final String name;
  final String mealType;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MealTemplate({
    required this.id,
    required this.name,
    this.mealType = 'snack',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  MealTemplate copyWith({
    String? id,
    String? name,
    String? mealType,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MealTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    mealType: mealType ?? this.mealType,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'meal_type': mealType,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory MealTemplate.fromMap(Map<String, dynamic> map) => MealTemplate(
    id: map['id'] as String,
    name: map['name'] as String,
    mealType: map['meal_type'] as String? ?? 'snack',
    notes: map['notes'] as String? ?? '',
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          mealType == other.mealType &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(id, name, mealType, notes);

  @override
  String toString() =>
      'MealTemplate(id: $id, name: $name, mealType: $mealType)';
}
