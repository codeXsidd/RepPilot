import 'package:sqflite/sqflite.dart';

import '../models/workout_set.dart';

class WorkoutSetRepository {
  final Database _db;

  WorkoutSetRepository(this._db);

  Future<WorkoutSet> create(WorkoutSet set) async {
    await _db.insert(
      'workout_sets',
      set.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return set;
  }

  Future<WorkoutSet?> getById(String id) async {
    final maps = await _db.query(
      'workout_sets',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return WorkoutSet.fromMap(maps.first);
  }

  Future<List<WorkoutSet>> getBySessionId(String sessionId) async {
    final maps = await _db.query(
      'workout_sets',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'exercise_id ASC, set_number ASC',
    );
    return maps.map(WorkoutSet.fromMap).toList();
  }

  Future<List<WorkoutSet>> getByExerciseId(
    String exerciseId, {
    int? limit,
  }) async {
    final maps = await _db.rawQuery(
      'SELECT ws.* FROM workout_sets ws '
      'JOIN workout_sessions s ON ws.session_id = s.id '
      'WHERE ws.exercise_id = ? AND ws.completed = 1 '
      'ORDER BY s.started_at DESC, ws.set_number ASC '
      '${limit != null ? 'LIMIT ?' : ''}',
      [exerciseId, ?limit],
    );
    return maps.map(WorkoutSet.fromMap).toList();
  }

  Future<List<WorkoutSet>> getAllCompleted() async {
    final maps = await _db.rawQuery(
      'SELECT ws.* FROM workout_sets ws '
      'JOIN workout_sessions s ON ws.session_id = s.id '
      'WHERE s.completed_at IS NOT NULL '
      'ORDER BY s.started_at ASC, ws.set_number ASC',
    );
    return maps.map(WorkoutSet.fromMap).toList();
  }

  Future<int> update(WorkoutSet set) async {
    return _db.update(
      'workout_sets',
      set.toMap(),
      where: 'id = ?',
      whereArgs: [set.id],
    );
  }

  Future<int> markCompleted(String id, {DateTime? completedAt}) async {
    final now = completedAt ?? DateTime.now();
    return _db.update(
      'workout_sets',
      {'completed': 1, 'completed_at': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(String id) async {
    return _db.delete('workout_sets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBySessionId(String sessionId) async {
    return _db.delete(
      'workout_sets',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }
}
