import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';
import '../models/exercise_settings.dart';

class ExerciseSettingsRepository {
  final Database _db;

  ExerciseSettingsRepository(this._db);

  Future<ExerciseSettings> create(ExerciseSettings settings) async {
    await _db.insert(
      'exercise_settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return settings;
  }

  Future<ExerciseSettings?> getById(String id) async {
    final maps = await _db.query(
      'exercise_settings',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ExerciseSettings.fromMap(maps.first);
  }

  Future<ExerciseSettings?> getByExerciseId(String exerciseId) async {
    final maps = await _db.query(
      'exercise_settings',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );
    if (maps.isEmpty) return null;
    return ExerciseSettings.fromMap(maps.first);
  }

  Future<ExerciseSettings> getOrCreateForExercise(String exerciseId) async {
    final existing = await getByExerciseId(exerciseId);
    if (existing != null) return existing;

    final now = DateTime.now();
    final settings = ExerciseSettings(
      id: generateId(),
      exerciseId: exerciseId,
      createdAt: now,
      updatedAt: now,
    );
    return create(settings);
  }

  Future<int> update(ExerciseSettings settings) async {
    return _db.update(
      'exercise_settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id],
    );
  }

  Future<int> delete(String id) async {
    return _db.delete('exercise_settings', where: 'id = ?', whereArgs: [id]);
  }
}
