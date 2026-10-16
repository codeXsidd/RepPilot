import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/core/data/motivational_messages.dart';
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
import 'package:rep_pilot/services/motivation_service.dart';
import 'package:rep_pilot/services/reminder_service.dart';
import 'package:rep_pilot/services/streak_service.dart';
import 'package:rep_pilot/services/weekly_report_service.dart';

import 'helpers/test_database.dart';

void main() {
  late Database db;
  late WorkoutSessionRepository sessionRepo;
  late WorkoutSetRepository setRepo;
  late BodyWeightRepository weightRepo;
  late FoodEntryRepository foodRepo;
  late WaterEntryRepository waterRepo;

  const motivation = MotivationService();
  const streak = StreakService();
  const reportService = WeeklyReportService(streak);

  setUp(() async {
    db = await openTestDatabase();
    sessionRepo = WorkoutSessionRepository(db);
    setRepo = WorkoutSetRepository(db);
    weightRepo = BodyWeightRepository(db);
    foodRepo = FoodEntryRepository(db);
    waterRepo = WaterEntryRepository(db);
    final now = DateTime(2025, 7, 7);
    await db.insert('exercises', {
      'id': 'e1',
      'name': 'Squat',
      'category': 'legs',
      'muscle_group': 'legs',
      'notes': '',
      'is_custom': 0,
      'is_archived': 0,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
  });

  tearDown(() async {
    await db.close();
  });

  WorkoutSession completedSession({required DateTime completedAt, String? id}) {
    final sid = id ?? generateId();
    return WorkoutSession(
      id: sid,
      startedAt: completedAt.subtract(const Duration(hours: 1)),
      completedAt: completedAt,
      createdAt: completedAt,
      updatedAt: completedAt,
    );
  }

  group('motivation + streak lifecycle', () {
    test('daily message is stable and from the pool', () {
      final date = DateTime(2025, 7, 10);
      final msg = motivation.getMessageForDate(date);
      expect(motivationalMessages, contains(msg));
      expect(motivation.getMessageForDate(date), msg);
    });

    test('streak builds as workouts are completed', () async {
      final sessions = <WorkoutSession>[];
      for (var i = 0; i < 5; i++) {
        final s = completedSession(completedAt: DateTime(2025, 7, 6 + i, 10));
        await sessionRepo.create(s);
        sessions.add(s);
      }

      final allSessions = await sessionRepo.getAll();
      final current = streak.getCurrentStreak(
        allSessions,
        DateTime(2025, 7, 10, 15),
      );
      expect(current, 5);
    });

    test('streak resets after gap and provides supportive message', () async {
      await sessionRepo.create(
        completedSession(completedAt: DateTime(2025, 7, 5, 10)),
      );

      final allSessions = await sessionRepo.getAll();
      final current = streak.getCurrentStreak(
        allSessions,
        DateTime(2025, 7, 10, 15),
      );
      expect(current, 0);

      final msg = streak.getStreakMessage(current);
      expect(msg, isNotEmpty);
      expect(msg.toLowerCase(), isNot(contains('lazy')));
      expect(msg.toLowerCase(), isNot(contains('fail')));
    });

    test('milestones accumulate with workouts', () async {
      final sessions = <WorkoutSession>[];
      for (var i = 0; i < 10; i++) {
        final s = completedSession(completedAt: DateTime(2025, 7, 1 + i, 10));
        await sessionRepo.create(s);
        sessions.add(s);
      }

      final allSessions = await sessionRepo.getAll();
      final currentStreak = streak.getCurrentStreak(
        allSessions,
        DateTime(2025, 7, 10, 15),
      );
      final total = streak.getTotalWorkouts(allSessions);
      final milestones = streak.getReachedMilestones(currentStreak, total);

      expect(milestones, contains(7));
      expect(milestones, contains(10));
    });
  });

  group('weekly report from real data', () {
    test('report aggregates workouts, weight, food and water', () async {
      final monday = DateTime(2025, 7, 7);

      final sid = generateId();
      await sessionRepo.create(
        WorkoutSession(
          id: sid,
          startedAt: DateTime(2025, 7, 8, 10),
          completedAt: DateTime(2025, 7, 8, 11),
          createdAt: DateTime(2025, 7, 8, 10),
          updatedAt: DateTime(2025, 7, 8, 11),
        ),
      );
      await setRepo.create(
        WorkoutSet(
          id: generateId(),
          sessionId: sid,
          exerciseId: 'e1',
          exerciseName: 'Squat',
          setNumber: 1,
          reps: 5,
          weightKg: 100,
          completed: true,
        ),
      );

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
          date: DateTime(2025, 7, 12),
          weightKg: 79.5,
          createdAt: monday,
          updatedAt: monday,
        ),
      );

      await foodRepo.create(
        FoodEntry(
          id: generateId(),
          date: DateTime(2025, 7, 7),
          mealType: 'lunch',
          description: 'Rice',
          calories: 2000,
          proteinGrams: 80,
          createdAt: monday,
          updatedAt: monday,
        ),
      );

      await waterRepo.create(
        WaterEntry(
          id: generateId(),
          date: DateTime(2025, 7, 7),
          amountMl: 2500,
          createdAt: monday,
        ),
      );

      final report = await reportService.generateReport(
        weekStart: monday,
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.hasAnyData, true);
      expect(report.workoutsCompleted, 1);
      expect(report.totalVolumeKg, closeTo(500, 0.01));
      expect(report.weightStart, 80.0);
      expect(report.weightEnd, 79.5);
      expect(report.weightChange, closeTo(-0.5, 0.01));
      expect(report.averageCalories, closeTo(2000, 0.01));
      expect(report.averageProtein, closeTo(80, 0.01));
      expect(report.averageWaterMl, closeTo(2500, 0.01));
    });

    test('report shows no fabricated data when nothing exists', () async {
      final report = await reportService.generateReport(
        weekStart: DateTime(2025, 7, 7),
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.hasAnyData, false);
      expect(report.workoutsCompleted, 0);
      expect(report.totalVolumeKg, 0);
      expect(report.weightStart, isNull);
      expect(report.averageCalories, isNull);
      expect(report.averageWaterMl, isNull);
    });

    test('report respects week boundaries', () async {
      await foodRepo.create(
        FoodEntry(
          id: generateId(),
          date: DateTime(2025, 7, 6),
          mealType: 'lunch',
          description: 'Previous week food',
          calories: 9999,
          proteinGrams: 999,
          createdAt: DateTime(2025, 7, 6),
          updatedAt: DateTime(2025, 7, 6),
        ),
      );
      await foodRepo.create(
        FoodEntry(
          id: generateId(),
          date: DateTime(2025, 7, 7),
          mealType: 'lunch',
          description: 'This week food',
          calories: 1800,
          proteinGrams: 70,
          createdAt: DateTime(2025, 7, 7),
          updatedAt: DateTime(2025, 7, 7),
        ),
      );

      final report = await reportService.generateReport(
        weekStart: DateTime(2025, 7, 7),
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.averageCalories, closeTo(1800, 0.01));
    });
  });

  group('reminder service integration', () {
    test('preferences round-trip through save and load', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = ReminderService(prefs, NoOpNotificationScheduler());

      await service.updateAndApply(
        const ReminderPreferences(
          workoutEnabled: true,
          workoutHour: 6,
          workoutMinute: 30,
          weightEnabled: true,
          waterEnabled: true,
          waterIntervalHours: 3,
        ),
      );

      final loaded = service.loadPreferences();
      expect(loaded.workoutEnabled, true);
      expect(loaded.workoutHour, 6);
      expect(loaded.workoutMinute, 30);
      expect(loaded.weightEnabled, true);
      expect(loaded.waterEnabled, true);
      expect(loaded.waterIntervalHours, 3);
    });

    test('app works normally with notifications disabled', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = ReminderService(prefs, NoOpNotificationScheduler());

      expect(service.notificationsAvailable, false);

      await service.updateAndApply(
        const ReminderPreferences(
          workoutEnabled: true,
          weightEnabled: true,
          waterEnabled: true,
        ),
      );

      final loaded = service.loadPreferences();
      expect(loaded.workoutEnabled, true);
      expect(loaded.weightEnabled, true);
      expect(loaded.waterEnabled, true);

      await service.cancelAll();
    });
  });

  group('date edge cases', () {
    test('motivation message stable across timezone-like time changes', () {
      final earlyMorning = DateTime(2025, 7, 10, 0, 0, 1);
      final lateNight = DateTime(2025, 7, 10, 23, 59, 59);
      expect(
        motivation.getMessageForDate(earlyMorning),
        motivation.getMessageForDate(lateNight),
      );
    });

    test('streak handles DST-like gaps (same calendar day)', () async {
      await sessionRepo.create(
        completedSession(completedAt: DateTime(2025, 3, 9, 1, 30)),
      );
      await sessionRepo.create(
        completedSession(completedAt: DateTime(2025, 3, 10, 3, 30)),
      );

      final allSessions = await sessionRepo.getAll();
      final current = streak.getCurrentStreak(
        allSessions,
        DateTime(2025, 3, 10, 12),
      );
      expect(current, 2);
    });

    test('weekly report for week at year boundary', () async {
      await sessionRepo.create(
        completedSession(completedAt: DateTime(2024, 12, 31, 10)),
      );
      await sessionRepo.create(
        completedSession(completedAt: DateTime(2025, 1, 1, 10)),
      );

      final report = await reportService.generateReport(
        weekStart: DateTime(2024, 12, 30),
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.workoutsCompleted, 2);
    });

    test('active week streak spans year boundary', () async {
      final sessions = [
        completedSession(completedAt: DateTime(2025, 1, 2, 10)),
        completedSession(completedAt: DateTime(2024, 12, 26, 10)),
      ];
      for (final s in sessions) {
        await sessionRepo.create(s);
      }

      final allSessions = await sessionRepo.getAll();
      final weekStreak = streak.getActiveWeekStreak(
        allSessions,
        DateTime(2025, 1, 2, 12),
      );
      expect(weekStreak, 2);
    });
  });

  group('no fabricated statistics', () {
    test('empty database produces all-null optional fields', () async {
      final report = await reportService.generateReport(
        weekStart: DateTime(2025, 7, 7),
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.weightStart, isNull);
      expect(report.weightEnd, isNull);
      expect(report.weightChange, isNull);
      expect(report.averageCalories, isNull);
      expect(report.averageProtein, isNull);
      expect(report.averageWaterMl, isNull);
      expect(report.newPersonalRecords, isEmpty);
    });

    test('streak is 0 with no workouts, not fabricated', () async {
      final allSessions = await sessionRepo.getAll();
      expect(streak.getCurrentStreak(allSessions, DateTime(2025, 7, 10)), 0);
      expect(streak.getLongestStreak(allSessions), 0);
      expect(streak.getTotalWorkouts(allSessions), 0);
    });

    test('report only shows sections with real data', () async {
      await sessionRepo.create(
        completedSession(completedAt: DateTime(2025, 7, 8, 10)),
      );

      final report = await reportService.generateReport(
        weekStart: DateTime(2025, 7, 7),
        sessionRepo: sessionRepo,
        setRepo: setRepo,
        weightRepo: weightRepo,
        foodRepo: foodRepo,
        waterRepo: waterRepo,
      );

      expect(report.hasWorkoutData, true);
      expect(report.hasWeightData, false);
      expect(report.hasNutritionData, false);
      expect(report.hasWaterData, false);
    });
  });
}
