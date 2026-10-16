import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:rep_pilot/models/food_entry.dart';
import 'package:rep_pilot/repositories/food_entry_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late FoodEntryRepository repo;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = await openTestDatabase();
    repo = FoodEntryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  FoodEntry makeEntry({
    String id = 'fe-1',
    DateTime? date,
    String mealType = 'lunch',
    double calories = 500,
  }) => FoodEntry(
    id: id,
    date: date ?? DateTime(2025, 6, 15),
    mealType: mealType,
    description: 'Test meal',
    calories: calories,
    proteinGrams: 30.0,
    carbsGrams: 50.0,
    fatGrams: 15.0,
    createdAt: now,
    updatedAt: now,
  );

  test('create and getById', () async {
    await repo.create(makeEntry());
    final fetched = await repo.getById('fe-1');
    expect(fetched, isNotNull);
    expect(fetched!.calories, 500);
  });

  test('getByDate returns all entries for date', () async {
    await repo.create(makeEntry(id: '1', mealType: 'breakfast'));
    await repo.create(makeEntry(id: '2', mealType: 'lunch'));
    await repo.create(
      makeEntry(id: '3', date: DateTime(2025, 6, 16), mealType: 'dinner'),
    );

    final entries = await repo.getByDate(DateTime(2025, 6, 15));
    expect(entries.length, 2);
  });

  test('getByDateAndMealType filters both', () async {
    await repo.create(makeEntry(id: '1', mealType: 'breakfast'));
    await repo.create(makeEntry(id: '2', mealType: 'lunch'));

    final lunches = await repo.getByDateAndMealType(
      DateTime(2025, 6, 15),
      'lunch',
    );
    expect(lunches.length, 1);
    expect(lunches.first.mealType, 'lunch');
  });

  test('getDailyTotals sums macros', () async {
    await repo.create(makeEntry(id: '1', calories: 400));
    await repo.create(makeEntry(id: '2', calories: 600));

    final totals = await repo.getDailyTotals(DateTime(2025, 6, 15));
    expect(totals['calories'], 1000.0);
    expect(totals['protein'], 60.0);
  });

  test('getDailyTotals returns zeros for empty day', () async {
    final totals = await repo.getDailyTotals(DateTime(2025, 1, 1));
    expect(totals['calories'], 0.0);
    expect(totals['protein'], 0.0);
  });

  test('getByDateRange returns entries in range', () async {
    await repo.create(makeEntry(id: '1', date: DateTime(2025, 6, 1)));
    await repo.create(makeEntry(id: '2', date: DateTime(2025, 6, 15)));
    await repo.create(makeEntry(id: '3', date: DateTime(2025, 6, 30)));

    final range = await repo.getByDateRange(
      DateTime(2025, 6, 10),
      DateTime(2025, 6, 20),
    );
    expect(range.length, 1);
    expect(range.first.id, '2');
  });

  test('update modifies entry', () async {
    await repo.create(makeEntry());
    await repo.update(makeEntry().copyWith(calories: 750.0));
    final fetched = await repo.getById('fe-1');
    expect(fetched!.calories, 750.0);
  });

  test('delete removes entry', () async {
    await repo.create(makeEntry());
    await repo.delete('fe-1');
    expect(await repo.getById('fe-1'), isNull);
  });
}
