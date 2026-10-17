import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rep_pilot/app.dart';
import 'package:rep_pilot/core/database/database_helper.dart';
import 'package:rep_pilot/core/data/default_exercises.dart';
import 'package:rep_pilot/core/data/default_foods.dart';
import 'package:rep_pilot/repositories/exercise_repository.dart';
import 'package:rep_pilot/repositories/food_repository.dart';
import 'package:rep_pilot/services/reminder_service.dart';
import 'package:rep_pilot/services/training_level_service.dart';
import 'package:rep_pilot/theme/theme_controller.dart';

Future<Widget> buildTestApp() async {
  final database = await DatabaseHelper.instance.database;

  final exerciseRepo = ExerciseRepository(database);
  await exerciseRepo.seedDefaults(buildDefaultExercises());

  final foodRepo = FoodRepository(database);
  await foodRepo.seedDefaults(buildDefaultFoods());

  final themeController = await ThemeController.create();

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_complete', true);

  final scheduler = NoOpNotificationScheduler();
  final reminderService = ReminderService(prefs, scheduler);
  final trainingLevelService = TrainingLevelService.withPrefs(prefs);

  return RepPilotApp(
    database: database,
    themeController: themeController,
    reminderService: reminderService,
    trainingLevelService: trainingLevelService,
    showOnboarding: false,
  );
}

Finder findNavLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App startup and navigation', () {
    testWidgets('app launches and shows home screen', (tester) async {
      final app = await buildTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('RepPilot'), findsOneWidget);
    });

    testWidgets('navigate to workout tab and back', (tester) async {
      final app = await buildTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(findNavLabel('Workout'));
      await tester.pumpAndSettle();
      expect(find.text('Workouts'), findsOneWidget);

      await tester.tap(findNavLabel('Home'));
      await tester.pumpAndSettle();
      expect(find.text('RepPilot'), findsOneWidget);
    });

    testWidgets('navigate to weekly workouts screen', (tester) async {
      final app = await buildTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(findNavLabel('Workout'));
      await tester.pumpAndSettle();

      final calendarBtn = find.byIcon(Icons.calendar_month_rounded);
      expect(calendarBtn, findsOneWidget);
      await tester.tap(calendarBtn);
      await tester.pumpAndSettle();

      expect(find.text('My Weekly Workouts'), findsOneWidget);
      expect(find.text('Weekly Progress'), findsOneWidget);

      for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
        expect(find.text(day), findsWidgets);
      }

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Workouts'), findsOneWidget);
    });

    testWidgets('navigate all five tabs', (tester) async {
      final app = await buildTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('RepPilot'), findsOneWidget);

      await tester.tap(findNavLabel('Workout'));
      await tester.pumpAndSettle();
      expect(find.text('Workouts'), findsOneWidget);

      await tester.tap(findNavLabel('Diet'));
      await tester.pumpAndSettle();

      await tester.tap(findNavLabel('Progress'));
      await tester.pumpAndSettle();

      await tester.tap(findNavLabel('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsAtLeastNWidgets(1));

      await tester.tap(findNavLabel('Home'));
      await tester.pumpAndSettle();
      expect(find.text('RepPilot'), findsOneWidget);
    });
  });

  group('Home dashboard', () {
    testWidgets('shows rest day or planned workout card', (tester) async {
      final app = await buildTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final restDay = find.text('Rest Day');
      final weekBtn = find.text('Week');
      expect(
        restDay.evaluate().isNotEmpty || weekBtn.evaluate().isNotEmpty,
        true,
      );
    });

    testWidgets('week button navigates to weekly workouts', (tester) async {
      final app = await buildTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final weekBtn = find.text('Week');
      if (weekBtn.evaluate().isNotEmpty) {
        await tester.tap(weekBtn.first);
        await tester.pumpAndSettle();
        expect(find.text('My Weekly Workouts'), findsOneWidget);
      }
    });
  });

  group('Weekly workouts screen', () {
    testWidgets('shows all 7 days with rest day cards', (tester) async {
      final app = await buildTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(findNavLabel('Workout'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Rest Day'), findsWidgets);
    });

    testWidgets('week navigation works', (tester) async {
      final app = await buildTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(findNavLabel('Workout'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Tap for this week'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
    });
  });
}
