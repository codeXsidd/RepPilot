import 'package:sqflite/sqflite.dart';

import '../models/meal_template_item.dart';

class MealTemplateItemRepository {
  final Database _db;

  MealTemplateItemRepository(this._db);

  Future<MealTemplateItem> create(MealTemplateItem item) async {
    await _db.insert(
      'meal_template_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return item;
  }

  Future<List<MealTemplateItem>> getByTemplateId(String templateId) async {
    final maps = await _db.query(
      'meal_template_items',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'created_at ASC',
    );
    return maps.map(MealTemplateItem.fromMap).toList();
  }

  Future<int> delete(String id) async {
    return _db.delete('meal_template_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllForTemplate(String templateId) async {
    return _db.delete(
      'meal_template_items',
      where: 'template_id = ?',
      whereArgs: [templateId],
    );
  }
}
