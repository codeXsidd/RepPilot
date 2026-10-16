import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';
import '../models/food_entry.dart';

class FoodEntryRepository {
  final Database _db;

  FoodEntryRepository(this._db);

  Future<FoodEntry> create(FoodEntry entry) async {
    await _db.insert(
      'food_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return entry;
  }

  Future<FoodEntry?> getById(String id) async {
    final maps = await _db.query(
      'food_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return FoodEntry.fromMap(maps.first);
  }

  Future<List<FoodEntry>> getByDate(DateTime date) async {
    final dateStr = formatDateOnly(stripTime(date));
    final maps = await _db.query(
      'food_entries',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at ASC',
    );
    return maps.map(FoodEntry.fromMap).toList();
  }

  Future<List<FoodEntry>> getByDateRange(DateTime start, DateTime end) async {
    final startStr = formatDateOnly(stripTime(start));
    final endStr = formatDateOnly(stripTime(end));
    final maps = await _db.query(
      'food_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date ASC, created_at ASC',
    );
    return maps.map(FoodEntry.fromMap).toList();
  }

  Future<List<FoodEntry>> getByDateAndMealType(
    DateTime date,
    String mealType,
  ) async {
    final dateStr = formatDateOnly(stripTime(date));
    final maps = await _db.query(
      'food_entries',
      where: 'date = ? AND meal_type = ?',
      whereArgs: [dateStr, mealType],
      orderBy: 'created_at ASC',
    );
    return maps.map(FoodEntry.fromMap).toList();
  }

  Future<Map<String, double>> getDailyTotals(DateTime date) async {
    final dateStr = formatDateOnly(stripTime(date));
    final result = await _db.rawQuery(
      'SELECT '
      'COALESCE(SUM(calories), 0) as total_calories, '
      'COALESCE(SUM(protein_grams), 0) as total_protein, '
      'COALESCE(SUM(carbs_grams), 0) as total_carbs, '
      'COALESCE(SUM(fat_grams), 0) as total_fat '
      'FROM food_entries WHERE date = ?',
      [dateStr],
    );
    if (result.isEmpty) {
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    }
    final row = result.first;
    return {
      'calories': (row['total_calories'] as num).toDouble(),
      'protein': (row['total_protein'] as num).toDouble(),
      'carbs': (row['total_carbs'] as num).toDouble(),
      'fat': (row['total_fat'] as num).toDouble(),
    };
  }

  Future<int> update(FoodEntry entry) async {
    return _db.update(
      'food_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> delete(String id) async {
    return _db.delete('food_entries', where: 'id = ?', whereArgs: [id]);
  }
}
