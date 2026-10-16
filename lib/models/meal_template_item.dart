import 'package:flutter/foundation.dart';

@immutable
class MealTemplateItem {
  final String id;
  final String templateId;
  final String foodId;
  final double servings;
  final DateTime createdAt;

  const MealTemplateItem({
    required this.id,
    required this.templateId,
    required this.foodId,
    this.servings = 1.0,
    required this.createdAt,
  });

  MealTemplateItem copyWith({
    String? id,
    String? templateId,
    String? foodId,
    double? servings,
    DateTime? createdAt,
  }) => MealTemplateItem(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    foodId: foodId ?? this.foodId,
    servings: servings ?? this.servings,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'template_id': templateId,
    'food_id': foodId,
    'servings': servings,
    'created_at': createdAt.toIso8601String(),
  };

  factory MealTemplateItem.fromMap(Map<String, dynamic> map) =>
      MealTemplateItem(
        id: map['id'] as String,
        templateId: map['template_id'] as String,
        foodId: map['food_id'] as String,
        servings: (map['servings'] as num?)?.toDouble() ?? 1.0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealTemplateItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          templateId == other.templateId &&
          foodId == other.foodId &&
          servings == other.servings;

  @override
  int get hashCode => Object.hash(id, templateId, foodId, servings);

  @override
  String toString() =>
      'MealTemplateItem(id: $id, templateId: $templateId, '
      'foodId: $foodId, servings: $servings)';
}
