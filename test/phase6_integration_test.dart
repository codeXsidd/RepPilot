import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:rep_pilot/core/data/default_foods.dart';
import 'package:rep_pilot/models/food.dart';
import 'package:rep_pilot/models/food_entry.dart';
import 'package:rep_pilot/models/meal_template.dart';
import 'package:rep_pilot/models/meal_template_item.dart';
import 'package:rep_pilot/models/personal_goal.dart';
import 'package:rep_pilot/models/water_entry.dart';
import 'package:rep_pilot/repositories/food_entry_repository.dart';
import 'package:rep_pilot/repositories/food_repository.dart';
import 'package:rep_pilot/repositories/meal_template_item_repository.dart';
import 'package:rep_pilot/repositories/meal_template_repository.dart';
import 'package:rep_pilot/repositories/personal_goal_repository.dart';
import 'package:rep_pilot/repositories/water_entry_repository.dart';
import 'package:rep_pilot/services/nutrition_service.dart';

import 'helpers/test_database.dart';

void main() {
  late Database db;
  late FoodRepository foodRepo;
  late FoodEntryRepository entryRepo;
  late WaterEntryRepository waterRepo;
  late MealTemplateRepository templateRepo;
  late MealTemplateItemRepository itemRepo;
  late PersonalGoalRepository goalRepo;
  const service = NutritionService();

  final now = DateTime(2025, 7, 1, 10, 0, 0);

  setUp(() async {
    db = await openTestDatabase();
    foodRepo = FoodRepository(db);
    entryRepo = FoodEntryRepository(db);
    waterRepo = WaterEntryRepository(db);
    templateRepo = MealTemplateRepository(db);
    itemRepo = MealTemplateItemRepository(db);
    goalRepo = PersonalGoalRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('food logging lifecycle', () {
    test('log food from catalog and verify daily totals', () async {
      final food = Food(
        id: 'f-rice',
        name: 'Rice',
        category: 'staples',
        servingSize: 1,
        servingUnit: 'cup',
        caloriesPerServing: 200,
        proteinPerServing: 4,
        carbsPerServing: 45,
        fatPerServing: 0.5,
        isEstimate: true,
        createdAt: now,
        updatedAt: now,
      );
      await foodRepo.create(food);

      final entry = service.createEntryFromFood(
        food: food,
        servings: 2,
        date: DateTime(2025, 7, 1),
        mealType: 'lunch',
      )!;
      await entryRepo.create(entry);

      final totals = await entryRepo.getDailyTotals(DateTime(2025, 7, 1));
      expect(totals['calories'], closeTo(400, 0.01));
      expect(totals['protein'], closeTo(8, 0.01));
      expect(totals['carbs'], closeTo(90, 0.01));
    });

    test('multiple meals accumulate correctly', () async {
      final rice = Food(
        id: 'f-rice',
        name: 'Rice',
        category: 'staples',
        caloriesPerServing: 200,
        proteinPerServing: 4,
        carbsPerServing: 45,
        fatPerServing: 0.5,
        createdAt: now,
        updatedAt: now,
      );
      final dal = Food(
        id: 'f-dal',
        name: 'Dal',
        category: 'staples',
        caloriesPerServing: 230,
        proteinPerServing: 18,
        carbsPerServing: 30,
        fatPerServing: 4,
        createdAt: now,
        updatedAt: now,
      );
      await foodRepo.create(rice);
      await foodRepo.create(dal);

      final date = DateTime(2025, 7, 1);
      await entryRepo.create(
        service.createEntryFromFood(
          food: rice,
          servings: 1.5,
          date: date,
          mealType: 'lunch',
        )!,
      );
      await entryRepo.create(
        service.createEntryFromFood(
          food: dal,
          servings: 1,
          date: date,
          mealType: 'lunch',
        )!,
      );

      final totals = await entryRepo.getDailyTotals(date);
      expect(totals['calories'], closeTo(530, 0.01));
      expect(totals['protein'], closeTo(24, 0.01));
    });

    test('edit food entry updates totals', () async {
      final entry = FoodEntry(
        id: 'fe-1',
        date: DateTime(2025, 7, 1),
        mealType: 'breakfast',
        description: 'Idli',
        calories: 140,
        proteinGrams: 4,
        createdAt: now,
        updatedAt: now,
      );
      await entryRepo.create(entry);

      final updated = entry.copyWith(calories: 280, proteinGrams: 8);
      await entryRepo.update(updated);

      final totals = await entryRepo.getDailyTotals(DateTime(2025, 7, 1));
      expect(totals['calories'], 280);
      expect(totals['protein'], 8);
    });

    test('delete food entry removes from totals', () async {
      final e1 = FoodEntry(
        id: 'fe-1',
        date: DateTime(2025, 7, 1),
        mealType: 'lunch',
        description: 'Rice',
        calories: 200,
        proteinGrams: 4,
        createdAt: now,
        updatedAt: now,
      );
      final e2 = FoodEntry(
        id: 'fe-2',
        date: DateTime(2025, 7, 1),
        mealType: 'lunch',
        description: 'Dal',
        calories: 230,
        proteinGrams: 18,
        createdAt: now,
        updatedAt: now,
      );
      await entryRepo.create(e1);
      await entryRepo.create(e2);

      await entryRepo.delete('fe-1');

      final totals = await entryRepo.getDailyTotals(DateTime(2025, 7, 1));
      expect(totals['calories'], 230);
    });
  });

  group('meal template workflow', () {
    test('create template and apply to date', () async {
      final idli = Food(
        id: 'f-idli',
        name: 'Idli',
        category: 'breakfast',
        servingSize: 2,
        servingUnit: 'pieces',
        caloriesPerServing: 140,
        proteinPerServing: 4,
        carbsPerServing: 28,
        fatPerServing: 1,
        isEstimate: true,
        createdAt: now,
        updatedAt: now,
      );
      final chutney = Food(
        id: 'f-chutney',
        name: 'Coconut Chutney',
        category: 'other',
        servingSize: 2,
        servingUnit: 'tbsp',
        caloriesPerServing: 50,
        proteinPerServing: 1,
        carbsPerServing: 4,
        fatPerServing: 3.5,
        isEstimate: true,
        createdAt: now,
        updatedAt: now,
      );
      await foodRepo.create(idli);
      await foodRepo.create(chutney);

      final template = MealTemplate(
        id: 't-morning',
        name: 'South Indian Breakfast',
        mealType: 'breakfast',
        createdAt: now,
        updatedAt: now,
      );
      await templateRepo.create(template);

      final item1 = MealTemplateItem(
        id: 'ti-1',
        templateId: 't-morning',
        foodId: 'f-idli',
        servings: 2,
        createdAt: now,
      );
      final item2 = MealTemplateItem(
        id: 'ti-2',
        templateId: 't-morning',
        foodId: 'f-chutney',
        servings: 1,
        createdAt: now,
      );
      await itemRepo.create(item1);
      await itemRepo.create(item2);

      final items = await itemRepo.getByTemplateId('t-morning');
      final entries = await service.applyTemplate(
        items: items,
        foodRepo: foodRepo,
        entryRepo: entryRepo,
        date: DateTime(2025, 7, 1),
        mealType: 'breakfast',
      );

      expect(entries.length, 2);

      final totals = await entryRepo.getDailyTotals(DateTime(2025, 7, 1));
      expect(totals['calories'], closeTo(330, 0.01));
    });

    test('applying same template twice creates separate entries', () async {
      final food = Food(
        id: 'f1',
        name: 'Egg',
        category: 'protein',
        caloriesPerServing: 78,
        proteinPerServing: 6,
        carbsPerServing: 1,
        fatPerServing: 5,
        createdAt: now,
        updatedAt: now,
      );
      await foodRepo.create(food);

      final template = MealTemplate(
        id: 't1',
        name: 'Egg Meal',
        mealType: 'breakfast',
        createdAt: now,
        updatedAt: now,
      );
      await templateRepo.create(template);
      await itemRepo.create(
        MealTemplateItem(
          id: 'ti1',
          templateId: 't1',
          foodId: 'f1',
          servings: 2,
          createdAt: now,
        ),
      );

      final items = await itemRepo.getByTemplateId('t1');
      await service.applyTemplate(
        items: items,
        foodRepo: foodRepo,
        entryRepo: entryRepo,
        date: DateTime(2025, 7, 1),
        mealType: 'breakfast',
      );
      await service.applyTemplate(
        items: items,
        foodRepo: foodRepo,
        entryRepo: entryRepo,
        date: DateTime(2025, 7, 1),
        mealType: 'breakfast',
      );

      final dayEntries = await entryRepo.getByDate(DateTime(2025, 7, 1));
      expect(dayEntries.length, 2);

      final totals = await entryRepo.getDailyTotals(DateTime(2025, 7, 1));
      expect(totals['calories'], closeTo(312, 0.01));
    });

    test('template with deleted food skips missing items', () async {
      final food = Food(
        id: 'f1',
        name: 'Temp Food',
        category: 'other',
        caloriesPerServing: 100,
        proteinPerServing: 5,
        createdAt: now,
        updatedAt: now,
      );
      await foodRepo.create(food);

      final template = MealTemplate(
        id: 't1',
        name: 'Test',
        mealType: 'snack',
        createdAt: now,
        updatedAt: now,
      );
      await templateRepo.create(template);
      await itemRepo.create(
        MealTemplateItem(
          id: 'ti1',
          templateId: 't1',
          foodId: 'f1',
          servings: 1,
          createdAt: now,
        ),
      );

      await foodRepo.delete('f1');

      final items = await itemRepo.getByTemplateId('t1');
      final entries = await service.applyTemplate(
        items: items,
        foodRepo: foodRepo,
        entryRepo: entryRepo,
        date: DateTime(2025, 7, 1),
        mealType: 'snack',
      );

      expect(entries, isEmpty);
    });
  });

  group('water tracking', () {
    test('accumulate water entries for a day', () async {
      await waterRepo.create(
        WaterEntry(
          id: 'w1',
          date: DateTime(2025, 7, 1),
          amountMl: 250,
          createdAt: now,
        ),
      );
      await waterRepo.create(
        WaterEntry(
          id: 'w2',
          date: DateTime(2025, 7, 1),
          amountMl: 500,
          createdAt: now,
        ),
      );
      await waterRepo.create(
        WaterEntry(
          id: 'w3',
          date: DateTime(2025, 7, 1),
          amountMl: 250,
          createdAt: now,
        ),
      );

      final total = await waterRepo.getDailyTotalMl(DateTime(2025, 7, 1));
      expect(total, 1000);
    });

    test('water entries for different dates do not mix', () async {
      await waterRepo.create(
        WaterEntry(
          id: 'w1',
          date: DateTime(2025, 7, 1),
          amountMl: 500,
          createdAt: now,
        ),
      );
      await waterRepo.create(
        WaterEntry(
          id: 'w2',
          date: DateTime(2025, 7, 2),
          amountMl: 750,
          createdAt: now,
        ),
      );

      expect(await waterRepo.getDailyTotalMl(DateTime(2025, 7, 1)), 500);
      expect(await waterRepo.getDailyTotalMl(DateTime(2025, 7, 2)), 750);
    });

    test('delete water entry reduces total', () async {
      await waterRepo.create(
        WaterEntry(
          id: 'w1',
          date: DateTime(2025, 7, 1),
          amountMl: 250,
          createdAt: now,
        ),
      );
      await waterRepo.create(
        WaterEntry(
          id: 'w2',
          date: DateTime(2025, 7, 1),
          amountMl: 500,
          createdAt: now,
        ),
      );

      await waterRepo.delete('w1');
      expect(await waterRepo.getDailyTotalMl(DateTime(2025, 7, 1)), 500);
    });

    test('deleteByDate clears all for that day', () async {
      await waterRepo.create(
        WaterEntry(
          id: 'w1',
          date: DateTime(2025, 7, 1),
          amountMl: 250,
          createdAt: now,
        ),
      );
      await waterRepo.create(
        WaterEntry(
          id: 'w2',
          date: DateTime(2025, 7, 1),
          amountMl: 500,
          createdAt: now,
        ),
      );

      await waterRepo.deleteByDate(DateTime(2025, 7, 1));
      expect(await waterRepo.getDailyTotalMl(DateTime(2025, 7, 1)), 0);
    });
  });

  group('nutrition goals', () {
    test('set and retrieve calorie goal', () async {
      await goalRepo.create(
        PersonalGoal(
          id: 'g1',
          goalType: 'daily_calories',
          targetValue: 2000,
          unit: 'kcal',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final goal = await goalRepo.getActiveByType('daily_calories');
      expect(goal, isNotNull);
      expect(goal!.targetValue, 2000);
    });

    test('update goal changes target', () async {
      await goalRepo.create(
        PersonalGoal(
          id: 'g1',
          goalType: 'daily_protein',
          targetValue: 100,
          unit: 'g',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final goal = (await goalRepo.getActiveByType('daily_protein'))!;
      await goalRepo.update(goal.copyWith(targetValue: 150));

      final updated = await goalRepo.getActiveByType('daily_protein');
      expect(updated!.targetValue, 150);
    });

    test('deactivated goal is not returned by getActiveByType', () async {
      await goalRepo.create(
        PersonalGoal(
          id: 'g1',
          goalType: 'daily_water_ml',
          targetValue: 2500,
          unit: 'ml',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await goalRepo.deactivate('g1');
      expect(await goalRepo.getActiveByType('daily_water_ml'), isNull);
    });

    test('goal progress computation', () async {
      await goalRepo.create(
        PersonalGoal(
          id: 'g1',
          goalType: 'daily_calories',
          targetValue: 2000,
          unit: 'kcal',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await entryRepo.create(
        FoodEntry(
          id: 'fe-1',
          date: DateTime(2025, 7, 1),
          mealType: 'lunch',
          description: 'Rice',
          calories: 1500,
          proteinGrams: 30,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final goal = (await goalRepo.getActiveByType('daily_calories'))!;
      final totals = await entryRepo.getDailyTotals(DateTime(2025, 7, 1));
      final progress = service.goalProgress(
        totals['calories']!,
        goal.targetValue,
      );
      expect(progress, closeTo(0.75, 0.01));
    });
  });

  group('date boundary handling', () {
    test('entries on adjacent days do not mix', () async {
      await entryRepo.create(
        FoodEntry(
          id: 'fe-1',
          date: DateTime(2025, 7, 1),
          mealType: 'lunch',
          description: 'Day 1 food',
          calories: 500,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await entryRepo.create(
        FoodEntry(
          id: 'fe-2',
          date: DateTime(2025, 7, 2),
          mealType: 'lunch',
          description: 'Day 2 food',
          calories: 800,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final day1 = await entryRepo.getDailyTotals(DateTime(2025, 7, 1));
      final day2 = await entryRepo.getDailyTotals(DateTime(2025, 7, 2));
      expect(day1['calories'], 500);
      expect(day2['calories'], 800);
    });

    test('getByDateRange respects boundaries', () async {
      for (var d = 1; d <= 7; d++) {
        await entryRepo.create(
          FoodEntry(
            id: 'fe-$d',
            date: DateTime(2025, 7, d),
            mealType: 'lunch',
            description: 'Day $d',
            calories: 100.0 * d,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final range = await entryRepo.getByDateRange(
        DateTime(2025, 7, 3),
        DateTime(2025, 7, 5),
      );
      expect(range.length, 3);
      expect(range.first.date, DateTime(2025, 7, 3));
      expect(range.last.date, DateTime(2025, 7, 5));
    });

    test('entries for future dates are separate', () async {
      await entryRepo.create(
        FoodEntry(
          id: 'fe-today',
          date: DateTime(2025, 7, 1),
          mealType: 'lunch',
          description: 'Today',
          calories: 500,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await entryRepo.create(
        FoodEntry(
          id: 'fe-future',
          date: DateTime(2025, 12, 31),
          mealType: 'lunch',
          description: 'Future',
          calories: 999,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final today = await entryRepo.getDailyTotals(DateTime(2025, 7, 1));
      expect(today['calories'], 500);
    });
  });

  group('default food seeding', () {
    test('seeds all default Indian foods', () async {
      await service.seedDefaultFoods(foodRepo, buildDefaultFoods());
      final all = await foodRepo.getAll();
      expect(all.length, greaterThanOrEqualTo(100));
    });

    test('default foods are marked as estimates', () async {
      await service.seedDefaultFoods(foodRepo, buildDefaultFoods());
      final all = await foodRepo.getAll();
      for (final food in all) {
        expect(food.isEstimate, true);
        expect(food.isCustom, false);
      }
    });

    test('default foods include required Indian items', () async {
      await service.seedDefaultFoods(foodRepo, buildDefaultFoods());
      final all = await foodRepo.getAll();
      final names = all.map((f) => f.name).toSet();

      expect(names, contains('Idli'));
      expect(names, contains('Dosa (plain)'));
      expect(names, contains('Rice (cooked)'));
      expect(names, contains('Dal / Lentils'));
      expect(names, contains('Chapati'));
      expect(names, contains('Paneer'));
      expect(names, contains('Boiled Egg'));
      expect(names, contains('Curd / Yogurt'));
    });

    test('search works on seeded foods', () async {
      await service.seedDefaultFoods(foodRepo, buildDefaultFoods());

      final results = await foodRepo.search('paneer');
      expect(results.isNotEmpty, true);
      expect(results.any((f) => f.name == 'Paneer'), true);
    });

    test('custom food alongside defaults', () async {
      await service.seedDefaultFoods(foodRepo, buildDefaultFoods());

      final custom = Food(
        id: 'custom-1',
        name: 'Homemade Biryani',
        category: 'other',
        caloriesPerServing: 350,
        proteinPerServing: 15,
        carbsPerServing: 45,
        fatPerServing: 12,
        isCustom: true,
        isEstimate: false,
        createdAt: now,
        updatedAt: now,
      );
      await foodRepo.create(custom);

      final all = await foodRepo.getAll();
      final defaultCount = buildDefaultFoods().length;
      expect(all.length, defaultCount + 1);

      final fetched = await foodRepo.getById('custom-1');
      expect(fetched!.isCustom, true);
      expect(fetched.isEstimate, false);
    });
  });

  group('empty state handling', () {
    test('daily totals for day with no entries', () async {
      final totals = await entryRepo.getDailyTotals(DateTime(2025, 7, 1));
      expect(totals['calories'], 0);
      expect(totals['protein'], 0);
    });

    test('water total for day with no entries', () async {
      expect(await waterRepo.getDailyTotalMl(DateTime(2025, 7, 1)), 0);
    });

    test('no active goals returns null', () async {
      expect(await goalRepo.getActiveByType('daily_calories'), isNull);
    });

    test('empty food catalog returns empty search', () async {
      final results = await foodRepo.search('anything');
      expect(results, isEmpty);
    });

    test('no templates returns empty list', () async {
      final templates = await templateRepo.getAll();
      expect(templates, isEmpty);
    });
  });

  group('validation', () {
    test('negative servings rejected by NutritionService', () {
      final food = Food(
        id: 'f1',
        name: 'Rice',
        category: 'staples',
        caloriesPerServing: 200,
        proteinPerServing: 4,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        service.createEntryFromFood(
          food: food,
          servings: -1,
          date: DateTime(2025, 7, 1),
          mealType: 'lunch',
        ),
        isNull,
      );
    });

    test('zero servings rejected by NutritionService', () {
      final food = Food(
        id: 'f1',
        name: 'Rice',
        category: 'staples',
        caloriesPerServing: 200,
        proteinPerServing: 4,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        service.createEntryFromFood(
          food: food,
          servings: 0,
          date: DateTime(2025, 7, 1),
          mealType: 'lunch',
        ),
        isNull,
      );
    });

    test('food entry with all null macros persists', () async {
      final entry = FoodEntry(
        id: 'fe-1',
        date: DateTime(2025, 7, 1),
        mealType: 'snack',
        description: 'Water crackers',
        createdAt: now,
        updatedAt: now,
      );
      await entryRepo.create(entry);

      final fetched = await entryRepo.getById('fe-1');
      expect(fetched, isNotNull);
      expect(fetched!.calories, isNull);
      expect(fetched.proteinGrams, isNull);
    });
  });
}
