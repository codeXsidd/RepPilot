import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';
import '../models/body_measurement.dart';

class BodyMeasurementRepository {
  final Database _db;

  BodyMeasurementRepository(this._db);

  Future<BodyMeasurement> create(BodyMeasurement entry) async {
    await _db.insert(
      'body_measurements',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return entry;
  }

  Future<BodyMeasurement?> getById(String id) async {
    final maps = await _db.query(
      'body_measurements',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return BodyMeasurement.fromMap(maps.first);
  }

  Future<BodyMeasurement?> getByDate(DateTime date) async {
    final dateStr = formatDateOnly(stripTime(date));
    final maps = await _db.query(
      'body_measurements',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    if (maps.isEmpty) return null;
    return BodyMeasurement.fromMap(maps.first);
  }

  Future<BodyMeasurement?> getLatest() async {
    final maps = await _db.query(
      'body_measurements',
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BodyMeasurement.fromMap(maps.first);
  }

  Future<BodyMeasurement> upsertByDate(BodyMeasurement entry) async {
    final existing = await getByDate(entry.date);
    if (existing != null) {
      final updated = entry.copyWith(id: existing.id);
      await update(updated);
      return updated;
    }
    return create(entry);
  }

  Future<List<BodyMeasurement>> getAll() async {
    final maps = await _db.query('body_measurements', orderBy: 'date DESC');
    return maps.map(BodyMeasurement.fromMap).toList();
  }

  Future<List<BodyMeasurement>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final startStr = formatDateOnly(stripTime(start));
    final endStr = formatDateOnly(stripTime(end));
    final maps = await _db.query(
      'body_measurements',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date ASC',
    );
    return maps.map(BodyMeasurement.fromMap).toList();
  }

  Future<int> update(BodyMeasurement entry) async {
    return _db.update(
      'body_measurements',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> delete(String id) async {
    return _db.delete('body_measurements', where: 'id = ?', whereArgs: [id]);
  }
}
