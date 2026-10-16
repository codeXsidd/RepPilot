import 'package:sqflite/sqflite.dart';

import '../models/routine_exercise.dart';

class RoutineExerciseRepository {
  final Database _db;

  RoutineExerciseRepository(this._db);

  Future<RoutineExercise> create(RoutineExercise re) async {
    await _db.insert(
      'routine_exercises',
      re.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return re;
  }

  Future<RoutineExercise?> getById(String id) async {
    final maps = await _db.query(
      'routine_exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return RoutineExercise.fromMap(maps.first);
  }

  Future<List<RoutineExercise>> getByRoutineId(String routineId) async {
    final maps = await _db.query(
      'routine_exercises',
      where: 'routine_id = ?',
      whereArgs: [routineId],
      orderBy: 'sort_order ASC',
    );
    return maps.map(RoutineExercise.fromMap).toList();
  }

  Future<int> update(RoutineExercise re) async {
    return _db.update(
      'routine_exercises',
      re.toMap(),
      where: 'id = ?',
      whereArgs: [re.id],
    );
  }

  Future<void> reorder(String routineId, List<String> orderedIds) async {
    await _db.transaction((txn) async {
      for (var i = 0; i < orderedIds.length; i++) {
        await txn.update(
          'routine_exercises',
          {'sort_order': i},
          where: 'id = ? AND routine_id = ?',
          whereArgs: [orderedIds[i], routineId],
        );
      }
    });
  }

  Future<int> delete(String id) async {
    return _db.delete('routine_exercises', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllForRoutine(String routineId) async {
    return _db.delete(
      'routine_exercises',
      where: 'routine_id = ?',
      whereArgs: [routineId],
    );
  }
}
