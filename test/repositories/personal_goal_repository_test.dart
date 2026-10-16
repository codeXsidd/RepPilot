import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:rep_pilot/models/personal_goal.dart';
import 'package:rep_pilot/repositories/personal_goal_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late PersonalGoalRepository repo;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = await openTestDatabase();
    repo = PersonalGoalRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  PersonalGoal makeGoal({
    String id = 'g-1',
    String goalType = 'target_weight',
    double targetValue = 75.0,
  }) => PersonalGoal(
    id: id,
    goalType: goalType,
    targetValue: targetValue,
    unit: 'kg',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );

  test('create and getById', () async {
    await repo.create(makeGoal());
    final fetched = await repo.getById('g-1');
    expect(fetched, isNotNull);
    expect(fetched!.targetValue, 75.0);
  });

  test('getAll with activeOnly filter', () async {
    await repo.create(makeGoal(id: 'a'));
    await repo.create(makeGoal(id: 'b'));
    await repo.deactivate('b');

    final active = await repo.getAll();
    expect(active.length, 1);

    final all = await repo.getAll(activeOnly: false);
    expect(all.length, 2);
  });

  test('getActiveByType finds correct goal', () async {
    await repo.create(makeGoal(goalType: 'target_weight'));
    await repo.create(
      makeGoal(id: 'g-2', goalType: 'daily_calories', targetValue: 2000),
    );

    final weight = await repo.getActiveByType('target_weight');
    expect(weight, isNotNull);
    expect(weight!.targetValue, 75.0);

    final missing = await repo.getActiveByType('nonexistent');
    expect(missing, isNull);
  });

  test('deactivate sets flag', () async {
    await repo.create(makeGoal());
    await repo.deactivate('g-1');
    final fetched = await repo.getById('g-1');
    expect(fetched!.isActive, false);
  });

  test('update modifies goal', () async {
    await repo.create(makeGoal());
    await repo.update(makeGoal().copyWith(targetValue: 80.0));
    final fetched = await repo.getById('g-1');
    expect(fetched!.targetValue, 80.0);
  });

  test('delete removes goal', () async {
    await repo.create(makeGoal());
    await repo.delete('g-1');
    expect(await repo.getById('g-1'), isNull);
  });

  test('empty state', () async {
    expect(await repo.getAll(), isEmpty);
    expect(await repo.getActiveByType('target_weight'), isNull);
  });
}
