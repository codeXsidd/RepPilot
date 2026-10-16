import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';
import '../models/body_weight_entry.dart';

class BodyWeightRepository {
  final Database _db;

  BodyWeightRepository(this._db);

  Future<BodyWeightEntry> create(BodyWeightEntry entry) async {
    await _db.insert(
      'body_weight_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return entry;
  }

  Future<BodyWeightEntry> upsertByDate(BodyWeightEntry entry) async {
    final existing = await getByDate(entry.date);
    if (existing != null) {
      final updated = entry.copyWith(id: existing.id);
      await update(updated);
      return updated;
    }
    return create(entry);
  }

  Future<BodyWeightEntry?> getById(String id) async {
    final maps = await _db.query(
      'body_weight_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return BodyWeightEntry.fromMap(maps.first);
  }

  Future<BodyWeightEntry?> getByDate(DateTime date) async {
    final dateStr = formatDateOnly(stripTime(date));
    final maps = await _db.query(
      'body_weight_entries',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    if (maps.isEmpty) return null;
    return BodyWeightEntry.fromMap(maps.first);
  }

  Future<BodyWeightEntry?> getLatest() async {
    final maps = await _db.query(
      'body_weight_entries',
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BodyWeightEntry.fromMap(maps.first);
  }

  Future<List<BodyWeightEntry>> getAll() async {
    final maps = await _db.query('body_weight_entries', orderBy: 'date DESC');
    return maps.map(BodyWeightEntry.fromMap).toList();
  }

  Future<List<BodyWeightEntry>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final startStr = formatDateOnly(stripTime(start));
    final endStr = formatDateOnly(stripTime(end));
    final maps = await _db.query(
      'body_weight_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date ASC',
    );
    return maps.map(BodyWeightEntry.fromMap).toList();
  }

  Future<int> update(BodyWeightEntry entry) async {
    return _db.update(
      'body_weight_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> delete(String id) async {
    return _db.delete('body_weight_entries', where: 'id = ?', whereArgs: [id]);
  }
}
