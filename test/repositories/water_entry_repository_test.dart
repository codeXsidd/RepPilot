import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:rep_pilot/models/water_entry.dart';
import 'package:rep_pilot/repositories/water_entry_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late WaterEntryRepository repo;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = await openTestDatabase();
    repo = WaterEntryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  WaterEntry makeEntry({String id = 'we-1', DateTime? date, int ml = 250}) =>
      WaterEntry(
        id: id,
        date: date ?? DateTime(2025, 6, 15),
        amountMl: ml,
        createdAt: now,
      );

  test('create and getById', () async {
    await repo.create(makeEntry());
    final fetched = await repo.getById('we-1');
    expect(fetched, isNotNull);
    expect(fetched!.amountMl, 250);
  });

  test('getByDate returns all entries for date', () async {
    await repo.create(makeEntry(id: '1', ml: 250));
    await repo.create(makeEntry(id: '2', ml: 500));
    await repo.create(makeEntry(id: '3', date: DateTime(2025, 6, 16)));

    final entries = await repo.getByDate(DateTime(2025, 6, 15));
    expect(entries.length, 2);
  });

  test('getDailyTotalMl sums all entries', () async {
    await repo.create(makeEntry(id: '1', ml: 250));
    await repo.create(makeEntry(id: '2', ml: 500));

    final total = await repo.getDailyTotalMl(DateTime(2025, 6, 15));
    expect(total, 750);
  });

  test('getDailyTotalMl returns 0 for empty day', () async {
    final total = await repo.getDailyTotalMl(DateTime(2025, 1, 1));
    expect(total, 0);
  });

  test('getByDateRange filters correctly', () async {
    await repo.create(makeEntry(id: '1', date: DateTime(2025, 6, 1)));
    await repo.create(makeEntry(id: '2', date: DateTime(2025, 6, 15)));
    await repo.create(makeEntry(id: '3', date: DateTime(2025, 6, 30)));

    final range = await repo.getByDateRange(
      DateTime(2025, 6, 10),
      DateTime(2025, 6, 20),
    );
    expect(range.length, 1);
  });

  test('delete removes entry', () async {
    await repo.create(makeEntry());
    await repo.delete('we-1');
    expect(await repo.getById('we-1'), isNull);
  });

  test('deleteByDate removes all entries for date', () async {
    await repo.create(makeEntry(id: '1'));
    await repo.create(makeEntry(id: '2'));
    await repo.deleteByDate(DateTime(2025, 6, 15));
    final entries = await repo.getByDate(DateTime(2025, 6, 15));
    expect(entries, isEmpty);
  });
}
