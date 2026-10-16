import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/food.dart';
import 'package:rep_pilot/models/meal_template.dart';
import 'package:rep_pilot/models/meal_template_item.dart';
import 'package:rep_pilot/repositories/food_repository.dart';
import 'package:rep_pilot/repositories/meal_template_item_repository.dart';
import 'package:rep_pilot/repositories/meal_template_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late MealTemplateRepository templateRepo;
  late MealTemplateItemRepository itemRepo;
  late FoodRepository foodRepo;

  final now = DateTime(2025, 7, 1, 10, 0, 0);

  MealTemplate makeTemplate({
    String? id,
    String name = 'Morning Meal',
    String mealType = 'breakfast',
    String notes = '',
  }) {
    return MealTemplate(
      id: id ?? generateId(),
      name: name,
      mealType: mealType,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  Food makeFood({
    String? id,
    String name = 'Idli',
    double calories = 140,
    double protein = 4,
  }) {
    return Food(
      id: id ?? generateId(),
      name: name,
      category: 'breakfast',
      servingSize: 2,
      servingUnit: 'pieces',
      caloriesPerServing: calories,
      proteinPerServing: protein,
      carbsPerServing: 28,
      fatPerServing: 1,
      isCustom: false,
      isEstimate: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  MealTemplateItem makeItem({
    String? id,
    required String templateId,
    required String foodId,
    double servings = 1.0,
  }) {
    return MealTemplateItem(
      id: id ?? generateId(),
      templateId: templateId,
      foodId: foodId,
      servings: servings,
      createdAt: now,
    );
  }

  setUp(() async {
    db = await openTestDatabase();
    templateRepo = MealTemplateRepository(db);
    itemRepo = MealTemplateItemRepository(db);
    foodRepo = FoodRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MealTemplateRepository CRUD', () {
    test('create and getById', () async {
      final t = makeTemplate(id: 't1');
      await templateRepo.create(t);

      final fetched = await templateRepo.getById('t1');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Morning Meal');
      expect(fetched.mealType, 'breakfast');
    });

    test('getById returns null for non-existent', () async {
      expect(await templateRepo.getById('nope'), isNull);
    });

    test('getAll returns templates sorted by name', () async {
      await templateRepo.create(makeTemplate(name: 'Dinner Set'));
      await templateRepo.create(makeTemplate(name: 'Breakfast Set'));

      final all = await templateRepo.getAll();
      expect(all.length, 2);
      expect(all[0].name, 'Breakfast Set');
      expect(all[1].name, 'Dinner Set');
    });

    test('getByMealType filters correctly', () async {
      await templateRepo.create(makeTemplate(name: 'A', mealType: 'breakfast'));
      await templateRepo.create(makeTemplate(name: 'B', mealType: 'lunch'));
      await templateRepo.create(makeTemplate(name: 'C', mealType: 'breakfast'));

      final breakfast = await templateRepo.getByMealType('breakfast');
      expect(breakfast.length, 2);
    });

    test('update modifies template', () async {
      final t = makeTemplate(id: 't1');
      await templateRepo.create(t);

      await templateRepo.update(t.copyWith(name: 'Updated Name'));
      final fetched = await templateRepo.getById('t1');
      expect(fetched!.name, 'Updated Name');
    });

    test('delete removes template', () async {
      final t = makeTemplate(id: 't1');
      await templateRepo.create(t);
      await templateRepo.delete('t1');
      expect(await templateRepo.getById('t1'), isNull);
    });
  });

  group('MealTemplateItemRepository', () {
    test('create and getByTemplateId', () async {
      final food = makeFood(id: 'food1');
      await foodRepo.create(food);

      final t = makeTemplate(id: 't1');
      await templateRepo.create(t);

      await itemRepo.create(
        makeItem(templateId: 't1', foodId: 'food1', servings: 2.0),
      );
      await itemRepo.create(
        makeItem(templateId: 't1', foodId: 'food1', servings: 1.0),
      );

      final items = await itemRepo.getByTemplateId('t1');
      expect(items.length, 2);
    });

    test('getByTemplateId returns empty for no items', () async {
      final items = await itemRepo.getByTemplateId('non-existent');
      expect(items, isEmpty);
    });

    test('delete removes single item', () async {
      final food = makeFood(id: 'food1');
      await foodRepo.create(food);

      final t = makeTemplate(id: 't1');
      await templateRepo.create(t);

      final item = makeItem(id: 'item1', templateId: 't1', foodId: 'food1');
      await itemRepo.create(item);
      await itemRepo.delete('item1');

      final items = await itemRepo.getByTemplateId('t1');
      expect(items, isEmpty);
    });

    test('deleteAllForTemplate removes all items', () async {
      final food = makeFood(id: 'food1');
      await foodRepo.create(food);

      final t = makeTemplate(id: 't1');
      await templateRepo.create(t);

      await itemRepo.create(makeItem(templateId: 't1', foodId: 'food1'));
      await itemRepo.create(makeItem(templateId: 't1', foodId: 'food1'));
      await itemRepo.create(makeItem(templateId: 't1', foodId: 'food1'));

      await itemRepo.deleteAllForTemplate('t1');
      final items = await itemRepo.getByTemplateId('t1');
      expect(items, isEmpty);
    });

    test('items persist correct servings', () async {
      final food = makeFood(id: 'food1');
      await foodRepo.create(food);

      final t = makeTemplate(id: 't1');
      await templateRepo.create(t);

      await itemRepo.create(
        makeItem(templateId: 't1', foodId: 'food1', servings: 2.5),
      );

      final items = await itemRepo.getByTemplateId('t1');
      expect(items.first.servings, 2.5);
    });
  });

  group('template with foods', () {
    test('template items reference valid foods', () async {
      final food1 = makeFood(id: 'food1', name: 'Idli', calories: 140);
      final food2 = makeFood(id: 'food2', name: 'Dosa', calories: 120);
      await foodRepo.create(food1);
      await foodRepo.create(food2);

      final t = makeTemplate(id: 't1', name: 'South Indian Breakfast');
      await templateRepo.create(t);

      await itemRepo.create(
        makeItem(templateId: 't1', foodId: 'food1', servings: 2),
      );
      await itemRepo.create(
        makeItem(templateId: 't1', foodId: 'food2', servings: 1),
      );

      final items = await itemRepo.getByTemplateId('t1');
      expect(items.length, 2);

      var totalCalories = 0.0;
      for (final item in items) {
        final food = await foodRepo.getById(item.foodId);
        expect(food, isNotNull);
        totalCalories += food!.caloriesFor(item.servings);
      }
      expect(totalCalories, closeTo(400, 0.01));
    });

    test('deleting food cascades to template items', () async {
      final food = makeFood(id: 'food1');
      await foodRepo.create(food);

      final t = makeTemplate(id: 't1');
      await templateRepo.create(t);

      await itemRepo.create(makeItem(templateId: 't1', foodId: 'food1'));

      await foodRepo.delete('food1');
      final items = await itemRepo.getByTemplateId('t1');
      expect(items, isEmpty);
    });
  });
}
