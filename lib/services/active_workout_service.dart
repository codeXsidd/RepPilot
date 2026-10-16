import 'package:flutter/foundation.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/overload_recommendation.dart';
import 'package:rep_pilot/models/workout_session.dart';
import 'package:rep_pilot/models/workout_set.dart';
import 'package:rep_pilot/repositories/exercise_repository.dart';
import 'package:rep_pilot/repositories/exercise_settings_repository.dart';
import 'package:rep_pilot/repositories/overload_recommendation_repository.dart';
import 'package:rep_pilot/repositories/routine_exercise_repository.dart';
import 'package:rep_pilot/repositories/routine_repository.dart';
import 'package:rep_pilot/repositories/workout_session_repository.dart';
import 'package:rep_pilot/repositories/workout_set_repository.dart';
import 'package:rep_pilot/services/overload_service.dart';

const _noValue = Object();

class ActiveWorkoutService extends ChangeNotifier {
  WorkoutSession? _currentSession;
  List<WorkoutSet> _sets = [];
  Map<String, List<WorkoutSet>> _previousSets = {};
  List<String> _exerciseOrder = [];
  bool _isSaving = false;
  bool _isFinishing = false;
  String? _lastError;

  WorkoutSession? get currentSession => _currentSession;
  List<WorkoutSet> get sets => List.unmodifiable(_sets);
  Map<String, List<WorkoutSet>> get previousSets =>
      Map.unmodifiable(_previousSets);
  List<String> get exerciseOrder => List.unmodifiable(_exerciseOrder);
  bool get isSaving => _isSaving;
  bool get isFinishing => _isFinishing;
  bool get hasActiveSession => _currentSession != null;
  String? get lastError => _lastError;

  int get completedSetCount =>
      _sets.where((s) => s.completed && !s.isWarmup).length;

  int get totalSetCount => _sets.where((s) => !s.isWarmup).length;

  double get progressPercent =>
      totalSetCount == 0 ? 0 : completedSetCount / totalSetCount;

  Duration get workoutDuration {
    if (_currentSession == null) return Duration.zero;
    final end = _currentSession!.completedAt ?? DateTime.now();
    return end.difference(_currentSession!.startedAt);
  }

  List<WorkoutSet> setsForExercise(String exerciseId) =>
      _sets.where((s) => s.exerciseId == exerciseId).toList()
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

  Future<void> startFromRoutine({
    required String routineId,
    required RoutineRepository routineRepo,
    required RoutineExerciseRepository reRepo,
    required ExerciseRepository exerciseRepo,
    required WorkoutSessionRepository sessionRepo,
    required WorkoutSetRepository setRepo,
    OverloadRecommendationRepository? recRepo,
  }) async {
    _lastError = null;
    try {
      final routine = await routineRepo.getById(routineId);
      if (routine == null) {
        _lastError = 'Routine not found';
        notifyListeners();
        return;
      }

      final routineExercises = await reRepo.getByRoutineId(routineId);
      final now = DateTime.now();

      final accepted = <String, OverloadRecommendation>{};
      if (recRepo != null) {
        for (final re in routineExercises) {
          final latest = await recRepo.getLatestForExercise(re.exerciseId);
          if (latest != null &&
              (latest.status == 'accepted' || latest.status == 'edited')) {
            accepted[re.exerciseId] = latest;
          }
        }
      }

      final session = WorkoutSession(
        id: generateId(),
        routineId: routineId,
        routineName: routine.name,
        startedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final newSets = <WorkoutSet>[];
      final order = <String>[];

      for (final re in routineExercises) {
        final exercise = await exerciseRepo.getById(re.exerciseId);
        final name = exercise?.name ?? '';
        if (!order.contains(re.exerciseId)) {
          order.add(re.exerciseId);
        }

        final rec = accepted[re.exerciseId];
        final weight = rec?.recommendedWeightKg ?? re.targetWeightKg;
        final reps = rec?.recommendedReps ?? re.targetReps;

        for (var i = 1; i <= re.targetSets; i++) {
          newSets.add(
            WorkoutSet(
              id: generateId(),
              sessionId: session.id,
              exerciseId: re.exerciseId,
              exerciseName: name,
              setNumber: i,
              weightKg: weight,
              reps: reps,
            ),
          );
        }
      }

      await sessionRepo.createWithSets(session, newSets);

      _currentSession = session;
      _sets = newSets;
      _exerciseOrder = order;
      _lastRecommendations = [];
      notifyListeners();

      await loadPreviousPerformance(setRepo: setRepo);
    } catch (e) {
      _lastError = 'Failed to start workout: $e';
      notifyListeners();
    }
  }

  Future<void> startStandalone({
    required String name,
    required WorkoutSessionRepository sessionRepo,
  }) async {
    _lastError = null;
    try {
      final now = DateTime.now();
      final session = WorkoutSession(
        id: generateId(),
        routineName: name,
        startedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      await sessionRepo.create(session);

      _currentSession = session;
      _sets = [];
      _exerciseOrder = [];
      _previousSets = {};
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to start workout: $e';
      notifyListeners();
    }
  }

  Future<bool> resumeSession({
    required WorkoutSessionRepository sessionRepo,
    required WorkoutSetRepository setRepo,
  }) async {
    _lastError = null;
    try {
      final session = await sessionRepo.getActiveSession();
      if (session == null) return false;

      final sets = await setRepo.getBySessionId(session.id);

      final order = <String>[];
      for (final s in sets) {
        if (!order.contains(s.exerciseId)) {
          order.add(s.exerciseId);
        }
      }

      _currentSession = session;
      _sets = sets;
      _exerciseOrder = order;
      notifyListeners();

      await loadPreviousPerformance(setRepo: setRepo);
      return true;
    } catch (e) {
      _lastError = 'Failed to resume workout: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> addExerciseSets({
    required String exerciseId,
    required String exerciseName,
    required int count,
    double? weightKg,
    required WorkoutSetRepository setRepo,
  }) async {
    if (_currentSession == null) return;
    _lastError = null;
    try {
      _isSaving = true;
      notifyListeners();

      if (!_exerciseOrder.contains(exerciseId)) {
        _exerciseOrder.add(exerciseId);
      }

      final existingCount = _sets
          .where((s) => s.exerciseId == exerciseId)
          .length;

      for (var i = 1; i <= count; i++) {
        final set = WorkoutSet(
          id: generateId(),
          sessionId: _currentSession!.id,
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          setNumber: existingCount + i,
          weightKg: weightKg,
        );
        await setRepo.create(set);
        _sets.add(set);
      }

      _isSaving = false;
      notifyListeners();
    } catch (e) {
      _isSaving = false;
      _lastError = 'Failed to add sets: $e';
      notifyListeners();
    }
  }

  Future<void> updateSet({
    required String setId,
    Object? reps = _noValue,
    Object? weightKg = _noValue,
    Object? rpe = _noValue,
    Object? isWarmup = _noValue,
    Object? notes = _noValue,
    required WorkoutSetRepository setRepo,
  }) async {
    _lastError = null;
    try {
      final index = _sets.indexWhere((s) => s.id == setId);
      if (index == -1) return;

      final current = _sets[index];
      final updated = WorkoutSet(
        id: current.id,
        sessionId: current.sessionId,
        exerciseId: current.exerciseId,
        exerciseName: current.exerciseName,
        setNumber: current.setNumber,
        reps: identical(reps, _noValue) ? current.reps : reps as int?,
        weightKg: identical(weightKg, _noValue)
            ? current.weightKg
            : weightKg as double?,
        completed: current.completed,
        rpe: identical(rpe, _noValue) ? current.rpe : rpe as double?,
        notes: identical(notes, _noValue)
            ? current.notes
            : notes as String? ?? current.notes,
        completedAt: current.completedAt,
        isWarmup: identical(isWarmup, _noValue)
            ? current.isWarmup
            : isWarmup as bool? ?? current.isWarmup,
      );

      await setRepo.update(updated);
      _sets[index] = updated;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to update set: $e';
      notifyListeners();
    }
  }

  Future<void> completeSet({
    required String setId,
    required WorkoutSetRepository setRepo,
  }) async {
    _lastError = null;
    try {
      final index = _sets.indexWhere((s) => s.id == setId);
      if (index == -1) return;

      final now = DateTime.now();
      final updated = _sets[index].copyWith(completed: true, completedAt: now);

      await setRepo.update(updated);
      _sets[index] = updated;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to complete set: $e';
      notifyListeners();
    }
  }

  Future<void> uncompleteSet({
    required String setId,
    required WorkoutSetRepository setRepo,
  }) async {
    _lastError = null;
    try {
      final index = _sets.indexWhere((s) => s.id == setId);
      if (index == -1) return;

      final updated = _sets[index].copyWith(
        completed: false,
        completedAt: null,
      );

      await setRepo.update(updated);
      _sets[index] = updated;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to undo set: $e';
      notifyListeners();
    }
  }

  Future<void> removeSet({
    required String setId,
    required WorkoutSetRepository setRepo,
  }) async {
    _lastError = null;
    try {
      final index = _sets.indexWhere((s) => s.id == setId);
      if (index == -1) return;

      final removed = _sets[index];
      await setRepo.delete(setId);
      _sets.removeAt(index);

      var num = 1;
      for (var i = 0; i < _sets.length; i++) {
        if (_sets[i].exerciseId == removed.exerciseId) {
          if (_sets[i].setNumber != num) {
            final renumbered = _sets[i].copyWith(setNumber: num);
            await setRepo.update(renumbered);
            _sets[i] = renumbered;
          }
          num++;
        }
      }

      if (!_sets.any((s) => s.exerciseId == removed.exerciseId)) {
        _exerciseOrder.remove(removed.exerciseId);
      }

      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to remove set: $e';
      notifyListeners();
    }
  }

  Future<void> addSet({
    required String exerciseId,
    required WorkoutSetRepository setRepo,
  }) async {
    if (_currentSession == null) return;
    _lastError = null;
    try {
      final exerciseSets = setsForExercise(exerciseId);
      final lastSet = exerciseSets.isNotEmpty ? exerciseSets.last : null;
      final nextNumber = exerciseSets.isEmpty
          ? 1
          : exerciseSets.last.setNumber + 1;

      final set = WorkoutSet(
        id: generateId(),
        sessionId: _currentSession!.id,
        exerciseId: exerciseId,
        exerciseName: lastSet?.exerciseName ?? '',
        setNumber: nextNumber,
        weightKg: lastSet?.weightKg,
        reps: lastSet?.reps,
      );

      await setRepo.create(set);
      _sets.add(set);
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to add set: $e';
      notifyListeners();
    }
  }

  Future<void> skipSet({
    required String setId,
    required WorkoutSetRepository setRepo,
  }) async {
    _lastError = null;
    try {
      final index = _sets.indexWhere((s) => s.id == setId);
      if (index == -1) return;

      final updated = _sets[index].copyWith(
        completed: true,
        reps: 0,
        completedAt: DateTime.now(),
        notes: 'Skipped',
      );

      await setRepo.update(updated);
      _sets[index] = updated;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to skip set: $e';
      notifyListeners();
    }
  }

  void reorderExercises(List<String> newOrder) {
    _exerciseOrder = List.of(newOrder);
    notifyListeners();
  }

  List<OverloadRecommendation> _lastRecommendations = [];
  List<OverloadRecommendation> get lastRecommendations =>
      List.unmodifiable(_lastRecommendations);

  Future<WorkoutSession?> finishWorkout({
    required WorkoutSessionRepository sessionRepo,
    OverloadService? overloadService,
    ExerciseSettingsRepository? settingsRepo,
    WorkoutSetRepository? setRepo,
    OverloadRecommendationRepository? recRepo,
    ExerciseRepository? exerciseRepo,
  }) async {
    if (_currentSession == null || _isFinishing) return null;
    _lastError = null;
    _isFinishing = true;
    notifyListeners();

    try {
      final sessionId = _currentSession!.id;
      final finishedSets = List<WorkoutSet>.from(_sets);
      final now = DateTime.now();
      await sessionRepo.complete(sessionId, completedAt: now);

      _lastRecommendations = [];
      if (overloadService != null &&
          settingsRepo != null &&
          setRepo != null &&
          recRepo != null) {
        _lastRecommendations = await overloadService.generateForSession(
          sessionId: sessionId,
          sessionSets: finishedSets,
          settingsRepo: settingsRepo,
          setRepo: setRepo,
          recRepo: recRepo,
        );
      }

      if (exerciseRepo != null) {
        final usedIds = finishedSets.map((s) => s.exerciseId).toSet();
        for (final id in usedIds) {
          await exerciseRepo.updateLastUsed(id);
        }
      }

      final completed = _currentSession!.copyWith(completedAt: now);
      _currentSession = null;
      _isFinishing = false;
      _sets = [];
      _exerciseOrder = [];
      _previousSets = {};
      notifyListeners();

      return completed;
    } catch (e) {
      _isFinishing = false;
      _lastError = 'Failed to finish workout: $e';
      notifyListeners();
      return null;
    }
  }

  List<WorkoutSet> get completedSets => List.unmodifiable(_sets);

  Future<void> cancelWorkout({
    required WorkoutSessionRepository sessionRepo,
    required WorkoutSetRepository setRepo,
  }) async {
    if (_currentSession == null) return;
    _lastError = null;
    try {
      await setRepo.deleteBySessionId(_currentSession!.id);
      await sessionRepo.delete(_currentSession!.id);
      clearState();
    } catch (e) {
      _lastError = 'Failed to cancel workout: $e';
      notifyListeners();
    }
  }

  void clearState() {
    _currentSession = null;
    _sets = [];
    _exerciseOrder = [];
    _previousSets = {};
    _isSaving = false;
    _isFinishing = false;
    _lastError = null;
    notifyListeners();
  }

  Future<void> loadPreviousPerformance({
    required WorkoutSetRepository setRepo,
  }) async {
    final newPrev = <String, List<WorkoutSet>>{};
    for (final exerciseId in _exerciseOrder) {
      try {
        final prev = await setRepo.getByExerciseId(exerciseId, limit: 10);
        if (prev.isNotEmpty) {
          newPrev[exerciseId] = prev;
        }
      } catch (_) {
        // Non-critical; previous performance is optional
      }
    }
    _previousSets = newPrev;
    notifyListeners();
  }
}
