import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import 'navigation/main_shell.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'repositories/body_measurement_repository.dart';
import 'repositories/body_weight_repository.dart';
import 'repositories/exercise_repository.dart';
import 'repositories/exercise_settings_repository.dart';
import 'repositories/food_entry_repository.dart';
import 'repositories/food_repository.dart';
import 'repositories/meal_template_item_repository.dart';
import 'repositories/meal_template_repository.dart';
import 'repositories/overload_recommendation_repository.dart';
import 'repositories/personal_goal_repository.dart';
import 'repositories/routine_exercise_repository.dart';
import 'repositories/routine_repository.dart';
import 'repositories/user_profile_repository.dart';
import 'repositories/water_entry_repository.dart';
import 'repositories/workout_session_repository.dart';
import 'repositories/workout_set_repository.dart';
import 'services/active_workout_service.dart';
import 'services/backup_service.dart';
import 'services/motivation_service.dart';
import 'services/overload_service.dart';
import 'services/reminder_service.dart';
import 'services/training_level_service.dart';
import 'services/streak_service.dart';
import 'services/weekly_report_service.dart';
import 'services/weight_analytics_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class RepPilotApp extends StatelessWidget {
  final Database database;
  final ThemeController themeController;
  final ReminderService reminderService;
  final TrainingLevelService trainingLevelService;
  final bool showOnboarding;

  const RepPilotApp({
    super.key,
    required this.database,
    required this.themeController,
    required this.reminderService,
    required this.trainingLevelService,
    this.showOnboarding = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: trainingLevelService),
        ChangeNotifierProvider(create: (_) => ActiveWorkoutService()),
        Provider(create: (_) => UserProfileRepository(database)),
        Provider(create: (_) => ExerciseRepository(database)),
        Provider(create: (_) => RoutineRepository(database)),
        Provider(create: (_) => RoutineExerciseRepository(database)),
        Provider(create: (_) => WorkoutSessionRepository(database)),
        Provider(create: (_) => WorkoutSetRepository(database)),
        Provider(create: (_) => BodyWeightRepository(database)),
        Provider(create: (_) => BodyMeasurementRepository(database)),
        Provider(create: (_) => FoodEntryRepository(database)),
        Provider(create: (_) => WaterEntryRepository(database)),
        Provider(create: (_) => PersonalGoalRepository(database)),
        Provider(create: (_) => ExerciseSettingsRepository(database)),
        Provider(create: (_) => OverloadRecommendationRepository(database)),
        Provider(create: (_) => OverloadService()),
        Provider(create: (_) => WeightAnalyticsService()),
        Provider(create: (_) => const MotivationService()),
        Provider(create: (_) => const StreakService()),
        Provider(create: (_) => WeeklyReportService(const StreakService())),
        Provider.value(value: reminderService),
        Provider(create: (_) => FoodRepository(database)),
        Provider(create: (_) => MealTemplateRepository(database)),
        Provider(create: (_) => MealTemplateItemRepository(database)),
        Provider(create: (_) => BackupService(database)),
      ],
      child: Consumer<ThemeController>(
        builder: (context, ctrl, _) {
          return MaterialApp(
            title: 'RepPilot',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ctrl.themeMode,
            home: showOnboarding ? const WelcomeScreen() : const MainShell(),
          );
        },
      ),
    );
  }
}
