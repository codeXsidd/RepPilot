import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/data/default_exercises.dart';
import 'core/data/default_foods.dart';
import 'repositories/exercise_repository.dart';
import 'repositories/food_repository.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'services/reminder_service.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await DatabaseHelper.instance.database;

  final exerciseRepo = ExerciseRepository(database);
  await exerciseRepo.seedDefaults(buildDefaultExercises());

  final foodRepo = FoodRepository(database);
  await foodRepo.seedDefaults(buildDefaultFoods());

  final themeController = await ThemeController.create();

  final prefs = await SharedPreferences.getInstance();
  final scheduler = NoOpNotificationScheduler();
  final reminderService = ReminderService(prefs, scheduler);

  final showOnboarding = !await WelcomeScreen.isOnboardingComplete();

  runApp(
    RepPilotApp(
      database: database,
      themeController: themeController,
      reminderService: reminderService,
      showOnboarding: showOnboarding,
    ),
  );
}
