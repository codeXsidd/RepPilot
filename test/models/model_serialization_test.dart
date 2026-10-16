import 'package:flutter_test/flutter_test.dart';

import 'package:rep_pilot/models/body_weight_entry.dart';
import 'package:rep_pilot/models/exercise.dart';
import 'package:rep_pilot/models/food_entry.dart';
import 'package:rep_pilot/models/personal_goal.dart';
import 'package:rep_pilot/models/routine.dart';
import 'package:rep_pilot/models/routine_exercise.dart';
import 'package:rep_pilot/models/user_profile.dart';
import 'package:rep_pilot/models/water_entry.dart';
import 'package:rep_pilot/models/workout_session.dart';
import 'package:rep_pilot/models/workout_set.dart';

void main() {
  final now = DateTime(2025, 6, 15, 10, 30);

  group('Exercise serialization', () {
    test('round-trips through toMap/fromMap', () {
      final e = Exercise(
        id: 'ex-1',
        name: 'Squat',
        category: 'legs',
        muscleGroup: 'Quadriceps',
        equipment: 'barbell',
        notes: 'Keep back straight',
        isCustom: true,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      );
      final restored = Exercise.fromMap(e.toMap());
      expect(restored.id, e.id);
      expect(restored.name, e.name);
      expect(restored.category, e.category);
      expect(restored.muscleGroup, e.muscleGroup);
      expect(restored.equipment, e.equipment);
      expect(restored.notes, e.notes);
      expect(restored.isCustom, e.isCustom);
      expect(restored.isArchived, e.isArchived);
    });

    test('copyWith preserves unchanged fields', () {
      final e = Exercise(
        id: 'ex-1',
        name: 'Squat',
        equipment: 'barbell',
        createdAt: now,
        updatedAt: now,
      );
      final copied = e.copyWith(name: 'Front Squat');
      expect(copied.id, 'ex-1');
      expect(copied.name, 'Front Squat');
      expect(copied.category, 'other');
      expect(copied.equipment, 'barbell');
    });

    test('copyWith updates equipment', () {
      final e = Exercise(
        id: 'ex-1',
        name: 'Curl',
        equipment: 'barbell',
        createdAt: now,
        updatedAt: now,
      );
      final copied = e.copyWith(equipment: 'dumbbell');
      expect(copied.equipment, 'dumbbell');
    });

    test('equality works on matching fields', () {
      final a = Exercise(
        id: 'x',
        name: 'A',
        equipment: 'barbell',
        createdAt: now,
        updatedAt: now,
      );
      final b = Exercise(
        id: 'x',
        name: 'A',
        equipment: 'barbell',
        createdAt: now,
        updatedAt: now,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('equipment defaults to empty string', () {
      final e = Exercise(
        id: 'ex-1',
        name: 'Plank',
        createdAt: now,
        updatedAt: now,
      );
      expect(e.equipment, '');
      final map = e.toMap();
      expect(map['equipment'], '');
    });

    test('fromMap handles missing equipment gracefully', () {
      final map = {
        'id': 'ex-1',
        'name': 'Old Exercise',
        'category': 'chest',
        'muscle_group': 'Pectorals',
        'notes': '',
        'is_custom': 1,
        'is_archived': 0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      final e = Exercise.fromMap(map);
      expect(e.equipment, '');
    });
  });

  group('Routine serialization', () {
    test('round-trips with nullable dayOfWeek', () {
      final r = Routine(
        id: 'r-1',
        name: 'Push Day',
        dayOfWeek: 1,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      );
      final restored = Routine.fromMap(r.toMap());
      expect(restored.dayOfWeek, 1);
      expect(restored.name, 'Push Day');

      final unscheduled = Routine(
        id: 'r-2',
        name: 'Flex',
        createdAt: now,
        updatedAt: now,
      );
      final restoredNull = Routine.fromMap(unscheduled.toMap());
      expect(restoredNull.dayOfWeek, isNull);
    });
  });

  group('RoutineExercise serialization', () {
    test('round-trips with nullable targetWeightKg', () {
      final re = RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'ex-1',
        targetSets: 4,
        targetReps: 8,
        targetWeightKg: 60.0,
        restSeconds: 90,
        createdAt: now,
        updatedAt: now,
      );
      final restored = RoutineExercise.fromMap(re.toMap());
      expect(restored.targetWeightKg, 60.0);
      expect(restored.targetSets, 4);

      final noWeight = RoutineExercise(
        id: 're-2',
        routineId: 'r-1',
        exerciseId: 'ex-1',
        createdAt: now,
        updatedAt: now,
      );
      final restoredNull = RoutineExercise.fromMap(noWeight.toMap());
      expect(restoredNull.targetWeightKg, isNull);
    });

    test('round-trips with rep range', () {
      final re = RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'ex-1',
        targetSets: 3,
        targetReps: 10,
        targetRepsMin: 8,
        targetRepsMax: 12,
        createdAt: now,
        updatedAt: now,
      );
      final restored = RoutineExercise.fromMap(re.toMap());
      expect(restored.targetRepsMin, 8);
      expect(restored.targetRepsMax, 12);
    });

    test('repsDisplay shows range when min and max set', () {
      final re = RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'ex-1',
        targetRepsMin: 8,
        targetRepsMax: 12,
        createdAt: now,
        updatedAt: now,
      );
      expect(re.repsDisplay, '8-12');
    });

    test('repsDisplay shows single when min equals max', () {
      final re = RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'ex-1',
        targetRepsMin: 10,
        targetRepsMax: 10,
        createdAt: now,
        updatedAt: now,
      );
      expect(re.repsDisplay, '10');
    });

    test('repsDisplay falls back to targetReps when no range', () {
      final re = RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'ex-1',
        targetReps: 15,
        createdAt: now,
        updatedAt: now,
      );
      expect(re.repsDisplay, '15');
    });

    test('nullable rep range fields default to null', () {
      final re = RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'ex-1',
        createdAt: now,
        updatedAt: now,
      );
      expect(re.targetRepsMin, isNull);
      expect(re.targetRepsMax, isNull);
    });

    test('fromMap handles missing rep range columns', () {
      final map = {
        'id': 're-1',
        'routine_id': 'r-1',
        'exercise_id': 'ex-1',
        'target_sets': 3,
        'target_reps': 10,
        'rest_seconds': 60,
        'sort_order': 0,
        'notes': '',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      final re = RoutineExercise.fromMap(map);
      expect(re.targetRepsMin, isNull);
      expect(re.targetRepsMax, isNull);
    });
  });

  group('WorkoutSession serialization', () {
    test('round-trips active session (no completedAt)', () {
      final s = WorkoutSession(
        id: 's-1',
        routineId: 'r-1',
        routineName: 'Push Day',
        startedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      expect(s.isActive, true);
      expect(s.duration, isNull);

      final restored = WorkoutSession.fromMap(s.toMap());
      expect(restored.completedAt, isNull);
      expect(restored.routineName, 'Push Day');
    });

    test('round-trips completed session', () {
      final end = now.add(const Duration(hours: 1));
      final s = WorkoutSession(
        id: 's-2',
        routineId: 'r-1',
        routineName: 'Leg Day',
        startedAt: now,
        completedAt: end,
        createdAt: now,
        updatedAt: now,
      );
      expect(s.isActive, false);
      expect(s.duration, const Duration(hours: 1));

      final restored = WorkoutSession.fromMap(s.toMap());
      expect(restored.completedAt, isNotNull);
    });
  });

  group('WorkoutSet serialization', () {
    test('round-trips with nullable fields', () {
      final ws = WorkoutSet(
        id: 'ws-1',
        sessionId: 's-1',
        exerciseId: 'ex-1',
        exerciseName: 'Squat',
        setNumber: 1,
        reps: 10,
        weightKg: 80.0,
        completed: true,
        rpe: 8.5,
        completedAt: now,
      );
      final restored = WorkoutSet.fromMap(ws.toMap());
      expect(restored.reps, 10);
      expect(restored.weightKg, 80.0);
      expect(restored.completed, true);
      expect(restored.rpe, 8.5);
      expect(restored.exerciseName, 'Squat');
    });

    test('handles all-null optional fields', () {
      final ws = WorkoutSet(
        id: 'ws-2',
        sessionId: 's-1',
        exerciseId: 'ex-1',
        setNumber: 1,
      );
      final restored = WorkoutSet.fromMap(ws.toMap());
      expect(restored.reps, isNull);
      expect(restored.weightKg, isNull);
      expect(restored.rpe, isNull);
      expect(restored.completedAt, isNull);
      expect(restored.completed, false);
    });
  });

  group('BodyWeightEntry serialization', () {
    test('stores date as YYYY-MM-DD', () {
      final bw = BodyWeightEntry(
        id: 'bw-1',
        date: DateTime(2025, 6, 15),
        weightKg: 75.5,
        createdAt: now,
        updatedAt: now,
      );
      final map = bw.toMap();
      expect(map['date'], '2025-06-15');
      final restored = BodyWeightEntry.fromMap(map);
      expect(restored.weightKg, 75.5);
    });
  });

  group('FoodEntry serialization', () {
    test('round-trips with all macros', () {
      final fe = FoodEntry(
        id: 'fe-1',
        date: DateTime(2025, 6, 15),
        mealType: 'lunch',
        description: 'Chicken salad',
        calories: 450.0,
        proteinGrams: 35.0,
        carbsGrams: 20.0,
        fatGrams: 15.0,
        createdAt: now,
        updatedAt: now,
      );
      final restored = FoodEntry.fromMap(fe.toMap());
      expect(restored.mealType, 'lunch');
      expect(restored.calories, 450.0);
      expect(restored.proteinGrams, 35.0);
    });
  });

  group('WaterEntry serialization', () {
    test('round-trips correctly', () {
      final we = WaterEntry(
        id: 'we-1',
        date: DateTime(2025, 6, 15),
        amountMl: 250,
        createdAt: now,
      );
      final restored = WaterEntry.fromMap(we.toMap());
      expect(restored.amountMl, 250);
      expect(restored.id, 'we-1');
    });
  });

  group('UserProfile serialization', () {
    test('round-trips with defaults', () {
      final p = UserProfile(id: 'p-1', createdAt: now, updatedAt: now);
      final restored = UserProfile.fromMap(p.toMap());
      expect(restored.weightUnit, 'kg');
      expect(restored.themeMode, 'system');
      expect(restored.heightCm, isNull);
    });

    test('round-trips with all fields', () {
      final p = UserProfile(
        id: 'p-1',
        displayName: 'Test User',
        weightUnit: 'lb',
        themeMode: 'dark',
        heightCm: 180.0,
        dateOfBirth: DateTime(1990, 1, 15),
        createdAt: now,
        updatedAt: now,
      );
      final restored = UserProfile.fromMap(p.toMap());
      expect(restored.displayName, 'Test User');
      expect(restored.weightUnit, 'lb');
      expect(restored.heightCm, 180.0);
    });
  });

  group('PersonalGoal serialization', () {
    test('round-trips active goal', () {
      final g = PersonalGoal(
        id: 'g-1',
        goalType: 'target_weight',
        targetValue: 75.0,
        unit: 'kg',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      final restored = PersonalGoal.fromMap(g.toMap());
      expect(restored.goalType, 'target_weight');
      expect(restored.targetValue, 75.0);
      expect(restored.isActive, true);
      expect(restored.startDate, isNull);
    });
  });
}
