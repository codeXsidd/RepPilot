import 'package:sqflite/sqflite.dart';

import '../models/meal_template.dart';

class MealTemplateRepository {
  final Database _db;

  MealTemplateRepository(this._db);

  Future<MealTemplate> create(MealTemplate template) async {
    await _db.insert(
      'meal_templates',
      template.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return template;
  }

  Future<MealTemplate?> getById(String id) async {
    final maps = await _db.query(
      'meal_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return MealTemplate.fromMap(maps.first);
  }

  Future<List<MealTemplate>> getAll() async {
    final maps = await _db.query('meal_templates', orderBy: 'name ASC');
    return maps.map(MealTemplate.fromMap).toList();
  }

  Future<List<MealTemplate>> getByMealType(String mealType) async {
    final maps = await _db.query(
      'meal_templates',
      where: 'meal_type = ?',
      whereArgs: [mealType],
      orderBy: 'name ASC',
    );
    return maps.map(MealTemplate.fromMap).toList();
  }

  Future<int> update(MealTemplate template) async {
    return _db.update(
      'meal_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<int> delete(String id) async {
    return _db.delete('meal_templates', where: 'id = ?', whereArgs: [id]);
  }
}
