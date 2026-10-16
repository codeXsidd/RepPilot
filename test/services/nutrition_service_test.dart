import 'package:flutter_test/flutter_test.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/food.dart';
import 'package:rep_pilot/models/food_entry.dart';
import 'package:rep_pilot/models/meal_template_item.dart';
import 'package:rep_pilot/services/nutrition_service.dart';

void main() {
  const service = NutritionService();
  final now = DateTime(2025, 7, 1, 10, 0, 0);

  Food makeFood({
    String id = 'f1',
    String name = 'Rice',
    double calories = 200,
    double protein = 4,
    double carbs = 45,
    double fat = 0.5,
    String servingUnit = 'cup',
    bool isEstimate = true,
  }) {
    return Food(
      id: id,
      name: name,
      category: 'staples',
      servingSize: 1,
      servingUnit: servingUnit,
      caloriesPerServing: calories,
      proteinPerServing: protein,
      carbsPerServing: carbs,
      fatPerServing: fat,
      isEstimate: isEstimate,
      createdAt: now,
      updatedAt: now,
    );
  }

  FoodEntry makeEntry({
    String? id,
    DateTime? date,
    String mealType = 'lunch',
    double? calories = 500,
    double? protein = 30,
    double? carbs = 50,
    double? fat = 15,
  }) {
    return FoodEntry(
      id: id ?? generateId(),
      date: date ?? DateTime(2025, 7, 1),
      mealType: mealType,
      description: 'Test food',
      calories: calories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('createEntryFromFood', () {
    test('creates entry with correct portion calculation', () {
      final food = makeFood(calories: 200, protein: 4);
      final entry = service.createEntryFromFood(
        food: food,
        servings: 2,
        date: DateTime(2025, 7, 1),
        mealType: 'lunch',
      );

      expect(entry, isNotNull);
      expect(entry!.calories, 400);
      expect(entry.proteinGrams, 8);
      expect(entry.mealType, 'lunch');
      expect(entry.description, contains('Rice'));
      expect(entry.description, contains('2.0'));
    });

    test('returns null for zero servings', () {
      final food = makeFood();
      final entry = service.createEntryFromFood(
        food: food,
        servings: 0,
        date: DateTime(2025, 7, 1),
        mealType: 'lunch',
      );
      expect(entry, isNull);
    });

    test('returns null for negative servings', () {
      final food = makeFood();
      final entry = service.createEntryFromFood(
        food: food,
        servings: -1,
        date: DateTime(2025, 7, 1),
        mealType: 'lunch',
      );
      expect(entry, isNull);
    });

    test('fractional servings compute correctly', () {
      final food = makeFood(calories: 200, protein: 10);
      final entry = service.createEntryFromFood(
        food: food,
        servings: 0.5,
        date: DateTime(2025, 7, 1),
        mealType: 'snack',
      );

      expect(entry, isNotNull);
      expect(entry!.calories, closeTo(100, 0.01));
      expect(entry.proteinGrams, closeTo(5, 0.01));
    });

    test('marks estimate foods in notes', () {
      final food = makeFood(isEstimate: true);
      final entry = service.createEntryFromFood(
        food: food,
        servings: 1,
        date: DateTime(2025, 7, 1),
        mealType: 'lunch',
      );

      expect(entry!.notes, contains('estimates'));
    });

    test('non-estimate foods have empty notes', () {
      final food = makeFood(isEstimate: false);
      final entry = service.createEntryFromFood(
        food: food,
        servings: 1,
        date: DateTime(2025, 7, 1),
        mealType: 'lunch',
      );

      expect(entry!.notes, isEmpty);
    });

    test('large servings compute without overflow', () {
      final food = makeFood(calories: 200);
      final entry = service.createEntryFromFood(
        food: food,
        servings: 100,
        date: DateTime(2025, 7, 1),
        mealType: 'lunch',
      );

      expect(entry!.calories, 20000);
    });
  });

  group('computeDailyTotals', () {
    test('sums all entries correctly', () {
      final entries = [
        makeEntry(calories: 300, protein: 20, carbs: 40, fat: 10),
        makeEntry(calories: 500, protein: 30, carbs: 60, fat: 15),
        makeEntry(calories: 200, protein: 10, carbs: 20, fat: 5),
      ];

      final totals = service.computeDailyTotals(entries);
      expect(totals['calories'], 1000);
      expect(totals['protein'], 60);
      expect(totals['carbs'], 120);
      expect(totals['fat'], 30);
    });

    test('returns zeros for empty list', () {
      final totals = service.computeDailyTotals([]);
      expect(totals['calories'], 0);
      expect(totals['protein'], 0);
      expect(totals['carbs'], 0);
      expect(totals['fat'], 0);
    });

    test('handles null macro fields', () {
      final entries = [
        makeEntry(calories: 300, protein: null, carbs: null, fat: null),
        makeEntry(calories: null, protein: 20, carbs: null, fat: null),
      ];

      final totals = service.computeDailyTotals(entries);
      expect(totals['calories'], 300);
      expect(totals['protein'], 20);
      expect(totals['carbs'], 0);
      expect(totals['fat'], 0);
    });

    test('single entry returns its values', () {
      final entries = [makeEntry(calories: 450, protein: 35)];
      final totals = service.computeDailyTotals(entries);
      expect(totals['calories'], 450);
      expect(totals['protein'], 35);
    });
  });

  group('computeWeeklyAverages', () {
    test('averages across multiple days', () {
      final daily = <DateTime, List<FoodEntry>>{
        DateTime(2025, 7, 1): [
          makeEntry(calories: 2000, protein: 100, carbs: 200, fat: 80),
        ],
        DateTime(2025, 7, 2): [
          makeEntry(calories: 1800, protein: 90, carbs: 180, fat: 70),
        ],
      };

      final avgs = service.computeWeeklyAverages(daily);
      expect(avgs['calories'], closeTo(1900, 0.01));
      expect(avgs['protein'], closeTo(95, 0.01));
    });

    test('returns zeros for empty map', () {
      final avgs = service.computeWeeklyAverages({});
      expect(avgs['calories'], 0);
    });

    test('skips days with empty entry lists', () {
      final daily = <DateTime, List<FoodEntry>>{
        DateTime(2025, 7, 1): [
          makeEntry(calories: 2000, protein: 100, carbs: 200, fat: 80),
        ],
        DateTime(2025, 7, 2): [],
      };

      final avgs = service.computeWeeklyAverages(daily);
      expect(avgs['calories'], 2000);
    });

    test('single day returns its totals', () {
      final daily = <DateTime, List<FoodEntry>>{
        DateTime(2025, 7, 1): [
          makeEntry(calories: 1000, protein: 50, carbs: 100, fat: 40),
          makeEntry(calories: 500, protein: 25, carbs: 50, fat: 20),
        ],
      };

      final avgs = service.computeWeeklyAverages(daily);
      expect(avgs['calories'], 1500);
      expect(avgs['protein'], 75);
    });
  });

  group('groupByMealType', () {
    test('groups entries correctly', () {
      final entries = [
        makeEntry(mealType: 'breakfast'),
        makeEntry(mealType: 'lunch'),
        makeEntry(mealType: 'lunch'),
        makeEntry(mealType: 'dinner'),
        makeEntry(mealType: 'snack'),
        makeEntry(mealType: 'snack'),
        makeEntry(mealType: 'snack'),
      ];

      final grouped = service.groupByMealType(entries);
      expect(grouped['breakfast']!.length, 1);
      expect(grouped['lunch']!.length, 2);
      expect(grouped['dinner']!.length, 1);
      expect(grouped['snack']!.length, 3);
    });

    test('returns empty lists for missing meal types', () {
      final grouped = service.groupByMealType([]);
      expect(grouped['breakfast'], isEmpty);
      expect(grouped['lunch'], isEmpty);
      expect(grouped['dinner'], isEmpty);
      expect(grouped['snack'], isEmpty);
    });
  });

  group('computeMealCalories', () {
    test('sums calories for meal entries', () {
      final entries = [makeEntry(calories: 300), makeEntry(calories: 200)];
      expect(service.computeMealCalories(entries), 500);
    });

    test('returns 0 for empty list', () {
      expect(service.computeMealCalories([]), 0);
    });

    test('handles null calories', () {
      final entries = [makeEntry(calories: 300), makeEntry(calories: null)];
      expect(service.computeMealCalories(entries), 300);
    });
  });

  group('computeTemplateCalories and protein', () {
    test('computes template totals correctly', () {
      final food1 = makeFood(id: 'f1', calories: 140, protein: 4);
      final food2 = makeFood(id: 'f2', calories: 120, protein: 3);
      final foodsById = {'f1': food1, 'f2': food2};

      final items = [
        MealTemplateItem(
          id: 'i1',
          templateId: 't1',
          foodId: 'f1',
          servings: 2,
          createdAt: now,
        ),
        MealTemplateItem(
          id: 'i2',
          templateId: 't1',
          foodId: 'f2',
          servings: 1,
          createdAt: now,
        ),
      ];

      expect(
        service.computeTemplateCalories(items, foodsById),
        closeTo(400, 0.01),
      );
      expect(
        service.computeTemplateProtein(items, foodsById),
        closeTo(11, 0.01),
      );
    });

    test('skips items with missing foods', () {
      final food = makeFood(id: 'f1', calories: 140);
      final foodsById = {'f1': food};

      final items = [
        MealTemplateItem(
          id: 'i1',
          templateId: 't1',
          foodId: 'f1',
          servings: 1,
          createdAt: now,
        ),
        MealTemplateItem(
          id: 'i2',
          templateId: 't1',
          foodId: 'missing',
          servings: 1,
          createdAt: now,
        ),
      ];

      expect(
        service.computeTemplateCalories(items, foodsById),
        closeTo(140, 0.01),
      );
    });

    test('returns 0 for empty items', () {
      expect(service.computeTemplateCalories([], {}), 0);
      expect(service.computeTemplateProtein([], {}), 0);
    });
  });

  group('goalProgress', () {
    test('computes progress correctly', () {
      expect(service.goalProgress(1500, 2000), closeTo(0.75, 0.01));
    });

    test('clamps at 1.0', () {
      expect(service.goalProgress(2500, 2000), 1.0);
    });

    test('returns 0 for null goal', () {
      expect(service.goalProgress(1500, null), 0.0);
    });

    test('returns 0 for zero goal', () {
      expect(service.goalProgress(1500, 0), 0.0);
    });

    test('returns 0 for negative goal', () {
      expect(service.goalProgress(1500, -100), 0.0);
    });

    test('handles zero current value', () {
      expect(service.goalProgress(0, 2000), 0.0);
    });
  });
}
