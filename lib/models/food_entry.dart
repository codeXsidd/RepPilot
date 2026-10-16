import 'package:flutter/foundation.dart';

import '../core/constants.dart';

const _sentinel = Object();

@immutable
class FoodEntry {
  final String id;
  final DateTime date;
  final String mealType;
  final String description;
  final double? calories;
  final double? proteinGrams;
  final double? carbsGrams;
  final double? fatGrams;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FoodEntry({
    required this.id,
    required this.date,
    this.mealType = 'snack',
    this.description = '',
    this.calories,
    this.proteinGrams,
    this.carbsGrams,
    this.fatGrams,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  FoodEntry copyWith({
    String? id,
    DateTime? date,
    String? mealType,
    String? description,
    Object? calories = _sentinel,
    Object? proteinGrams = _sentinel,
    Object? carbsGrams = _sentinel,
    Object? fatGrams = _sentinel,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FoodEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    mealType: mealType ?? this.mealType,
    description: description ?? this.description,
    calories: calories == _sentinel
        ? this.calories
        : (calories as num?)?.toDouble(),
    proteinGrams: proteinGrams == _sentinel
        ? this.proteinGrams
        : (proteinGrams as num?)?.toDouble(),
    carbsGrams: carbsGrams == _sentinel
        ? this.carbsGrams
        : (carbsGrams as num?)?.toDouble(),
    fatGrams: fatGrams == _sentinel
        ? this.fatGrams
        : (fatGrams as num?)?.toDouble(),
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': formatDateOnly(date),
    'meal_type': mealType,
    'description': description,
    'calories': calories,
    'protein_grams': proteinGrams,
    'carbs_grams': carbsGrams,
    'fat_grams': fatGrams,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory FoodEntry.fromMap(Map<String, dynamic> map) => FoodEntry(
    id: map['id'] as String,
    date: parseDateOnly(map['date'] as String),
    mealType: map['meal_type'] as String? ?? 'snack',
    description: map['description'] as String? ?? '',
    calories: (map['calories'] as num?)?.toDouble(),
    proteinGrams: (map['protein_grams'] as num?)?.toDouble(),
    carbsGrams: (map['carbs_grams'] as num?)?.toDouble(),
    fatGrams: (map['fat_grams'] as num?)?.toDouble(),
    notes: map['notes'] as String? ?? '',
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          mealType == other.mealType &&
          description == other.description &&
          calories == other.calories &&
          proteinGrams == other.proteinGrams;

  @override
  int get hashCode =>
      Object.hash(id, date, mealType, description, calories, proteinGrams);

  @override
  String toString() =>
      'FoodEntry(id: $id, date: ${formatDateOnly(date)}, '
      'mealType: $mealType, calories: $calories)';
}
