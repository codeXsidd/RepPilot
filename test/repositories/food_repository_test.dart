import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/core/data/default_foods.dart';
import 'package:rep_pilot/models/food.dart';
import 'package:rep_pilot/repositories/food_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late FoodRepository repo;

  final now = DateTime(2025, 7, 1, 10, 0, 0);

  Food makeFood({
    String? id,
    String name = 'Chicken Breast',
    String category = 'protein',
    double servingSize = 100,
    String servingUnit = 'g',
    double calories = 165,
    double protein = 31,
    double carbs = 0,
    double fat = 4,
    bool isCustom = true,
    bool isEstimate = false,
    bool isFavorite = false,
  }) {
    return Food(
      id: id ?? generateId(),
      name: name,
      category: category,
      servingSize: servingSize,
      servingUnit: servingUnit,
      caloriesPerServing: calories,
      proteinPerServing: protein,
      carbsPerServing: carbs,
      fatPerServing: fat,
      isCustom: isCustom,
      isEstimate: isEstimate,
      isFavorite: isFavorite,
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() async {
    db = await openTestDatabase();
    repo = FoodRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CRUD', () {
    test('create and getById', () async {
      final food = makeFood(id: 'f1');
      await repo.create(food);

      final fetched = await repo.getById('f1');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Chicken Breast');
      expect(fetched.caloriesPerServing, 165);
      expect(fetched.proteinPerServing, 31);
    });

    test('getById returns null for non-existent id', () async {
      expect(await repo.getById('non-existent'), isNull);
    });

    test('getAll returns foods sorted by name', () async {
      await repo.create(makeFood(name: 'Banana', category: 'snacks'));
      await repo.create(makeFood(name: 'Apple', category: 'snacks'));
      await repo.create(makeFood(name: 'Curd', category: 'protein'));

      final all = await repo.getAll();
      expect(all.length, 3);
      expect(all[0].name, 'Apple');
      expect(all[1].name, 'Banana');
      expect(all[2].name, 'Curd');
    });

    test('update modifies food', () async {
      final food = makeFood(id: 'f1');
      await repo.create(food);

      final updated = food.copyWith(caloriesPerServing: 170, updatedAt: now);
      await repo.update(updated);

      final fetched = await repo.getById('f1');
      expect(fetched!.caloriesPerServing, 170);
    });

    test('delete removes food', () async {
      final food = makeFood(id: 'f1');
      await repo.create(food);
      await repo.delete('f1');

      expect(await repo.getById('f1'), isNull);
    });
  });

  group('search', () {
    test('search by name (case insensitive)', () async {
      await repo.create(makeFood(name: 'Chicken Breast'));
      await repo.create(makeFood(name: 'Paneer'));
      await repo.create(makeFood(name: 'Chicken Thigh'));

      final results = await repo.search('chicken');
      expect(results.length, 2);
    });

    test('search by category', () async {
      await repo.create(makeFood(name: 'Idli', category: 'breakfast'));
      await repo.create(makeFood(name: 'Rice', category: 'staples'));

      final results = await repo.search('breakfast');
      expect(results.length, 1);
      expect(results.first.name, 'Idli');
    });

    test('search returns empty for no match', () async {
      await repo.create(makeFood(name: 'Rice'));
      final results = await repo.search('xyz');
      expect(results, isEmpty);
    });

    test('search orders favorites first', () async {
      await repo.create(makeFood(name: 'Apple', isFavorite: false));
      await repo.create(makeFood(name: 'Avocado', isFavorite: true));

      final results = await repo.search('a');
      expect(results.first.name, 'Avocado');
    });
  });

  group('categories', () {
    test('getByCategory returns only matching category', () async {
      await repo.create(makeFood(name: 'Idli', category: 'breakfast'));
      await repo.create(makeFood(name: 'Rice', category: 'staples'));
      await repo.create(makeFood(name: 'Dosa', category: 'breakfast'));

      final breakfast = await repo.getByCategory('breakfast');
      expect(breakfast.length, 2);
      expect(breakfast.every((f) => f.category == 'breakfast'), true);
    });

    test('getByCategory returns empty for unknown category', () async {
      await repo.create(makeFood(name: 'Rice', category: 'staples'));
      final results = await repo.getByCategory('desserts');
      expect(results, isEmpty);
    });
  });

  group('favorites', () {
    test('getFavorites returns only favorites', () async {
      await repo.create(makeFood(id: 'f1', name: 'Idli', isFavorite: true));
      await repo.create(makeFood(id: 'f2', name: 'Rice', isFavorite: false));
      await repo.create(makeFood(id: 'f3', name: 'Dal', isFavorite: true));

      final favorites = await repo.getFavorites();
      expect(favorites.length, 2);
    });

    test('toggleFavorite switches state', () async {
      final food = makeFood(id: 'f1', isFavorite: false);
      await repo.create(food);

      await repo.toggleFavorite('f1');
      var fetched = await repo.getById('f1');
      expect(fetched!.isFavorite, true);

      await repo.toggleFavorite('f1');
      fetched = await repo.getById('f1');
      expect(fetched!.isFavorite, false);
    });

    test('toggleFavorite returns 0 for non-existent id', () async {
      final result = await repo.toggleFavorite('non-existent');
      expect(result, 0);
    });
  });

  group('seeding', () {
    test('seedDefaults populates default foods', () async {
      final defaults = buildDefaultFoods();
      await repo.seedDefaults(defaults);

      final all = await repo.getAll();
      expect(all.length, defaults.length);

      final idli = all.where((f) => f.name == 'Idli').toList();
      expect(idli.length, 1);
      expect(idli.first.isCustom, false);
      expect(idli.first.isEstimate, true);
    });

    test('seedDefaults is idempotent', () async {
      final defaults = buildDefaultFoods();
      await repo.seedDefaults(defaults);
      await repo.seedDefaults(defaults);

      final all = await repo.getAll();
      expect(all.length, defaults.length);
    });

    test('hasDefaultFoods returns false when empty', () async {
      expect(await repo.hasDefaultFoods(), false);
    });

    test('hasDefaultFoods returns true after seeding', () async {
      await repo.seedDefaults(buildDefaultFoods());
      expect(await repo.hasDefaultFoods(), true);
    });

    test('default foods all have isEstimate true', () async {
      await repo.seedDefaults(buildDefaultFoods());
      final all = await repo.getAll();
      for (final food in all) {
        expect(
          food.isEstimate,
          true,
          reason: '${food.name} should be estimate',
        );
      }
    });
  });

  group('portion calculations', () {
    test('caloriesFor computes correctly', () {
      final food = makeFood(calories: 165);
      expect(food.caloriesFor(1), 165);
      expect(food.caloriesFor(2), 330);
      expect(food.caloriesFor(0.5), closeTo(82.5, 0.01));
    });

    test('proteinFor computes correctly', () {
      final food = makeFood(protein: 31);
      expect(food.proteinFor(1), 31);
      expect(food.proteinFor(1.5), closeTo(46.5, 0.01));
    });

    test('carbsFor and fatFor compute correctly', () {
      final food = makeFood(carbs: 20, fat: 10);
      expect(food.carbsFor(2), 40);
      expect(food.fatFor(3), 30);
    });

    test('zero servings returns zero', () {
      final food = makeFood(calories: 165, protein: 31);
      expect(food.caloriesFor(0), 0);
      expect(food.proteinFor(0), 0);
    });
  });
}
