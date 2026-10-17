import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

class DatabaseHelper {
  static const String _dbName = 'rep_pilot.db';

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  Future<String> get databasePath async {
    final dir = await getApplicationDocumentsDirectory();
    return join(dir.path, _dbName);
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    return openDatabase(
      path,
      version: currentSchemaVersion,
      onConfigure: onConfigure,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );
  }

  static Future<void> onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> onCreate(Database db, int version) async {
    await _createBaseSchema(db);
    await _runMigrations(db, 1, version);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    await _autoBackupBeforeMigration(db.path, oldVersion);
    await _runMigrations(db, oldVersion, newVersion);
  }

  static Future<void> _autoBackupBeforeMigration(
    String dbPath,
    int version,
  ) async {
    try {
      final file = File(dbPath);
      if (await file.exists()) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        await file.copy('$dbPath.v${version}_$ts.bak');
      }
    } catch (_) {
      // Best-effort backup; do not block migration on failure.
    }
  }

  static Future<void> _createBaseSchema(Database db) async {
    for (final sql in v1Tables) {
      await db.execute(sql);
    }
    for (final sql in v1Indexes) {
      await db.execute(sql);
    }
  }

  static Future<void> _runMigrations(Database db, int from, int to) async {
    if (from < 2 && to >= 2) {
      for (final sql in v1ToV2Migration) {
        await db.execute(sql);
      }
      for (final sql in v2Indexes) {
        await db.execute(sql);
      }
    }
    if (from < 3 && to >= 3) {
      for (final sql in v2ToV3Migration) {
        await db.execute(sql);
      }
    }
    if (from < 4 && to >= 4) {
      for (final sql in v3ToV4Migration) {
        await db.execute(sql);
      }
      for (final sql in v4Indexes) {
        await db.execute(sql);
      }
    }
    if (from < 5 && to >= 5) {
      for (final sql in v4ToV5Migration) {
        await db.execute(sql);
      }
      for (final sql in v5Indexes) {
        await db.execute(sql);
      }
    }
    if (from < 6 && to >= 6) {
      for (final sql in v5ToV6Migration) {
        await db.execute(sql);
      }
      for (final sql in v6Indexes) {
        await db.execute(sql);
      }
    }
    if (from < 7 && to >= 7) {
      for (final sql in v6ToV7Migration) {
        await db.execute(sql);
      }
      for (final sql in v7Indexes) {
        await db.execute(sql);
      }
    }
    if (from < 8 && to >= 8) {
      for (final sql in v7ToV8Migration) {
        await db.execute(sql);
      }
      for (final sql in v8Indexes) {
        await db.execute(sql);
      }
    }
  }

  static Future<void> createAllTables(Database db) async {
    await _createBaseSchema(db);
    await _runMigrations(db, 1, currentSchemaVersion);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
