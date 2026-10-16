import 'package:sqflite/sqflite.dart';

import '../models/food.dart';

class FoodRepository {
  final Database _db;

  FoodRepository(this._db);

  Future<Food> create(Food food) async {
    await _db.insert(
      'foods',
      food.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return food;
  }

  Future<Food?> getById(String id) async {
    final maps = await _db.query('foods', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Food.fromMap(maps.first);
  }

  Future<List<Food>> getAll() async {
    final maps = await _db.query('foods', orderBy: 'name ASC');
    return maps.map(Food.fromMap).toList();
  }

  Future<List<Food>> search(String query) async {
    final pattern = '%$query%';
    final maps = await _db.query(
      'foods',
      where: 'name LIKE ? OR category LIKE ?',
      whereArgs: [pattern, pattern],
      orderBy: 'is_favorite DESC, name ASC',
    );
    return maps.map(Food.fromMap).toList();
  }

  Future<List<Food>> getByCategory(String category) async {
    final maps = await _db.query(
      'foods',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'is_favorite DESC, name ASC',
    );
    return maps.map(Food.fromMap).toList();
  }

  Future<List<Food>> getFavorites() async {
    final maps = await _db.query(
      'foods',
      where: 'is_favorite = 1',
      orderBy: 'name ASC',
    );
    return maps.map(Food.fromMap).toList();
  }

  Future<int> toggleFavorite(String id) async {
    final food = await getById(id);
    if (food == null) return 0;
    final now = DateTime.now();
    return _db.update(
      'foods',
      {
        'is_favorite': food.isFavorite ? 0 : 1,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> update(Food food) async {
    return _db.update(
      'foods',
      food.toMap(),
      where: 'id = ?',
      whereArgs: [food.id],
    );
  }

  Future<int> delete(String id) async {
    return _db.delete('foods', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> hasDefaultFoods() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM foods WHERE is_custom = 0',
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  Future<void> seedDefaults(List<Food> defaults) async {
    if (await hasDefaultFoods()) return;
    await _db.transaction((txn) async {
      for (final food in defaults) {
        await txn.insert(
          'foods',
          food.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }
}
