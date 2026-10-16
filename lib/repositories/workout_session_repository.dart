import 'package:sqflite/sqflite.dart';

import '../models/workout_session.dart';
import '../models/workout_set.dart';

class WorkoutSessionRepository {
  final Database _db;

  WorkoutSessionRepository(this._db);

  Future<WorkoutSession> create(WorkoutSession session) async {
    await _db.insert(
      'workout_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return session;
  }

  Future<WorkoutSession> createWithSets(
    WorkoutSession session,
    List<WorkoutSet> sets,
  ) async {
    await _db.transaction((txn) async {
      await txn.insert('workout_sessions', session.toMap());
      for (final s in sets) {
        await txn.insert('workout_sets', s.toMap());
      }
    });
    return session;
  }

  Future<WorkoutSession?> getById(String id) async {
    final maps = await _db.query(
      'workout_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return WorkoutSession.fromMap(maps.first);
  }

  Future<WorkoutSession?> getActiveSession() async {
    final maps = await _db.query(
      'workout_sessions',
      where: 'completed_at IS NULL',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return WorkoutSession.fromMap(maps.first);
  }

  Future<List<WorkoutSession>> getAll({int? limit, int? offset}) async {
    final maps = await _db.query(
      'workout_sessions',
      orderBy: 'started_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map(WorkoutSession.fromMap).toList();
  }

  Future<List<WorkoutSession>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final maps = await _db.query(
      'workout_sessions',
      where: 'started_at >= ? AND started_at <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'started_at DESC',
    );
    return maps.map(WorkoutSession.fromMap).toList();
  }

  Future<List<WorkoutSession>> getByRoutineId(String routineId) async {
    final maps = await _db.query(
      'workout_sessions',
      where: 'routine_id = ?',
      whereArgs: [routineId],
      orderBy: 'started_at DESC',
    );
    return maps.map(WorkoutSession.fromMap).toList();
  }

  Future<int> update(WorkoutSession session) async {
    return _db.update(
      'workout_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> complete(String id, {DateTime? completedAt}) async {
    final now = completedAt ?? DateTime.now();
    return _db.update(
      'workout_sessions',
      {
        'completed_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(String id) async {
    return _db.delete('workout_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countByDateRange(DateTime start, DateTime end) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM workout_sessions '
      'WHERE started_at >= ? AND started_at <= ? AND completed_at IS NOT NULL',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
