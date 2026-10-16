import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:rep_pilot/models/exercise.dart';
import 'package:rep_pilot/repositories/exercise_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late ExerciseRepository repo;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = await openTestDatabase();
    repo = ExerciseRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Exercise makeExercise({
    String id = 'ex-1',
    String name = 'Bench Press',
    String category = 'chest',
    String equipment = 'barbell',
    String muscleGroup = 'Pectorals',
    bool isCustom = true,
  }) => Exercise(
    id: id,
    name: name,
    category: category,
    equipment: equipment,
    muscleGroup: muscleGroup,
    isCustom: isCustom,
    createdAt: now,
    updatedAt: now,
  );

  test('create and getById', () async {
    final e = makeExercise();
    await repo.create(e);
    final fetched = await repo.getById('ex-1');
    expect(fetched, isNotNull);
    expect(fetched!.name, 'Bench Press');
    expect(fetched.category, 'chest');
    expect(fetched.equipment, 'barbell');
  });

  test('getAll returns empty on fresh DB', () async {
    final all = await repo.getAll();
    expect(all, isEmpty);
  });

  test('getAll excludes archived by default', () async {
    await repo.create(makeExercise(id: 'a', name: 'Active'));
    await repo.create(
      makeExercise(id: 'b', name: 'Archived').copyWith(isArchived: true),
    );
    await db.update(
      'exercises',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: ['b'],
    );

    final active = await repo.getAll();
    expect(active.length, 1);
    expect(active.first.name, 'Active');

    final all = await repo.getAll(includeArchived: true);
    expect(all.length, 2);
  });

  test('getByCategory filters correctly', () async {
    await repo.create(makeExercise(id: '1', name: 'Bench', category: 'chest'));
    await repo.create(makeExercise(id: '2', name: 'Squat', category: 'legs'));
    await repo.create(makeExercise(id: '3', name: 'Fly', category: 'chest'));

    final chest = await repo.getByCategory('chest');
    expect(chest.length, 2);
    expect(chest.every((e) => e.category == 'chest'), true);
  });

  test('getByMuscleGroup filters correctly', () async {
    await repo.create(
      makeExercise(id: '1', name: 'Bench', muscleGroup: 'Pectorals'),
    );
    await repo.create(
      makeExercise(id: '2', name: 'Squat', muscleGroup: 'Quadriceps'),
    );

    final pecs = await repo.getByMuscleGroup('Pectorals');
    expect(pecs.length, 1);
    expect(pecs.first.name, 'Bench');
  });

  test('search matches name, category, and equipment', () async {
    await repo.create(
      makeExercise(
        id: '1',
        name: 'Bench Press',
        category: 'chest',
        equipment: 'barbell',
      ),
    );
    await repo.create(
      makeExercise(
        id: '2',
        name: 'Squat',
        category: 'legs',
        equipment: 'barbell',
      ),
    );

    final byName = await repo.search('bench');
    expect(byName.length, 1);
    expect(byName.first.name, 'Bench Press');

    final byCat = await repo.search('legs');
    expect(byCat.length, 1);
    expect(byCat.first.name, 'Squat');

    final byEquip = await repo.search('barbell');
    expect(byEquip.length, 2);
  });

  test('search empty query returns all', () async {
    await repo.create(makeExercise(id: '1', name: 'A'));
    await repo.create(makeExercise(id: '2', name: 'B'));
    final all = await repo.search('');
    expect(all.length, 2);
  });

  test('getDistinctCategories returns unique categories', () async {
    await repo.create(makeExercise(id: '1', name: 'A', category: 'chest'));
    await repo.create(makeExercise(id: '2', name: 'B', category: 'legs'));
    await repo.create(makeExercise(id: '3', name: 'C', category: 'chest'));

    final cats = await repo.getDistinctCategories();
    expect(cats.length, 2);
    expect(cats, contains('chest'));
    expect(cats, contains('legs'));
  });

  test('update modifies fields', () async {
    await repo.create(makeExercise());
    final updated = makeExercise().copyWith(
      name: 'Incline Bench',
      equipment: 'dumbbell',
    );
    await repo.update(updated);

    final fetched = await repo.getById('ex-1');
    expect(fetched!.name, 'Incline Bench');
    expect(fetched.equipment, 'dumbbell');
  });

  test('archive sets flag', () async {
    await repo.create(makeExercise());
    await repo.archive('ex-1');

    final fetched = await repo.getById('ex-1');
    expect(fetched!.isArchived, true);
  });

  test('delete removes record', () async {
    await repo.create(makeExercise());
    await repo.delete('ex-1');
    final fetched = await repo.getById('ex-1');
    expect(fetched, isNull);
  });

  test('duplicate id throws', () async {
    await repo.create(makeExercise());
    expect(
      () => repo.create(makeExercise()),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('getById returns null for nonexistent id', () async {
    final fetched = await repo.getById('nonexistent');
    expect(fetched, isNull);
  });

  group('seedDefaults', () {
    test('seeds exercises when no defaults exist', () async {
      final defaults = [
        makeExercise(id: 'd-1', name: 'Default A', isCustom: false),
        makeExercise(id: 'd-2', name: 'Default B', isCustom: false),
      ];
      await repo.seedDefaults(defaults);

      final all = await repo.getAll();
      expect(all.length, 2);
      expect(all.every((e) => !e.isCustom), true);
    });

    test('re-seed upserts new exercises and updates existing', () async {
      final defaults = [
        makeExercise(id: 'd-1', name: 'Default A', isCustom: false),
      ];
      await repo.seedDefaults(defaults);
      await repo.seedDefaults([
        makeExercise(id: 'd-1', name: 'Default A Updated', isCustom: false),
        makeExercise(id: 'd-2', name: 'Default B', isCustom: false),
      ]);

      final all = await repo.getAll();
      expect(all.length, 2);
      expect(all.any((e) => e.name == 'Default A Updated'), true);
      expect(all.any((e) => e.name == 'Default B'), true);
    });

    test('hasDefaultExercises returns false on fresh DB', () async {
      expect(await repo.hasDefaultExercises(), false);
    });

    test('hasDefaultExercises returns true after seeding', () async {
      await repo.seedDefaults([
        makeExercise(id: 'd-1', name: 'Default', isCustom: false),
      ]);
      expect(await repo.hasDefaultExercises(), true);
    });
  });
}
