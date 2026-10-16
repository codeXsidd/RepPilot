import 'package:flutter/foundation.dart';

import '../core/constants.dart';

@immutable
class WaterEntry {
  final String id;
  final DateTime date;
  final int amountMl;
  final DateTime createdAt;

  const WaterEntry({
    required this.id,
    required this.date,
    required this.amountMl,
    required this.createdAt,
  });

  WaterEntry copyWith({
    String? id,
    DateTime? date,
    int? amountMl,
    DateTime? createdAt,
  }) => WaterEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    amountMl: amountMl ?? this.amountMl,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': formatDateOnly(date),
    'amount_ml': amountMl,
    'created_at': createdAt.toIso8601String(),
  };

  factory WaterEntry.fromMap(Map<String, dynamic> map) => WaterEntry(
    id: map['id'] as String,
    date: parseDateOnly(map['date'] as String),
    amountMl: map['amount_ml'] as int,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaterEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          amountMl == other.amountMl;

  @override
  int get hashCode => Object.hash(id, date, amountMl);

  @override
  String toString() =>
      'WaterEntry(id: $id, date: ${formatDateOnly(date)}, amountMl: $amountMl)';
}
