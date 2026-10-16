import 'package:sqflite/sqflite.dart';

import '../models/overload_recommendation.dart';

class OverloadRecommendationRepository {
  final Database _db;

  OverloadRecommendationRepository(this._db);

  Future<OverloadRecommendation> create(
    OverloadRecommendation recommendation,
  ) async {
    await _db.insert(
      'overload_recommendations',
      recommendation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return recommendation;
  }

  Future<OverloadRecommendation?> getById(String id) async {
    final maps = await _db.query(
      'overload_recommendations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return OverloadRecommendation.fromMap(maps.first);
  }

  Future<List<OverloadRecommendation>> getByExerciseId(
    String exerciseId,
  ) async {
    final maps = await _db.query(
      'overload_recommendations',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'created_at DESC',
    );
    return maps.map(OverloadRecommendation.fromMap).toList();
  }

  Future<OverloadRecommendation?> getLatestForExercise(
    String exerciseId,
  ) async {
    final maps = await _db.query(
      'overload_recommendations',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return OverloadRecommendation.fromMap(maps.first);
  }

  Future<List<OverloadRecommendation>> getBySessionId(String sessionId) async {
    final maps = await _db.query(
      'overload_recommendations',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at DESC',
    );
    return maps.map(OverloadRecommendation.fromMap).toList();
  }

  Future<int> update(OverloadRecommendation recommendation) async {
    return _db.update(
      'overload_recommendations',
      recommendation.toMap(),
      where: 'id = ?',
      whereArgs: [recommendation.id],
    );
  }

  Future<int> updateStatus(String id, String status) async {
    return _db.update(
      'overload_recommendations',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(String id) async {
    return _db.delete(
      'overload_recommendations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
