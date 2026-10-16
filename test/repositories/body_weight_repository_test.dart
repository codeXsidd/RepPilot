import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:rep_pilot/models/body_weight_entry.dart';
import 'package:rep_pilot/repositories/body_weight_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late BodyWeightRepository repo;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = await openTestDatabase();
    repo = BodyWeightRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  BodyWeightEntry makeEntry({
    String id = 'bw-1',
    DateTime? date,
    double weightKg = 75.0,
  }) => BodyWeightEntry(
    id: id,
    date: date ?? DateTime(2025, 6, 15),
    weightKg: weightKg,
    createdAt: now,
    updatedAt: now,
  );

  test('create and getById', () async {
    await repo.create(makeEntry());
    final fetched = await repo.getById('bw-1');
    expect(fetched, isNotNull);
    expect(fetched!.weightKg, 75.0);
  });

  test('getByDate finds entry by date', () async {
    await repo.create(makeEntry());
    final fetched = await repo.getByDate(DateTime(2025, 6, 15, 23, 59));
    expect(fetched, isNotNull);
    expect(fetched!.id, 'bw-1');
  });

  test('getLatest returns most recent entry', () async {
    await repo.create(makeEntry(id: 'a', date: DateTime(2025, 6, 10)));
    await repo.create(makeEntry(id: 'b', date: DateTime(2025, 6, 20)));
    final latest = await repo.getLatest();
    expect(latest!.id, 'b');
  });

  test('getByDateRange returns entries in range', () async {
    await repo.create(makeEntry(id: 'a', date: DateTime(2025, 6, 1)));
    await repo.create(makeEntry(id: 'b', date: DateTime(2025, 6, 15)));
    await repo.create(makeEntry(id: 'c', date: DateTime(2025, 6, 30)));

    final range = await repo.getByDateRange(
      DateTime(2025, 6, 10),
      DateTime(2025, 6, 20),
    );
    expect(range.length, 1);
    expect(range.first.id, 'b');
  });

  test('unique date constraint prevents duplicates', () async {
    await repo.create(makeEntry());
    expect(
      () => repo.create(makeEntry(id: 'bw-2', weightKg: 76.0)),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('upsertByDate updates existing entry for same date', () async {
    await repo.create(makeEntry());
    final updated = makeEntry(id: 'bw-new', weightKg: 76.0);
    final result = await repo.upsertByDate(updated);
    expect(result.id, 'bw-1');

    final fetched = await repo.getById('bw-1');
    expect(fetched!.weightKg, 76.0);
  });

  test('upsertByDate creates new entry for new date', () async {
    final entry = makeEntry(date: DateTime(2025, 7, 1));
    final result = await repo.upsertByDate(entry);
    expect(result.id, 'bw-1');

    final all = await repo.getAll();
    expect(all.length, 1);
  });

  test('delete removes entry', () async {
    await repo.create(makeEntry());
    await repo.delete('bw-1');
    expect(await repo.getById('bw-1'), isNull);
  });

  test('empty state returns null and empty lists', () async {
    expect(await repo.getLatest(), isNull);
    expect(await repo.getAll(), isEmpty);
    expect(await repo.getByDate(DateTime(2025, 1, 1)), isNull);
  });
}
