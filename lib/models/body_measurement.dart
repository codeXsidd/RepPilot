import 'package:flutter/foundation.dart';

import '../core/constants.dart';

const _sentinel = Object();

@immutable
class BodyMeasurement {
  final String id;
  final DateTime date;
  final double? waistCm;
  final double? chestCm;
  final double? leftArmCm;
  final double? rightArmCm;
  final double? hipsCm;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BodyMeasurement({
    required this.id,
    required this.date,
    this.waistCm,
    this.chestCm,
    this.leftArmCm,
    this.rightArmCm,
    this.hipsCm,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasAnyMeasurement =>
      waistCm != null ||
      chestCm != null ||
      leftArmCm != null ||
      rightArmCm != null ||
      hipsCm != null;

  BodyMeasurement copyWith({
    String? id,
    DateTime? date,
    Object? waistCm = _sentinel,
    Object? chestCm = _sentinel,
    Object? leftArmCm = _sentinel,
    Object? rightArmCm = _sentinel,
    Object? hipsCm = _sentinel,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BodyMeasurement(
    id: id ?? this.id,
    date: date ?? this.date,
    waistCm: waistCm == _sentinel ? this.waistCm : waistCm as double?,
    chestCm: chestCm == _sentinel ? this.chestCm : chestCm as double?,
    leftArmCm: leftArmCm == _sentinel ? this.leftArmCm : leftArmCm as double?,
    rightArmCm: rightArmCm == _sentinel
        ? this.rightArmCm
        : rightArmCm as double?,
    hipsCm: hipsCm == _sentinel ? this.hipsCm : hipsCm as double?,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': formatDateOnly(date),
    'waist_cm': waistCm,
    'chest_cm': chestCm,
    'left_arm_cm': leftArmCm,
    'right_arm_cm': rightArmCm,
    'hips_cm': hipsCm,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory BodyMeasurement.fromMap(Map<String, dynamic> map) => BodyMeasurement(
    id: map['id'] as String,
    date: parseDateOnly(map['date'] as String),
    waistCm: (map['waist_cm'] as num?)?.toDouble(),
    chestCm: (map['chest_cm'] as num?)?.toDouble(),
    leftArmCm: (map['left_arm_cm'] as num?)?.toDouble(),
    rightArmCm: (map['right_arm_cm'] as num?)?.toDouble(),
    hipsCm: (map['hips_cm'] as num?)?.toDouble(),
    notes: map['notes'] as String? ?? '',
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyMeasurement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          waistCm == other.waistCm &&
          chestCm == other.chestCm &&
          leftArmCm == other.leftArmCm &&
          rightArmCm == other.rightArmCm &&
          hipsCm == other.hipsCm;

  @override
  int get hashCode =>
      Object.hash(id, date, waistCm, chestCm, leftArmCm, rightArmCm, hipsCm);

  @override
  String toString() =>
      'BodyMeasurement(id: $id, date: ${formatDateOnly(date)})';
}
