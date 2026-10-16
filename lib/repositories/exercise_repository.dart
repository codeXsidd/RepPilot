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
          '(name LIKE ? OR muscle_group LIKE ? OR category LIKE ? '
          'OR equipment LIKE ? OR aliases LIKE ? OR secondary_muscles LIKE ?) '
          'AND is_archived = 0',
      whereArgs: [pattern, pattern, pattern, pattern, pattern, pattern],
      orderBy: 'name ASC',
    );
    return maps.map(Exercise.fromMap).toList();
  }

  Future<List<Exercise>> getByDifficulty(
    String difficulty, {
    bool includeArchived = false,
  }) async {
    final archiveClause = includeArchived ? '' : ' AND is_archived = 0';
    final maps = await _db.query(
      'exercises',
      where: 'difficulty = ?$archiveClause',
      whereArgs: [difficulty],
      orderBy: 'name ASC',
    );
    return maps.map(Exercise.fromMap).toList();
  }

  Future<List<Exercise>> getByEquipment(
    String equipment, {
    bool includeArchived = false,
  }) async {
    final archiveClause = includeArchived ? '' : ' AND is_archived = 0';
    final maps = await _db.query(
      'exercises',
      where: 'equipment = ?$archiveClause',
      whereArgs: [equipment],
      orderBy: 'name ASC',
    );
    return maps.map(Exercise.fromMap).toList();
  }

  Future<List<Exercise>> getHomeExercises({
    bool includeArchived = false,
  }) async {
    final archiveClause = includeArchived ? '' : ' AND is_archived = 0';
    final maps = await _db.query(
      'exercises',
      where: 'suitable_for_home = 1$archiveClause',
      orderBy: 'name ASC',
    );
    return maps.map(Exercise.fromMap).toList();
  }

  Future<List<Exercise>> getFavorites() async {
    final maps = await _db.query(
      'exercises',
      where: 'is_favorite = 1 AND is_archived = 0',
      orderBy: 'name ASC',
    );
    return maps.map(Exercise.fromMap).toList();
  }

  Future<int> toggleFavorite(String id) async {
    final exercise = await getById(id);
    if (exercise == null) return 0;
    final newVal = exercise.isFavorite ? 0 : 1;
    return _db.update(
      'exercises',
      {'is_favorite': newVal, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> setFavorite(String id, bool favorite) async {
    return _db.update(
      'exercises',
      {
        'is_favorite': favorite ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Exercise>> getRecentlyUsed({int limit = 20}) async {
    final maps = await _db.query(
      'exercises',
      where: 'last_used_at IS NOT NULL AND is_archived = 0',
      orderBy: 'last_used_at DESC',
      limit: limit,
    );
    return maps.map(Exercise.fromMap).toList();
  }

  Future<int> updateLastUsed(String id) async {
    return _db.update(
      'exercises',
      {'last_used_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Exercise>> getFiltered({
    String? category,
    String? equipment,
    String? difficulty,
    bool? suitableForHome,
    String? searchQuery,
    bool favoritesOnly = false,
    bool includeArchived = false,
  }) async {
    final conditions = <String>[];
    final args = <dynamic>[];

    if (!includeArchived) conditions.add('is_archived = 0');
    if (favoritesOnly) conditions.add('is_favorite = 1');

    if (category != null) {
      conditions.add('category = ?');
      args.add(category);
    }
    if (equipment != null) {
      conditions.add('equipment = ?');
      args.add(equipment);
    }
    if (difficulty != null) {
      conditions.add('difficulty = ?');
      args.add(difficulty);
    }
    if (suitableForHome == true) {
      conditions.add('suitable_for_home = 1');
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final pattern = '%$searchQuery%';
      conditions.add(
        '(name LIKE ? OR muscle_group LIKE ? OR aliases LIKE ? '
        'OR category LIKE ? OR equipment LIKE ?)',
      );
      args.addAll([pattern, pattern, pattern, pattern, pattern]);
    }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    final maps = await _db.query(
      'exercises',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name ASC',
    );
    return maps.map(Exercise.fromMap).toList();
  }

  Future<List<Exercise>> getSubstitutions(String exerciseId) async {
    final exercise = await getById(exerciseId);
    if (exercise == null || exercise.substitutionIds.isEmpty) return [];
    final ids = exercise.substitutionIdList;
    if (ids.isEmpty) return [];
    final placeholders = ids.map((_) => '?').join(',');
    final maps = await _db.query(
      'exercises',
      where: 'id IN ($placeholders) AND is_archived = 0',
      whereArgs: ids,
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

  Future<List<String>> getDistinctEquipment() async {
    final maps = await _db.rawQuery(
      "SELECT DISTINCT equipment FROM exercises WHERE is_archived = 0 AND equipment != '' ORDER BY equipment ASC",
    );
    return maps.map((m) => m['equipment'] as String).toList();
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

  Future<int> countDefaultExercises() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM exercises WHERE is_custom = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> seedDefaults(List<Exercise> exercises) async {
    final existingCount = await countDefaultExercises();

    if (existingCount == 0) {
      final batch = _db.batch();
      for (final e in exercises) {
        batch.insert(
          'exercises',
          e.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
      return;
    }

    final batch = _db.batch();
    for (final e in exercises) {
      final map = e.toMap();
      map.remove('is_favorite');
      map.remove('last_used_at');
      batch.rawInsert('''INSERT INTO exercises (${map.keys.join(', ')})
           VALUES (${map.keys.map((_) => '?').join(', ')})
           ON CONFLICT(id) DO UPDATE SET
             name = excluded.name,
             category = excluded.category,
             muscle_group = excluded.muscle_group,
             equipment = excluded.equipment,
             secondary_muscles = excluded.secondary_muscles,
             difficulty = excluded.difficulty,
             description = excluded.description,
             instructions = excluded.instructions,
             movement_pattern = excluded.movement_pattern,
             default_sets = excluded.default_sets,
             default_reps_min = excluded.default_reps_min,
             default_reps_max = excluded.default_reps_max,
             default_rest_seconds = excluded.default_rest_seconds,
             default_increment_kg = excluded.default_increment_kg,
             aliases = excluded.aliases,
             substitution_ids = excluded.substitution_ids,
             is_bodyweight = excluded.is_bodyweight,
             is_unilateral = excluded.is_unilateral,
             is_machine = excluded.is_machine,
             suitable_for_home = excluded.suitable_for_home,
             suitable_for_gym = excluded.suitable_for_gym,
             safety_notes = excluded.safety_notes,
             updated_at = excluded.updated_at
           WHERE is_custom = 0''', map.values.toList());
    }
    await batch.commit(noResult: true);
  }
}
