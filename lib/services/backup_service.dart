import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../core/database/schema.dart';

const List<String> kTableInsertOrder = [
  'user_profile',
  'exercises',
  'foods',
  'routines',
  'body_weight_entries',
  'food_entries',
  'water_entries',
  'personal_goals',
  'body_measurements',
  'meal_templates',
  'routine_exercises',
  'exercise_settings',
  'workout_sessions',
  'workout_sets',
  'overload_recommendations',
  'meal_template_items',
];

const String kBackupFormat = 'reppilot_backup';
const int kBackupVersion = 1;

class BackupValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const BackupValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
}

class RestorePreview {
  final Map<String, int> recordCounts;
  final int schemaVersion;
  final String exportedAt;
  final int totalRecords;

  const RestorePreview({
    required this.recordCounts,
    required this.schemaVersion,
    required this.exportedAt,
    required this.totalRecords,
  });
}

class RestoreResult {
  final bool success;
  final int recordsRestored;
  final List<String> warnings;

  const RestoreResult({
    required this.success,
    required this.recordsRestored,
    this.warnings = const [],
  });
}

class BackupService {
  final Database _db;

  BackupService(this._db);

  static List<String> get tableDeleteOrder =>
      kTableInsertOrder.reversed.toList();

  Future<Map<String, dynamic>> exportToJson() async {
    final tables = <String, List<Map<String, dynamic>>>{};
    for (final table in kTableInsertOrder) {
      tables[table] = await _db.query(table);
    }
    return {
      'format': kBackupFormat,
      'version': kBackupVersion,
      'schemaVersion': currentSchemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'appVersion': '1.0.0',
      'tables': tables,
    };
  }

  String encodeJson(Map<String, dynamic> backup) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backup);
  }

  Map<String, dynamic>? parseBackupJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<String> exportTableToCsv(String tableName) async {
    final rows = await _db.query(tableName);
    if (rows.isEmpty) return '';

    final columns = rows.first.keys.toList();
    final buffer = StringBuffer();
    buffer.writeln(columns.join(','));

    for (final row in rows) {
      final values = columns.map((col) {
        final value = row[col];
        if (value == null) return '';
        final str = value.toString();
        if (str.contains(',') || str.contains('"') || str.contains('\n')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      });
      buffer.writeln(values.join(','));
    }

    return buffer.toString();
  }

  BackupValidationResult validateBackup(Map<String, dynamic> data) {
    final errors = <String>[];
    final warnings = <String>[];

    if (data['format'] != kBackupFormat) {
      errors.add('Invalid backup format: expected "$kBackupFormat"');
      return BackupValidationResult(isValid: false, errors: errors);
    }

    final version = data['version'];
    if (version is! int || version < 1) {
      errors.add('Invalid backup version');
      return BackupValidationResult(isValid: false, errors: errors);
    }
    if (version > kBackupVersion) {
      errors.add(
        'Backup version $version is newer than supported ($kBackupVersion)',
      );
      return BackupValidationResult(isValid: false, errors: errors);
    }

    final schemaVer = data['schemaVersion'];
    if (schemaVer is! int || schemaVer < 1) {
      errors.add('Invalid schema version');
      return BackupValidationResult(isValid: false, errors: errors);
    }
    if (schemaVer > currentSchemaVersion) {
      errors.add(
        'Backup schema version $schemaVer is newer than '
        'current ($currentSchemaVersion)',
      );
      return BackupValidationResult(isValid: false, errors: errors);
    }
    if (schemaVer < currentSchemaVersion) {
      warnings.add(
        'Backup from older schema version $schemaVer '
        '(current: $currentSchemaVersion). Some fields may use defaults.',
      );
    }

    final tables = data['tables'];
    if (tables is! Map<String, dynamic>) {
      errors.add('Missing or invalid "tables" field');
      return BackupValidationResult(isValid: false, errors: errors);
    }

    for (final entry in tables.entries) {
      final tableName = entry.key;
      final rows = entry.value;

      if (!kTableInsertOrder.contains(tableName)) {
        warnings.add('Unknown table "$tableName" will be skipped');
        continue;
      }

      if (rows is! List) {
        errors.add('Table "$tableName" data is not a list');
        continue;
      }

      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row is! Map<String, dynamic>) {
          errors.add('Table "$tableName" row $i is not a valid record');
          continue;
        }
        if (!row.containsKey('id')) {
          warnings.add('Table "$tableName" row $i missing "id" — will skip');
        }
      }
    }

    return BackupValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  RestorePreview? getRestorePreview(Map<String, dynamic> data) {
    final validation = validateBackup(data);
    if (!validation.isValid) return null;

    final tables = data['tables'] as Map<String, dynamic>;
    final counts = <String, int>{};
    var total = 0;

    for (final table in kTableInsertOrder) {
      final rows = tables[table];
      final count = (rows is List) ? rows.length : 0;
      counts[table] = count;
      total += count;
    }

    return RestorePreview(
      recordCounts: counts,
      schemaVersion: data['schemaVersion'] as int,
      exportedAt: (data['exportedAt'] as String?) ?? 'Unknown',
      totalRecords: total,
    );
  }

  Future<RestoreResult> restoreFromJson(Map<String, dynamic> data) async {
    final validation = validateBackup(data);
    if (!validation.isValid) {
      throw BackupRestoreException(
        'Invalid backup: ${validation.errors.join('; ')}',
      );
    }

    final tables = data['tables'] as Map<String, dynamic>;
    final warnings = <String>[...validation.warnings];

    final tableColumns = <String, Set<String>>{};
    for (final table in kTableInsertOrder) {
      final info = await _db.rawQuery('PRAGMA table_info($table)');
      tableColumns[table] = info.map((r) => r['name'] as String).toSet();
    }

    var totalInserted = 0;

    await _db.execute('PRAGMA foreign_keys = OFF');
    try {
      await _db.transaction((txn) async {
        for (final table in tableDeleteOrder) {
          await txn.delete(table);
        }

        for (final table in kTableInsertOrder) {
          final rows = tables[table];
          if (rows is! List || rows.isEmpty) continue;

          final validCols = tableColumns[table] ?? <String>{};
          var tableInserted = 0;

          for (final row in rows) {
            if (row is! Map<String, dynamic>) continue;
            final sanitized = _sanitizeRow(row, validCols);
            if (sanitized.isEmpty || !sanitized.containsKey('id')) continue;

            await txn.insert(
              table,
              sanitized,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            tableInserted++;
          }
          totalInserted += tableInserted;
        }
      });
    } catch (e) {
      await _db.execute('PRAGMA foreign_keys = ON');
      rethrow;
    }

    await _db.execute('PRAGMA foreign_keys = ON');

    final fkCheck = await _db.rawQuery('PRAGMA foreign_key_check');
    if (fkCheck.isNotEmpty) {
      warnings.add(
        '${fkCheck.length} foreign key issue(s) detected. '
        'Some cross-references may be incomplete.',
      );
    }

    return RestoreResult(
      success: true,
      recordsRestored: totalInserted,
      warnings: warnings,
    );
  }

  Future<void> resetAllData() async {
    await _db.execute('PRAGMA foreign_keys = OFF');
    try {
      await _db.transaction((txn) async {
        for (final table in tableDeleteOrder) {
          await txn.delete(table);
        }
      });
    } finally {
      await _db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Map<String, dynamic> _sanitizeRow(
    Map<String, dynamic> row,
    Set<String> validColumns,
  ) {
    final sanitized = <String, dynamic>{};
    for (final entry in row.entries) {
      if (!validColumns.contains(entry.key)) continue;
      final value = entry.value;
      if (value is bool) {
        sanitized[entry.key] = value ? 1 : 0;
      } else if (value == null ||
          value is int ||
          value is double ||
          value is String) {
        sanitized[entry.key] = value;
      } else {
        sanitized[entry.key] = value.toString();
      }
    }
    return sanitized;
  }
}

class BackupRestoreException implements Exception {
  final String message;
  const BackupRestoreException(this.message);

  @override
  String toString() => 'BackupRestoreException: $message';
}
