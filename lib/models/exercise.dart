import 'package:flutter/foundation.dart';

@immutable
class Exercise {
  final String id;
  final String name;
  final String category;
  final String muscleGroup;
  final String equipment;
  final String notes;
  final bool isCustom;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Exercise({
    required this.id,
    required this.name,
    this.category = 'other',
    this.muscleGroup = '',
    this.equipment = '',
    this.notes = '',
    this.isCustom = true,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Exercise copyWith({
    String? id,
    String? name,
    String? category,
    String? muscleGroup,
    String? equipment,
    String? notes,
    bool? isCustom,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    muscleGroup: muscleGroup ?? this.muscleGroup,
    equipment: equipment ?? this.equipment,
    notes: notes ?? this.notes,
    isCustom: isCustom ?? this.isCustom,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'muscle_group': muscleGroup,
    'equipment': equipment,
    'notes': notes,
    'is_custom': isCustom ? 1 : 0,
    'is_archived': isArchived ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
    id: map['id'] as String,
    name: map['name'] as String,
    category: map['category'] as String? ?? 'other',
    muscleGroup: map['muscle_group'] as String? ?? '',
    equipment: map['equipment'] as String? ?? '',
    notes: map['notes'] as String? ?? '',
    isCustom: (map['is_custom'] as int?) == 1,
    isArchived: (map['is_archived'] as int?) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          muscleGroup == other.muscleGroup &&
          equipment == other.equipment &&
          notes == other.notes &&
          isCustom == other.isCustom &&
          isArchived == other.isArchived;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    muscleGroup,
    equipment,
    notes,
    isCustom,
    isArchived,
  );

  @override
  String toString() =>
      'Exercise(id: $id, name: $name, category: $category, equipment: $equipment)';
}
