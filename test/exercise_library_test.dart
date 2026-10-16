import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:rep_pilot/core/data/default_exercises.dart';
import 'package:rep_pilot/core/data/exercise_catalog.dart';
import 'package:rep_pilot/models/exercise.dart';
import 'package:rep_pilot/repositories/exercise_repository.dart';

import 'helpers/test_database.dart';

void main() {
  group('Exercise catalog validation', () {
    late List<Exercise> catalog;

    setUpAll(() {
      catalog = buildExerciseCatalog();
    });

    test('contains at least 150 exercises', () {
      expect(catalog.length, greaterThanOrEqualTo(150));
    });

    test('no duplicate IDs', () {
      final ids = catalog.map((e) => e.id).toSet();
      expect(ids.length, catalog.length);
    });

    test('no duplicate names', () {
      final names = catalog.map((e) => e.name.toLowerCase()).toSet();
      expect(names.length, catalog.length);
    });

    test('all IDs follow the default-ex-NNN pattern', () {
      for (final e in catalog) {
        expect(
          e.id,
          matches(RegExp(r'^default-ex-\d{3}$')),
          reason: '${e.name} has invalid ID: ${e.id}',
        );
      }
    });

    test('all exercises are non-custom', () {
      for (final e in catalog) {
        expect(e.isCustom, false, reason: '${e.name} should not be custom');
      }
    });

    test('all exercises have a valid category', () {
      for (final e in catalog) {
        expect(
          exerciseCategories,
          contains(e.category),
          reason: '${e.name} has invalid category: ${e.category}',
        );
      }
    });

    test('all exercises have a non-empty name', () {
      for (final e in catalog) {
        expect(e.name.trim().isNotEmpty, true);
      }
    });

    test('all exercises have a non-empty muscle group', () {
      for (final e in catalog) {
        expect(
          e.muscleGroup.isNotEmpty,
          true,
          reason: '${e.name} missing muscle group',
        );
      }
    });

    test('all exercises have a valid difficulty', () {
      for (final e in catalog) {
        expect(
          difficultyLevels,
          contains(e.difficulty),
          reason: '${e.name} has invalid difficulty: ${e.difficulty}',
        );
      }
    });

    test('all exercises have a non-empty description', () {
      for (final e in catalog) {
        expect(
          e.description.isNotEmpty,
          true,
          reason: '${e.name} missing description',
        );
      }
    });

    test('all exercises have non-empty instructions', () {
      for (final e in catalog) {
        expect(
          e.instructions.isNotEmpty,
          true,
          reason: '${e.name} missing instructions',
        );
      }
    });

    test('default programming values are reasonable', () {
      for (final e in catalog) {
        expect(
          e.defaultSets,
          inInclusiveRange(1, 10),
          reason: '${e.name} sets',
        );
        expect(
          e.defaultRepsMin,
          inInclusiveRange(1, 60),
          reason: '${e.name} repsMin',
        );
        expect(
          e.defaultRepsMax,
          greaterThanOrEqualTo(e.defaultRepsMin),
          reason: '${e.name} repsMax >= repsMin',
        );
        expect(
          e.defaultRestSeconds,
          inInclusiveRange(15, 300),
          reason: '${e.name} rest',
        );
        expect(
          e.defaultIncrementKg,
          greaterThanOrEqualTo(0),
          reason: '${e.name} increment',
        );
      }
    });

    test('all categories are represented', () {
      final usedCategories = catalog.map((e) => e.category).toSet();
      for (final cat in exerciseCategories) {
        expect(
          usedCategories,
          contains(cat),
          reason: 'Category $cat has no exercises',
        );
      }
    });

    test('suitableForGym is true for all exercises', () {
      for (final e in catalog) {
        expect(
          e.suitableForGym,
          true,
          reason: '${e.name} should be suitable for gym',
        );
      }
    });

    test('bodyweight exercises have zero increment', () {
      for (final e in catalog.where((e) => e.isBodyweight)) {
        expect(
          e.defaultIncrementKg,
          0.0,
          reason: '${e.name} is bodyweight but has non-zero increment',
        );
      }
    });
  });

  group('Exercise model extended fields', () {
    final now = DateTime(2025, 6, 15, 10, 0);

    test('round-trips new fields through toMap/fromMap', () {
      final e = Exercise(
        id: 'test-1',
        name: 'Test Exercise',
        category: 'chest',
        muscleGroup: 'Pectorals',
        equipment: 'barbell',
        createdAt: now,
        updatedAt: now,
        secondaryMuscles: 'Triceps,Anterior Deltoid',
        difficulty: 'advanced',
        description: 'A test exercise',
        instructions: 'Push the bar up',
        movementPattern: 'push',
        defaultSets: 4,
        defaultRepsMin: 6,
        defaultRepsMax: 8,
        defaultRestSeconds: 120,
        defaultIncrementKg: 2.5,
        aliases: 'Bench,BP',
        substitutionIds: 'ex-2,ex-3',
        isBodyweight: false,
        isUnilateral: false,
        isMachine: false,
        suitableForHome: false,
        suitableForGym: true,
        isFavorite: true,
        lastUsedAt: now,
        safetyNotes: 'Use a spotter',
      );

      final map = e.toMap();
      final restored = Exercise.fromMap(map);

      expect(restored.secondaryMuscles, 'Triceps,Anterior Deltoid');
      expect(restored.difficulty, 'advanced');
      expect(restored.description, 'A test exercise');
      expect(restored.instructions, 'Push the bar up');
      expect(restored.movementPattern, 'push');
      expect(restored.defaultSets, 4);
      expect(restored.defaultRepsMin, 6);
      expect(restored.defaultRepsMax, 8);
      expect(restored.defaultRestSeconds, 120);
      expect(restored.defaultIncrementKg, 2.5);
      expect(restored.aliases, 'Bench,BP');
      expect(restored.substitutionIds, 'ex-2,ex-3');
      expect(restored.isBodyweight, false);
      expect(restored.isUnilateral, false);
      expect(restored.isMachine, false);
      expect(restored.suitableForHome, false);
      expect(restored.suitableForGym, true);
      expect(restored.isFavorite, true);
      expect(restored.lastUsedAt, now);
      expect(restored.safetyNotes, 'Use a spotter');
    });

    test('copyWith can set lastUsedAt to null', () {
      final e = Exercise(
        id: 'test-1',
        name: 'Test',
        createdAt: now,
        updatedAt: now,
        lastUsedAt: now,
      );
      final cleared = e.copyWith(lastUsedAt: null);
      expect(cleared.lastUsedAt, isNull);
    });

    test('copyWith preserves lastUsedAt when not specified', () {
      final e = Exercise(
        id: 'test-1',
        name: 'Test',
        createdAt: now,
        updatedAt: now,
        lastUsedAt: now,
      );
      final copied = e.copyWith(name: 'Updated');
      expect(copied.lastUsedAt, now);
      expect(copied.name, 'Updated');
    });

    test('aliasList splits comma-separated aliases', () {
      final e = Exercise(
        id: 'test-1',
        name: 'Test',
        createdAt: now,
        updatedAt: now,
        aliases: 'Bench,BP,Flat Press',
      );
      expect(e.aliasList, ['Bench', 'BP', 'Flat Press']);
    });

    test('aliasList returns empty list when aliases is empty', () {
      final e = Exercise(
        id: 'test-1',
        name: 'Test',
        createdAt: now,
        updatedAt: now,
      );
      expect(e.aliasList, isEmpty);
    });

    test('secondaryMuscleList splits correctly', () {
      final e = Exercise(
        id: 'test-1',
        name: 'Test',
        createdAt: now,
        updatedAt: now,
        secondaryMuscles: 'Triceps, Anterior Deltoid',
      );
      expect(e.secondaryMuscleList, ['Triceps', 'Anterior Deltoid']);
    });

    test('fromMap handles missing new fields gracefully', () {
      final map = <String, dynamic>{
        'id': 'old-1',
        'name': 'Old Exercise',
        'category': 'chest',
        'muscle_group': 'Pectorals',
        'equipment': 'barbell',
        'notes': '',
        'is_custom': 1,
        'is_archived': 0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      final e = Exercise.fromMap(map);
      expect(e.difficulty, 'intermediate');
      expect(e.defaultSets, 3);
      expect(e.defaultRepsMin, 8);
      expect(e.defaultRepsMax, 12);
      expect(e.isFavorite, false);
      expect(e.lastUsedAt, isNull);
      expect(e.safetyNotes, '');
    });
  });

  group('Exercise repository — new methods', () {
    late Database db;
    late ExerciseRepository repo;
    final now = DateTime(2025, 6, 15, 10, 0);

    Exercise makeExercise({
      String id = 'ex-1',
      String name = 'Bench Press',
      String category = 'chest',
      String equipment = 'barbell',
      String muscleGroup = 'Pectorals',
      String difficulty = 'intermediate',
      bool isCustom = true,
      bool suitableForHome = false,
      String aliases = '',
    }) => Exercise(
      id: id,
      name: name,
      category: category,
      equipment: equipment,
      muscleGroup: muscleGroup,
      difficulty: difficulty,
      isCustom: isCustom,
      suitableForHome: suitableForHome,
      aliases: aliases,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() async {
      db = await openTestDatabase();
      repo = ExerciseRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('toggleFavorite flips the flag', () async {
      await repo.create(makeExercise());
      expect((await repo.getById('ex-1'))!.isFavorite, false);

      await repo.toggleFavorite('ex-1');
      expect((await repo.getById('ex-1'))!.isFavorite, true);

      await repo.toggleFavorite('ex-1');
      expect((await repo.getById('ex-1'))!.isFavorite, false);
    });

    test('getFavorites returns only favorites', () async {
      await repo.create(makeExercise(id: 'a', name: 'A'));
      await repo.create(makeExercise(id: 'b', name: 'B'));
      await repo.toggleFavorite('a');

      final favs = await repo.getFavorites();
      expect(favs.length, 1);
      expect(favs.first.id, 'a');
    });

    test('updateLastUsed sets timestamp', () async {
      await repo.create(makeExercise());
      expect((await repo.getById('ex-1'))!.lastUsedAt, isNull);

      await repo.updateLastUsed('ex-1');
      final updated = await repo.getById('ex-1');
      expect(updated!.lastUsedAt, isNotNull);
    });

    test('getRecentlyUsed returns exercises ordered by last used', () async {
      await repo.create(makeExercise(id: 'a', name: 'A'));
      await repo.create(makeExercise(id: 'b', name: 'B'));
      await repo.create(makeExercise(id: 'c', name: 'C'));

      await repo.updateLastUsed('b');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await repo.updateLastUsed('a');

      final recent = await repo.getRecentlyUsed();
      expect(recent.length, 2);
      expect(recent[0].id, 'a');
      expect(recent[1].id, 'b');
    });

    test('getByDifficulty filters correctly', () async {
      await repo.create(
        makeExercise(id: 'a', name: 'A', difficulty: 'beginner'),
      );
      await repo.create(
        makeExercise(id: 'b', name: 'B', difficulty: 'advanced'),
      );
      await repo.create(
        makeExercise(id: 'c', name: 'C', difficulty: 'intermediate'),
      );

      final beginners = await repo.getByDifficulty('beginner');
      expect(beginners.length, 1);
      expect(beginners.first.id, 'a');
    });

    test('getByEquipment filters correctly', () async {
      await repo.create(makeExercise(id: 'a', name: 'A', equipment: 'barbell'));
      await repo.create(
        makeExercise(id: 'b', name: 'B', equipment: 'dumbbell'),
      );

      final barbells = await repo.getByEquipment('barbell');
      expect(barbells.length, 1);
      expect(barbells.first.id, 'a');
    });

    test('getHomeExercises returns only home-suitable', () async {
      await repo.create(
        makeExercise(id: 'a', name: 'A', suitableForHome: true),
      );
      await repo.create(
        makeExercise(id: 'b', name: 'B', suitableForHome: false),
      );

      final home = await repo.getHomeExercises();
      expect(home.length, 1);
      expect(home.first.id, 'a');
    });

    test('getFiltered combines multiple criteria', () async {
      await repo.create(
        makeExercise(
          id: 'a',
          name: 'Home Beginner',
          difficulty: 'beginner',
          equipment: 'bodyweight',
          suitableForHome: true,
        ),
      );
      await repo.create(
        makeExercise(
          id: 'b',
          name: 'Gym Advanced',
          difficulty: 'advanced',
          equipment: 'barbell',
          suitableForHome: false,
        ),
      );
      await repo.create(
        makeExercise(
          id: 'c',
          name: 'Home Advanced',
          difficulty: 'advanced',
          equipment: 'bodyweight',
          suitableForHome: true,
        ),
      );

      final result = await repo.getFiltered(
        difficulty: 'advanced',
        suitableForHome: true,
      );
      expect(result.length, 1);
      expect(result.first.id, 'c');
    });

    test('getFiltered with searchQuery matches aliases', () async {
      await repo.create(
        makeExercise(id: 'a', name: 'Bench Press', aliases: 'BP,Flat Bench'),
      );
      await repo.create(
        makeExercise(id: 'b', name: 'Squat', aliases: 'Back Squat'),
      );

      final result = await repo.getFiltered(searchQuery: 'Flat');
      expect(result.length, 1);
      expect(result.first.id, 'a');
    });

    test('search matches aliases column', () async {
      await repo.create(
        makeExercise(id: 'a', name: 'Bench Press', aliases: 'BP,Flat Bench'),
      );

      final result = await repo.search('Flat');
      expect(result.length, 1);
      expect(result.first.id, 'a');
    });

    test('getDistinctEquipment returns unique values', () async {
      await repo.create(makeExercise(id: '1', name: 'A', equipment: 'barbell'));
      await repo.create(
        makeExercise(id: '2', name: 'B', equipment: 'dumbbell'),
      );
      await repo.create(makeExercise(id: '3', name: 'C', equipment: 'barbell'));

      final equip = await repo.getDistinctEquipment();
      expect(equip.length, 2);
      expect(equip, contains('barbell'));
      expect(equip, contains('dumbbell'));
    });

    test('countDefaultExercises counts non-custom exercises', () async {
      await repo.create(makeExercise(id: 'a', name: 'A', isCustom: false));
      await repo.create(makeExercise(id: 'b', name: 'B', isCustom: true));
      expect(await repo.countDefaultExercises(), 1);
    });
  });

  group('Seeding with catalog', () {
    late Database db;
    late ExerciseRepository repo;

    setUp(() async {
      db = await openTestDatabase();
      repo = ExerciseRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('seedDefaults inserts full catalog', () async {
      final catalog = buildExerciseCatalog();
      await repo.seedDefaults(catalog);

      final count = await repo.countDefaultExercises();
      expect(count, catalog.length);
    });

    test('seedDefaults is idempotent', () async {
      final catalog = buildExerciseCatalog();
      await repo.seedDefaults(catalog);
      await repo.seedDefaults(catalog);

      final count = await repo.countDefaultExercises();
      expect(count, catalog.length);
    });

    test('seedDefaults preserves user favorites on re-seed', () async {
      final catalog = buildExerciseCatalog();
      await repo.seedDefaults(catalog);

      await repo.toggleFavorite(catalog.first.id);
      expect((await repo.getById(catalog.first.id))!.isFavorite, true);

      await repo.seedDefaults(catalog);

      final afterReseed = await repo.getById(catalog.first.id);
      expect(afterReseed!.isFavorite, true);
    });

    test('seedDefaults does not overwrite user-created exercises', () async {
      final now = DateTime.now();
      final userExercise = Exercise(
        id: 'user-custom-1',
        name: 'My Custom Exercise',
        category: 'chest',
        isCustom: true,
        createdAt: now,
        updatedAt: now,
      );
      await repo.create(userExercise);

      final catalog = buildExerciseCatalog();
      await repo.seedDefaults(catalog);

      final custom = await repo.getById('user-custom-1');
      expect(custom, isNotNull);
      expect(custom!.name, 'My Custom Exercise');
      expect(custom.isCustom, true);
    });

    test('all seeded exercises are searchable', () async {
      final catalog = buildExerciseCatalog();
      await repo.seedDefaults(catalog);

      final all = await repo.getAll();
      expect(all.length, catalog.length);

      final searched = await repo.search('press');
      expect(searched.isNotEmpty, true);
    });
  });

  group('buildDefaultExercises compatibility', () {
    test('buildDefaultExercises returns same list as buildExerciseCatalog', () {
      final fromDefault = buildDefaultExercises();
      final fromCatalog = buildExerciseCatalog();
      expect(fromDefault.length, fromCatalog.length);
      expect(fromDefault.first.id, fromCatalog.first.id);
    });
  });
}
