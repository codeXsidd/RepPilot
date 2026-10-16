import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/food.dart';
import 'package:rep_pilot/models/food_entry.dart';
import 'package:rep_pilot/models/meal_template_item.dart';
import 'package:rep_pilot/repositories/food_entry_repository.dart';
import 'package:rep_pilot/repositories/food_repository.dart';

class NutritionService {
  const NutritionService();

  FoodEntry? createEntryFromFood({
    required Food food,
    required double servings,
    required DateTime date,
    required String mealType,
  }) {
    if (servings <= 0) return null;

    return FoodEntry(
      id: generateId(),
      date: stripTime(date),
      mealType: mealType,
      description:
          '${food.name} (${servings.toStringAsFixed(1)} ${food.servingUnit})',
      calories: food.caloriesFor(servings),
      proteinGrams: food.proteinFor(servings),
      carbsGrams: food.carbsFor(servings),
      fatGrams: food.fatFor(servings),
      notes: food.isEstimate ? 'Nutrition values are estimates' : '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, double> computeDailyTotals(List<FoodEntry> entries) {
    var calories = 0.0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    for (final e in entries) {
      calories += e.calories ?? 0;
      protein += e.proteinGrams ?? 0;
      carbs += e.carbsGrams ?? 0;
      fat += e.fatGrams ?? 0;
    }
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  Map<String, double> computeWeeklyAverages(
    Map<DateTime, List<FoodEntry>> dailyEntries,
  ) {
    if (dailyEntries.isEmpty) {
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    }

    var totalCal = 0.0;
    var totalPro = 0.0;
    var totalCarbs = 0.0;
    var totalFat = 0.0;
    var dayCount = 0;

    for (final entries in dailyEntries.values) {
      if (entries.isEmpty) continue;
      final totals = computeDailyTotals(entries);
      totalCal += totals['calories']!;
      totalPro += totals['protein']!;
      totalCarbs += totals['carbs']!;
      totalFat += totals['fat']!;
      dayCount++;
    }

    if (dayCount == 0) {
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    }

    return {
      'calories': totalCal / dayCount,
      'protein': totalPro / dayCount,
      'carbs': totalCarbs / dayCount,
      'fat': totalFat / dayCount,
    };
  }

  Map<String, List<FoodEntry>> groupByMealType(List<FoodEntry> entries) {
    final grouped = <String, List<FoodEntry>>{
      'breakfast': [],
      'lunch': [],
      'dinner': [],
      'snack': [],
    };
    for (final e in entries) {
      (grouped[e.mealType] ??= []).add(e);
    }
    return grouped;
  }

  double computeMealCalories(List<FoodEntry> mealEntries) {
    return mealEntries.fold<double>(0, (sum, e) => sum + (e.calories ?? 0));
  }

  double computeTemplateCalories(
    List<MealTemplateItem> items,
    Map<String, Food> foodsById,
  ) {
    var total = 0.0;
    for (final item in items) {
      final food = foodsById[item.foodId];
      if (food != null) {
        total += food.caloriesFor(item.servings);
      }
    }
    return total;
  }

  double computeTemplateProtein(
    List<MealTemplateItem> items,
    Map<String, Food> foodsById,
  ) {
    var total = 0.0;
    for (final item in items) {
      final food = foodsById[item.foodId];
      if (food != null) {
        total += food.proteinFor(item.servings);
      }
    }
    return total;
  }

  Future<List<FoodEntry>> applyTemplate({
    required List<MealTemplateItem> items,
    required FoodRepository foodRepo,
    required FoodEntryRepository entryRepo,
    required DateTime date,
    required String mealType,
  }) async {
    final entries = <FoodEntry>[];
    final now = DateTime.now();

    for (final item in items) {
      final food = await foodRepo.getById(item.foodId);
      if (food == null || item.servings <= 0) continue;

      final entry = FoodEntry(
        id: generateId(),
        date: stripTime(date),
        mealType: mealType,
        description:
            '${food.name} (${item.servings.toStringAsFixed(1)} ${food.servingUnit})',
        calories: food.caloriesFor(item.servings),
        proteinGrams: food.proteinFor(item.servings),
        carbsGrams: food.carbsFor(item.servings),
        fatGrams: food.fatFor(item.servings),
        notes: food.isEstimate ? 'Nutrition values are estimates' : '',
        createdAt: now,
        updatedAt: now,
      );
      await entryRepo.create(entry);
      entries.add(entry);
    }
    return entries;
  }

  double goalProgress(double current, double? goal) {
    if (goal == null || goal <= 0) return 0.0;
    return (current / goal).clamp(0.0, 1.0);
  }

  Future<void> seedDefaultFoods(
    FoodRepository repo,
    List<Food> defaults,
  ) async {
    await repo.seedDefaults(defaults);
  }
}
