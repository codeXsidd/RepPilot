import 'package:sqflite/sqflite.dart';

import '../models/exercise.dart';

class ExerciseRepository {
  final Database _db;

  ExerciseRepository(this._db);

  Future<Exercise> create(Exercise exercise) async {
    await _db.insert(
      'exercises',
      exercise.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return exercise;
  }

  Future<Exercise?> getById(String id) async {
    final maps = await _db.query('exercises', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Exercise.fromMap(maps.first);
  }

  Future<List<Exercise>> getAll({bool includeArchived = false}) async {
    final where = includeArchived ? null : 'is_archived = 0';
    final maps = await _db.query(
      'exercises',
      where: where,
      orderBy: 'name ASC',
    );
    return maps.map(Exercise.fromMap).toList();
  }

  Future<List<Exercise>> getByCategory(
    String category, {
    bool includeArchived = false,
  }) async {
    final archiveClause = includeArchived ? '' : ' AND is_archived = 0';
    final maps = await _db.query(
      'exercises',
      where: 'category = ?$archiveClause',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return maps.map(Exercise.fromMap).toList();
  }

  Future<List<Exercise>> getByMuscleGroup(
    String muscleGroup, {
    bool includeArchived = false,
  }) async {
    final archiveClause = includeArchived ? '' : ' AND is_archived = 0';
    final maps = await _db.query(
      'exercises',
      where: 'muscle_group = ?$archiveClause',
      whereArgs: [muscleGroup],
      orderBy: 'name ASC',
    );
    return maps.map(Exercise.fromMap).toList();
  }

  Future<List<Exercise>> search(String query) async {
    if (query.isEmpty) return getAll();
    final pattern = '%$query%';
    final maps = await _db.query(
      'exercises',
      where:
          '(name LIKE ? OR muscle_group LIKE ? OR category LIKE ? OR equipment LIKE ?) '
          'AND is_archived = 0',
      whereArgs: [pattern, pattern, pattern, pattern],
      orderBy: 'name ASC',
    );
    return maps.map(Exercise.fromMap).toList();
  }

  Future<List<String>> getDistinctCategories() async {
    final maps = await _db.rawQuery(
      'SELECT DISTINCT category FROM exercises WHERE is_archived = 0 ORDER BY category ASC',
    );
    return maps.map((m) => m['category'] as String).toList();
  }

  Future<int> update(Exercise exercise) async {
    return _db.update(
      'exercises',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<int> archive(String id) async {
    return _db.update(
      'exercises',
      {'is_archived': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(String id) async {
    return _db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> hasDefaultExercises() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM exercises WHERE is_custom = 0',
    );
    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  Future<void> seedDefaults(List<Exercise> exercises) async {
    final hasDefaults = await hasDefaultExercises();
    if (hasDefaults) return;
    final batch = _db.batch();
    for (final e in exercises) {
      batch.insert(
        'exercises',
        e.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }
}
