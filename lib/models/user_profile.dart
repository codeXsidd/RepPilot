import 'package:flutter/foundation.dart';

const _sentinel = Object();

@immutable
class UserProfile {
  final String id;
  final String displayName;
  final String weightUnit;
  final String themeMode;
  final double? heightCm;
  final DateTime? dateOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    this.displayName = '',
    this.weightUnit = 'kg',
    this.themeMode = 'system',
    this.heightCm,
    this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? weightUnit,
    String? themeMode,
    Object? heightCm = _sentinel,
    Object? dateOfBirth = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfile(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    weightUnit: weightUnit ?? this.weightUnit,
    themeMode: themeMode ?? this.themeMode,
    heightCm: heightCm == _sentinel
        ? this.heightCm
        : (heightCm as num?)?.toDouble(),
    dateOfBirth: dateOfBirth == _sentinel
        ? this.dateOfBirth
        : dateOfBirth as DateTime?,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'display_name': displayName,
    'weight_unit': weightUnit,
    'theme_mode': themeMode,
    'height_cm': heightCm,
    'date_of_birth': dateOfBirth?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    id: map['id'] as String,
    displayName: map['display_name'] as String? ?? '',
    weightUnit: map['weight_unit'] as String? ?? 'kg',
    themeMode: map['theme_mode'] as String? ?? 'system',
    heightCm: (map['height_cm'] as num?)?.toDouble(),
    dateOfBirth: map['date_of_birth'] != null
        ? DateTime.parse(map['date_of_birth'] as String)
        : null,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          weightUnit == other.weightUnit &&
          themeMode == other.themeMode &&
          heightCm == other.heightCm &&
          dateOfBirth == other.dateOfBirth;

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    weightUnit,
    themeMode,
    heightCm,
    dateOfBirth,
  );

  @override
  String toString() =>
      'UserProfile(id: $id, displayName: $displayName, weightUnit: $weightUnit)';
}
