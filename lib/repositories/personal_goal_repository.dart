import 'package:sqflite/sqflite.dart';

import '../models/personal_goal.dart';

class PersonalGoalRepository {
  final Database _db;

  PersonalGoalRepository(this._db);

  Future<PersonalGoal> create(PersonalGoal goal) async {
    await _db.insert(
      'personal_goals',
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return goal;
  }

  Future<PersonalGoal?> getById(String id) async {
    final maps = await _db.query(
      'personal_goals',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return PersonalGoal.fromMap(maps.first);
  }

  Future<List<PersonalGoal>> getAll({bool activeOnly = true}) async {
    final where = activeOnly ? 'is_active = 1' : null;
    final maps = await _db.query(
      'personal_goals',
      where: where,
      orderBy: 'goal_type ASC',
    );
    return maps.map(PersonalGoal.fromMap).toList();
  }

  Future<PersonalGoal?> getActiveByType(String goalType) async {
    final maps = await _db.query(
      'personal_goals',
      where: 'goal_type = ? AND is_active = 1',
      whereArgs: [goalType],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PersonalGoal.fromMap(maps.first);
  }

  Future<int> update(PersonalGoal goal) async {
    return _db.update(
      'personal_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deactivate(String id) async {
    return _db.update(
      'personal_goals',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(String id) async {
    return _db.delete('personal_goals', where: 'id = ?', whereArgs: [id]);
  }
}
