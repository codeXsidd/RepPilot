import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';
import '../models/routine.dart';
import '../models/routine_exercise.dart';

class RoutineRepository {
  final Database _db;

  RoutineRepository(this._db);

  Future<Routine> create(Routine routine) async {
    await _db.insert(
      'routines',
      routine.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return routine;
  }

  Future<Routine?> getById(String id) async {
    final maps = await _db.query('routines', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Routine.fromMap(maps.first);
  }

  Future<List<Routine>> getAll({bool includeArchived = false}) async {
    final where = includeArchived ? null : 'is_archived = 0';
    final maps = await _db.query(
      'routines',
      where: where,
      orderBy: 'sort_order ASC, name ASC',
    );
    return maps.map(Routine.fromMap).toList();
  }

  Future<List<Routine>> getByDayOfWeek(int dayOfWeek) async {
    final maps = await _db.query(
      'routines',
      where: 'day_of_week = ? AND is_archived = 0',
      whereArgs: [dayOfWeek],
      orderBy: 'sort_order ASC',
    );
    return maps.map(Routine.fromMap).toList();
  }

  Future<Map<int, List<Routine>>> getWeeklySchedule() async {
    final maps = await _db.query(
      'routines',
      where: 'day_of_week IS NOT NULL AND is_archived = 0',
      orderBy: 'day_of_week ASC, sort_order ASC',
    );
    final schedule = <int, List<Routine>>{};
    for (final map in maps) {
      final routine = Routine.fromMap(map);
      final day = routine.dayOfWeek!;
      schedule.putIfAbsent(day, () => []).add(routine);
    }
    return schedule;
  }

  Future<int> update(Routine routine) async {
    return _db.update(
      'routines',
      routine.toMap(),
      where: 'id = ?',
      whereArgs: [routine.id],
    );
  }

  Future<int> schedule(String id, int dayOfWeek) async {
    return _db.update(
      'routines',
      {
        'day_of_week': dayOfWeek,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> unschedule(String id) async {
    return _db.update(
      'routines',
      {'day_of_week': null, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> archive(String id) async {
    return _db.update(
      'routines',
      {'is_archived': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Routine> duplicate(String sourceId, {String? newName}) async {
    final source = await getById(sourceId);
    if (source == null) throw ArgumentError('Routine $sourceId not found');

    final now = DateTime.now();
    final newId = generateId();
    final routine = Routine(
      id: newId,
      name: newName ?? '${source.name} (Copy)',
      dayOfWeek: null,
      sortOrder: source.sortOrder,
      notes: source.notes,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );

    final sourceExercises = await _db.query(
      'routine_exercises',
      where: 'routine_id = ?',
      whereArgs: [sourceId],
      orderBy: 'sort_order ASC',
    );

    await _db.transaction((txn) async {
      await txn.insert('routines', routine.toMap());
      for (final re in sourceExercises) {
        final copy = RoutineExercise.fromMap(re).copyWith(
          id: generateId(),
          routineId: newId,
          createdAt: now,
          updatedAt: now,
        );
        await txn.insert('routine_exercises', copy.toMap());
      }
    });

    return routine;
  }

  Future<int> delete(String id) async {
    return _db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }
}
