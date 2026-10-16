import 'package:flutter/foundation.dart';

const _sentinel = Object();

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

  final String secondaryMuscles;
  final String difficulty;
  final String description;
  final String instructions;
  final String movementPattern;
  final int defaultSets;
  final int defaultRepsMin;
  final int defaultRepsMax;
  final int defaultRestSeconds;
  final double defaultIncrementKg;
  final String aliases;
  final String substitutionIds;
  final bool isBodyweight;
  final bool isUnilateral;
  final bool isMachine;
  final bool suitableForHome;
  final bool suitableForGym;
  final bool isFavorite;
  final DateTime? lastUsedAt;
  final String safetyNotes;

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
    this.secondaryMuscles = '',
    this.difficulty = 'intermediate',
    this.description = '',
    this.instructions = '',
    this.movementPattern = '',
    this.defaultSets = 3,
    this.defaultRepsMin = 8,
    this.defaultRepsMax = 12,
    this.defaultRestSeconds = 60,
    this.defaultIncrementKg = 2.5,
    this.aliases = '',
    this.substitutionIds = '',
    this.isBodyweight = false,
    this.isUnilateral = false,
    this.isMachine = false,
    this.suitableForHome = false,
    this.suitableForGym = true,
    this.isFavorite = false,
    this.lastUsedAt,
    this.safetyNotes = '',
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
    String? secondaryMuscles,
    String? difficulty,
    String? description,
    String? instructions,
    String? movementPattern,
    int? defaultSets,
    int? defaultRepsMin,
    int? defaultRepsMax,
    int? defaultRestSeconds,
    double? defaultIncrementKg,
    String? aliases,
    String? substitutionIds,
    bool? isBodyweight,
    bool? isUnilateral,
    bool? isMachine,
    bool? suitableForHome,
    bool? suitableForGym,
    bool? isFavorite,
    Object? lastUsedAt = _sentinel,
    String? safetyNotes,
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
    secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
    difficulty: difficulty ?? this.difficulty,
    description: description ?? this.description,
    instructions: instructions ?? this.instructions,
    movementPattern: movementPattern ?? this.movementPattern,
    defaultSets: defaultSets ?? this.defaultSets,
    defaultRepsMin: defaultRepsMin ?? this.defaultRepsMin,
    defaultRepsMax: defaultRepsMax ?? this.defaultRepsMax,
    defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
    defaultIncrementKg: defaultIncrementKg ?? this.defaultIncrementKg,
    aliases: aliases ?? this.aliases,
    substitutionIds: substitutionIds ?? this.substitutionIds,
    isBodyweight: isBodyweight ?? this.isBodyweight,
    isUnilateral: isUnilateral ?? this.isUnilateral,
    isMachine: isMachine ?? this.isMachine,
    suitableForHome: suitableForHome ?? this.suitableForHome,
    suitableForGym: suitableForGym ?? this.suitableForGym,
    isFavorite: isFavorite ?? this.isFavorite,
    lastUsedAt: identical(lastUsedAt, _sentinel)
        ? this.lastUsedAt
        : lastUsedAt as DateTime?,
    safetyNotes: safetyNotes ?? this.safetyNotes,
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
    'secondary_muscles': secondaryMuscles,
    'difficulty': difficulty,
    'description': description,
    'instructions': instructions,
    'movement_pattern': movementPattern,
    'default_sets': defaultSets,
    'default_reps_min': defaultRepsMin,
    'default_reps_max': defaultRepsMax,
    'default_rest_seconds': defaultRestSeconds,
    'default_increment_kg': defaultIncrementKg,
    'aliases': aliases,
    'substitution_ids': substitutionIds,
    'is_bodyweight': isBodyweight ? 1 : 0,
    'is_unilateral': isUnilateral ? 1 : 0,
    'is_machine': isMachine ? 1 : 0,
    'suitable_for_home': suitableForHome ? 1 : 0,
    'suitable_for_gym': suitableForGym ? 1 : 0,
    'is_favorite': isFavorite ? 1 : 0,
    'last_used_at': lastUsedAt?.toIso8601String(),
    'safety_notes': safetyNotes,
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
    secondaryMuscles: map['secondary_muscles'] as String? ?? '',
    difficulty: map['difficulty'] as String? ?? 'intermediate',
    description: map['description'] as String? ?? '',
    instructions: map['instructions'] as String? ?? '',
    movementPattern: map['movement_pattern'] as String? ?? '',
    defaultSets: map['default_sets'] as int? ?? 3,
    defaultRepsMin: map['default_reps_min'] as int? ?? 8,
    defaultRepsMax: map['default_reps_max'] as int? ?? 12,
    defaultRestSeconds: map['default_rest_seconds'] as int? ?? 60,
    defaultIncrementKg:
        (map['default_increment_kg'] as num?)?.toDouble() ?? 2.5,
    aliases: map['aliases'] as String? ?? '',
    substitutionIds: map['substitution_ids'] as String? ?? '',
    isBodyweight: (map['is_bodyweight'] as int?) == 1,
    isUnilateral: (map['is_unilateral'] as int?) == 1,
    isMachine: (map['is_machine'] as int?) == 1,
    suitableForHome: (map['suitable_for_home'] as int?) == 1,
    suitableForGym: (map['suitable_for_gym'] as int?) != 0,
    isFavorite: (map['is_favorite'] as int?) == 1,
    lastUsedAt: map['last_used_at'] != null
        ? DateTime.parse(map['last_used_at'] as String)
        : null,
    safetyNotes: map['safety_notes'] as String? ?? '',
  );

  List<String> get aliasList => aliases.isEmpty
      ? const []
      : aliases.split(',').map((a) => a.trim()).toList();

  List<String> get secondaryMuscleList => secondaryMuscles.isEmpty
      ? const []
      : secondaryMuscles.split(',').map((m) => m.trim()).toList();

  List<String> get substitutionIdList => substitutionIds.isEmpty
      ? const []
      : substitutionIds.split(',').map((s) => s.trim()).toList();

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
