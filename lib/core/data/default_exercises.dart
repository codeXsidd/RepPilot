import '../../models/exercise.dart';
import 'exercise_catalog.dart';

const List<String> exerciseCategories = [
  'chest',
  'back',
  'shoulders',
  'biceps',
  'triceps',
  'legs',
  'glutes',
  'calves',
  'core',
  'full_body',
  'forearms',
  'mobility',
];

const List<String> equipmentTypes = [
  'barbell',
  'bodyweight',
  'cable',
  'dumbbell',
  'ez_bar',
  'kettlebell',
  'machine',
  'resistance_band',
  'medicine_ball',
  'other',
];

const List<String> difficultyLevels = ['beginner', 'intermediate', 'advanced'];

const List<String> movementPatterns = [
  'push',
  'pull',
  'squat',
  'hinge',
  'lunge',
  'carry',
  'rotation',
  'isolation',
  'isometric',
  'compound',
];

List<Exercise> buildDefaultExercises() => buildExerciseCatalog();
