import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/body_weight_entry.dart';
import 'package:rep_pilot/models/food_entry.dart';
import 'package:rep_pilot/models/water_entry.dart';
import 'package:rep_pilot/models/workout_session.dart';
import 'package:rep_pilot/models/workout_set.dart';
import 'package:rep_pilot/repositories/body_weight_repository.dart';
import 'package:rep_pilot/repositories/food_entry_repository.dart';
import 'package:rep_pilot/repositories/water_entry_repository.dart';
import 'package:rep_pilot/repositories/workout_session_repository.dart';
import 'package:rep_pilot/repositories/workout_set_repository.dart';
import 'package:rep_pilot/services/streak_service.dart';
import 'package:rep_pilot/services/weekly_report_service.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late WorkoutSessionRepository sessionRepo;
  late WorkoutSetRepository setRepo;
  late BodyWeightRepository weightRepo;
  late FoodEntryRepository foodRepo;
  late WaterEntryRepository waterRepo;
  late WeeklyReportService service;

  final monday = DateTime(2025, 7, 7);

  setUp(() async {
    db = await openTestDatabase();
    sessionRepo = WorkoutSessionRepository(db);
    setRepo = WorkoutSetRepository(db);
    weightRepo = BodyWeightRepository(db);
    foodRepo = FoodEntryRepository(db);
    waterRepo = WaterEntryRepository(db);
    service = const WeeklyReportService(StreakService());
    await db.insert('exercises', {
      'id': 'e1',
      'name': 'Bench Press',
      'category': 'chest',
      'muscle_group': 'chest',
      'notes': '',
      'is_custom': 0,
      'is_archived': 0,
      'created_at': monday.toIso8601String(),
      'updated_at': monday.toIso8601String(),
    });
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> createCompletedSession({
    required DateTime startedAt,
    required DateTime completedAt,
    List<WorkoutSet>? sets,
  }) async {
    final session = WorkoutSession(
      id: generateId(),
      startedAt: startedAt,
      completedAt: completedAt,
      createdAt: startedAt,
      updatedAt: completedAt,
    );
    await sessionRepo.create(session);
    if (sets != null) {
      for (final s in sets) {
        await setRepo.create(s.copyWith(sessionId: session.id));
      }
    }
  }

  group('empty state', () {
    test('report with no data has zero values', () async {
      final report = await service.generateReport(
        weekStart: monday,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.workoutsCompleted, 0);
      expect(report.totalVolumeKg, 0);
      expect(report.personalRecordsCount, 0);
      expect(report.weightStart, isNull);
      expect(report.weightEnd, isNull);
      expect(report.averageCalories, isNull);
      expect(report.averageProtein, isNull);
      expect(report.averageWaterMl, isNull);
      expect(report.hasAnyData, false);
    });
  });

  group('workout data', () {
    test('counts completed sessions in the week', () async {
      await createCompletedSession(
        startedAt: DateTime(2025, 7, 7, 10),
        completedAt: DateTime(2025, 7, 7, 11),
      );
      await createCompletedSession(
        startedAt: DateTime(2025, 7, 9, 10),
        completedAt: DateTime(2025, 7, 9, 11),
      );

      final report = await service.generateReport(
        weekStart: monday,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.workoutsCompleted, 2);
      expect(report.hasWorkoutData, true);
    });

    test('does not count incomplete sessions', () async {
      await sessionRepo.create(
        WorkoutSession(
          id: generateId(),
          startedAt: DateTime(2025, 7, 8, 10),
          createdAt: DateTime(2025, 7, 8, 10),
          updatedAt: DateTime(2025, 7, 8, 10),
        ),
      );

      final report = await service.generateReport(
        weekStart: monday,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.workoutsCompleted, 0);
    });

    test('excludes sessions from other weeks', () async {
      await createCompletedSession(
        startedAt: DateTime(2025, 7, 1, 10),
        completedAt: DateTime(2025, 7, 1, 11),
      );
      await createCompletedSession(
        startedAt: DateTime(2025, 7, 7, 10),
        completedAt: DateTime(2025, 7, 7, 11),
      );

      final report = await service.generateReport(
        weekStart: monday,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.workoutsCompleted, 1);
    });

    test('calculates total volume', () async {
      final sessionId = generateId();
      await sessionRepo.create(
        WorkoutSession(
          id: sessionId,
          startedAt: DateTime(2025, 7, 7, 10),
          completedAt: DateTime(2025, 7, 7, 11),
          createdAt: DateTime(2025, 7, 7, 10),
          updatedAt: DateTime(2025, 7, 7, 11),
        ),
      );
      await setRepo.create(
        WorkoutSet(
          id: generateId(),
          sessionId: sessionId,
          exerciseId: 'e1',
          exerciseName: 'Bench Press',
          setNumber: 1,
          reps: 10,
          weightKg: 60,
          completed: true,
        ),
      );
      await setRepo.create(
        WorkoutSet(
          id: generateId(),
          sessionId: sessionId,
          exerciseId: 'e1',
          exerciseName: 'Bench Press',
          setNumber: 2,
          reps: 8,
          weightKg: 60,
          completed: true,
        ),
      );

      final report = await service.generateReport(
        weekStart: monday,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.totalVolumeKg, closeTo(1080, 0.01));
    });
  });

  group('body weight data', () {
    test('captures start and end weight', () async {
      await weightRepo.create(
        BodyWeightEntry(
          id: generateId(),
          date: DateTime(2025, 7, 7),
          weightKg: 80.0,
          createdAt: monday,
          updatedAt: monday,
        ),
      );
      await weightRepo.create(
        BodyWeightEntry(
          id: generateId(),
          date: DateTime(2025, 7, 11),
          weightKg: 79.5,
          createdAt: monday,
          updatedAt: monday,
        ),
      );

      final report = await service.generateReport(
        weekStart: monday,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.weightStart, 80.0);
      expect(report.weightEnd, 79.5);
      expect(report.weightChange, closeTo(-0.5, 0.01));
      expect(report.hasWeightData, true);
    });

    test('single weight entry has no change', () async {
      await weightRepo.create(
        BodyWeightEntry(
          id: generateId(),
          date: DateTime(2025, 7, 9),
          weightKg: 80.0,
          createdAt: monday,
          updatedAt: monday,
        ),
      );

      final report = await service.generateReport(
        weekStart: monday,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.weightStart, 80.0);
      expect(report.weightEnd, isNull);
      expect(report.weightChange, isNull);
    });
  });

  group('nutrition data', () {
    test('averages calories and protein across logged days', () async {
      await foodRepo.create(
        FoodEntry(
          id: generateId(),
          date: DateTime(2025, 7, 7),
          mealType: 'lunch',
          description: 'Rice',
          calories: 2000,
          proteinGrams: 100,
          createdAt: monday,
          updatedAt: monday,
        ),
      );
      await foodRepo.create(
        FoodEntry(
          id: generateId(),
          date: DateTime(2025, 7, 8),
          mealType: 'lunch',
          description: 'Dal',
          calories: 1800,
          proteinGrams: 80,
          createdAt: monday,
          updatedAt: monday,
        ),
      );

      final report = await service.generateReport(
        weekStart: monday,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.averageCalories, closeTo(1900, 0.01));
      expect(report.averageProtein, closeTo(90, 0.01));
      expect(report.hasNutritionData, true);
    });

    test('skips days with no food entries', () async {
      await foodRepo.create(
        FoodEntry(
          id: generateId(),
          date: DateTime(2025, 7, 7),
          mealType: 'lunch',
          description: 'Rice',
          calories: 2000,
          proteinGrams: 100,
          createdAt: monday,
          updatedAt: monday,
        ),
      );

      final report = await service.generateReport(
        weekStart: monday,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.averageCalories, closeTo(2000, 0.01));
    });
  });

  group('water data', () {
    test('averages water intake across logged days', () async {
      await waterRepo.create(
        WaterEntry(
          id: generateId(),
          date: DateTime(2025, 7, 7),
          amountMl: 2000,
          createdAt: monday,
        ),
      );
      await waterRepo.create(
        WaterEntry(
          id: generateId(),
          date: DateTime(2025, 7, 8),
          amountMl: 2500,
          createdAt: monday,
        ),
      );

      final report = await service.generateReport(
        weekStart: monday,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.averageWaterMl, closeTo(2250, 0.01));
      expect(report.hasWaterData, true);
    });
  });

  group('date boundaries', () {
    test('weekStart is normalized to Monday', () async {
      final report = await service.generateReport(
        weekStart: DateTime(2025, 7, 9),
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.weekStart.weekday, DateTime.monday);
      expect(report.weekEnd.weekday, DateTime.sunday);
    });

    test('report covers exactly 7 days', () async {
      final report = await service.generateReport(
        weekStart: monday,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      final diff = report.weekEnd.difference(report.weekStart).inDays;
      expect(diff, 6);
    });
  });

  group('streak in report', () {
    test('includes current streak', () async {
      await createCompletedSession(
        startedAt: DateTime(2025, 7, 12, 10),
        completedAt: DateTime(2025, 7, 12, 11),
      );
      await createCompletedSession(
        startedAt: DateTime(2025, 7, 13, 10),
        completedAt: DateTime(2025, 7, 13, 11),
      );

      final report = await service.generateReport(
        weekStart: monday,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.currentStreak, 2);
      expect(report.longestStreak, 2);
    });
  });
}
