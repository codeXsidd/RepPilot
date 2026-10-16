import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';
import '../models/water_entry.dart';

class WaterEntryRepository {
  final Database _db;

  WaterEntryRepository(this._db);

  Future<WaterEntry> create(WaterEntry entry) async {
    await _db.insert(
      'water_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return entry;
  }

  Future<WaterEntry?> getById(String id) async {
    final maps = await _db.query(
      'water_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return WaterEntry.fromMap(maps.first);
  }

  Future<List<WaterEntry>> getByDate(DateTime date) async {
    final dateStr = formatDateOnly(stripTime(date));
    final maps = await _db.query(
      'water_entries',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at ASC',
    );
    return maps.map(WaterEntry.fromMap).toList();
  }

  Future<int> getDailyTotalMl(DateTime date) async {
    final dateStr = formatDateOnly(stripTime(date));
    final result = await _db.rawQuery(
      'SELECT COALESCE(SUM(amount_ml), 0) as total '
      'FROM water_entries WHERE date = ?',
      [dateStr],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<WaterEntry>> getByDateRange(DateTime start, DateTime end) async {
    final startStr = formatDateOnly(stripTime(start));
    final endStr = formatDateOnly(stripTime(end));
    final maps = await _db.query(
      'water_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date ASC, created_at ASC',
    );
    return maps.map(WaterEntry.fromMap).toList();
  }

  Future<int> delete(String id) async {
    return _db.delete('water_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteByDate(DateTime date) async {
    final dateStr = formatDateOnly(stripTime(date));
    return _db.delete('water_entries', where: 'date = ?', whereArgs: [dateStr]);
  }
}
