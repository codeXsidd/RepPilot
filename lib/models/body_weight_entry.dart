import 'package:flutter/foundation.dart';

import '../core/constants.dart';

@immutable
class BodyWeightEntry {
  final String id;
  final DateTime date;
  final double weightKg;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BodyWeightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  BodyWeightEntry copyWith({
    String? id,
    DateTime? date,
    double? weightKg,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BodyWeightEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    weightKg: weightKg ?? this.weightKg,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': formatDateOnly(date),
    'weight_kg': weightKg,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory BodyWeightEntry.fromMap(Map<String, dynamic> map) => BodyWeightEntry(
    id: map['id'] as String,
    date: parseDateOnly(map['date'] as String),
    weightKg: (map['weight_kg'] as num).toDouble(),
    notes: map['notes'] as String? ?? '',
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyWeightEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          weightKg == other.weightKg &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(id, date, weightKg, notes);

  @override
  String toString() =>
      'BodyWeightEntry(id: $id, date: ${formatDateOnly(date)}, '
      'weightKg: $weightKg)';
}
