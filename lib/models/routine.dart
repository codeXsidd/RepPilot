import 'package:flutter/foundation.dart';

const _sentinel = _Sentinel();

class _Sentinel {
  const _Sentinel();
}

@immutable
class Routine {
  final String id;
  final String name;
  final int? dayOfWeek;
  final int sortOrder;
  final String notes;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Routine({
    required this.id,
    required this.name,
    this.dayOfWeek,
    this.sortOrder = 0,
    this.notes = '',
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Routine copyWith({
    String? id,
    String? name,
    Object? dayOfWeek = _sentinel,
    int? sortOrder,
    String? notes,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Routine(
    id: id ?? this.id,
    name: name ?? this.name,
    dayOfWeek: identical(dayOfWeek, _sentinel)
        ? this.dayOfWeek
        : dayOfWeek as int?,
    sortOrder: sortOrder ?? this.sortOrder,
    notes: notes ?? this.notes,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'day_of_week': dayOfWeek,
    'sort_order': sortOrder,
    'notes': notes,
    'is_archived': isArchived ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Routine.fromMap(Map<String, dynamic> map) => Routine(
    id: map['id'] as String,
    name: map['name'] as String,
    dayOfWeek: map['day_of_week'] as int?,
    sortOrder: map['sort_order'] as int? ?? 0,
    notes: map['notes'] as String? ?? '',
    isArchived: (map['is_archived'] as int?) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Routine &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          dayOfWeek == other.dayOfWeek &&
          sortOrder == other.sortOrder &&
          notes == other.notes &&
          isArchived == other.isArchived;

  @override
  int get hashCode =>
      Object.hash(id, name, dayOfWeek, sortOrder, notes, isArchived);

  @override
  String toString() => 'Routine(id: $id, name: $name, dayOfWeek: $dayOfWeek)';
}
