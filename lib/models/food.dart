import 'package:flutter/foundation.dart';

@immutable
class Food {
  final String id;
  final String name;
  final String category;
  final double servingSize;
  final String servingUnit;
  final double caloriesPerServing;
  final double proteinPerServing;
  final double carbsPerServing;
  final double fatPerServing;
  final bool isCustom;
  final bool isEstimate;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Food({
    required this.id,
    required this.name,
    this.category = 'other',
    this.servingSize = 1.0,
    this.servingUnit = 'serving',
    this.caloriesPerServing = 0,
    this.proteinPerServing = 0,
    this.carbsPerServing = 0,
    this.fatPerServing = 0,
    this.isCustom = true,
    this.isEstimate = false,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  double caloriesFor(double servings) => caloriesPerServing * servings;
  double proteinFor(double servings) => proteinPerServing * servings;
  double carbsFor(double servings) => carbsPerServing * servings;
  double fatFor(double servings) => fatPerServing * servings;

  Food copyWith({
    String? id,
    String? name,
    String? category,
    double? servingSize,
    String? servingUnit,
    double? caloriesPerServing,
    double? proteinPerServing,
    double? carbsPerServing,
    double? fatPerServing,
    bool? isCustom,
    bool? isEstimate,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Food(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    servingSize: servingSize ?? this.servingSize,
    servingUnit: servingUnit ?? this.servingUnit,
    caloriesPerServing: caloriesPerServing ?? this.caloriesPerServing,
    proteinPerServing: proteinPerServing ?? this.proteinPerServing,
    carbsPerServing: carbsPerServing ?? this.carbsPerServing,
    fatPerServing: fatPerServing ?? this.fatPerServing,
    isCustom: isCustom ?? this.isCustom,
    isEstimate: isEstimate ?? this.isEstimate,
    isFavorite: isFavorite ?? this.isFavorite,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'serving_size': servingSize,
    'serving_unit': servingUnit,
    'calories_per_serving': caloriesPerServing,
    'protein_per_serving': proteinPerServing,
    'carbs_per_serving': carbsPerServing,
    'fat_per_serving': fatPerServing,
    'is_custom': isCustom ? 1 : 0,
    'is_estimate': isEstimate ? 1 : 0,
    'is_favorite': isFavorite ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Food.fromMap(Map<String, dynamic> map) => Food(
    id: map['id'] as String,
    name: map['name'] as String,
    category: map['category'] as String? ?? 'other',
    servingSize: (map['serving_size'] as num?)?.toDouble() ?? 1.0,
    servingUnit: map['serving_unit'] as String? ?? 'serving',
    caloriesPerServing: (map['calories_per_serving'] as num?)?.toDouble() ?? 0,
    proteinPerServing: (map['protein_per_serving'] as num?)?.toDouble() ?? 0,
    carbsPerServing: (map['carbs_per_serving'] as num?)?.toDouble() ?? 0,
    fatPerServing: (map['fat_per_serving'] as num?)?.toDouble() ?? 0,
    isCustom: (map['is_custom'] as int?) == 1,
    isEstimate: (map['is_estimate'] as int?) == 1,
    isFavorite: (map['is_favorite'] as int?) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Food &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          servingSize == other.servingSize &&
          servingUnit == other.servingUnit &&
          caloriesPerServing == other.caloriesPerServing &&
          proteinPerServing == other.proteinPerServing &&
          isCustom == other.isCustom &&
          isFavorite == other.isFavorite;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    servingSize,
    servingUnit,
    caloriesPerServing,
    proteinPerServing,
    isCustom,
    isFavorite,
  );

  @override
  String toString() =>
      'Food(id: $id, name: $name, category: $category, '
      'cal: $caloriesPerServing per $servingSize $servingUnit)';
}
