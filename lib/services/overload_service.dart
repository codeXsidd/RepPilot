import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/exercise_settings.dart';
import 'package:rep_pilot/models/overload_recommendation.dart';
import 'package:rep_pilot/models/workout_set.dart';
import 'package:rep_pilot/repositories/exercise_settings_repository.dart';
import 'package:rep_pilot/repositories/overload_recommendation_repository.dart';
import 'package:rep_pilot/repositories/workout_set_repository.dart';

class OverloadService {
  static const double highEffortThreshold = 9.0;
  static const int minimumSetsForSuggestion = 1;

  OverloadRecommendation? generateRecommendation({
    required String exerciseId,
    required ExerciseSettings settings,
    required List<WorkoutSet> recentSets,
    String? sessionId,
  }) {
    final workingSets = recentSets
        .where((s) => !s.isWarmup && s.reps != null && s.reps != 0)
        .toList();

    if (workingSets.isEmpty) return null;

    final latestSessionId = workingSets.first.sessionId;
    final latestSets = workingSets
        .where((s) => s.sessionId == latestSessionId)
        .toList();

    if (latestSets.length < minimumSetsForSuggestion) return null;

    final incompleteSets = latestSets.where((s) => !s.completed).toList();
    if (incompleteSets.isNotEmpty) {
      final weightStr = _formatWeight(_dominantWeight(latestSets));
      return _buildRecommendation(
        exerciseId: exerciseId,
        sessionId: sessionId,
        previousWeight: _dominantWeight(latestSets),
        previousReps: _averageReps(latestSets),
        recommendedWeight: _dominantWeight(latestSets),
        recommendedReps: _averageReps(latestSets),
        reasoning:
            '${incompleteSets.length} of ${latestSets.length} sets were not '
            'completed at $weightStr. Maintain current load and focus on '
            'completing all prescribed sets before increasing.',
      );
    }

    final completedSets = latestSets.where((s) => s.completed).toList();
    final rpeValues = completedSets
        .where((s) => s.rpe != null)
        .map((s) => s.rpe!)
        .toList();
    if (rpeValues.isNotEmpty) {
      final avgRpe = rpeValues.reduce((a, b) => a + b) / rpeValues.length;
      if (avgRpe >= highEffortThreshold) {
        final weightStr = _formatWeight(_dominantWeight(completedSets));
        return _buildRecommendation(
          exerciseId: exerciseId,
          sessionId: sessionId,
          previousWeight: _dominantWeight(completedSets),
          previousReps: _averageReps(completedSets),
          recommendedWeight: _dominantWeight(completedSets),
          recommendedReps: _averageReps(completedSets),
          reasoning:
              'Average effort was very high (RPE ${avgRpe.toStringAsFixed(1)}) '
              'at $weightStr. Maintain current load until it feels more '
              'manageable before adding weight.',
        );
      }
    }

    final currentWeight = _dominantWeight(completedSets);
    final avgReps = _averageReps(completedSets);

    if (settings.isBodyweight) {
      if (avgReps != null && avgReps >= settings.maxReps) {
        final target = avgReps + 1;
        return _buildRecommendation(
          exerciseId: exerciseId,
          sessionId: sessionId,
          previousWeight: null,
          previousReps: avgReps,
          recommendedWeight: null,
          recommendedReps: target,
          reasoning:
              'Bodyweight exercise: all ${completedSets.length} sets reached '
              '$avgReps reps (target: ${settings.maxReps}). '
              'Increase target to $target reps next session.',
        );
      }
      return _buildRecommendation(
        exerciseId: exerciseId,
        sessionId: sessionId,
        previousWeight: null,
        previousReps: avgReps,
        recommendedWeight: null,
        recommendedReps: avgReps != null
            ? (avgReps < settings.maxReps ? avgReps + 1 : avgReps)
            : settings.minReps,
        reasoning:
            'Bodyweight exercise: averaged $avgReps reps across '
            '${completedSets.length} sets. Continue building toward '
            '${settings.maxReps} reps per set.',
      );
    }

    final allMetTarget =
        completedSets.isNotEmpty &&
        completedSets.every(
          (s) => s.reps != null && s.reps! >= settings.maxReps,
        );

    if (allMetTarget && currentWeight != null) {
      final increment = settings.effectiveIncrement;
      final newWeight = currentWeight + increment;
      final weightStr = _formatWeight(currentWeight);
      final newWeightStr = _formatWeight(newWeight);
      final incrementStr = _formatWeight(increment);
      return _buildRecommendation(
        exerciseId: exerciseId,
        sessionId: sessionId,
        previousWeight: currentWeight,
        previousReps: avgReps,
        recommendedWeight: newWeight,
        recommendedReps: settings.minReps,
        reasoning:
            'All ${completedSets.length} sets hit ${settings.maxReps}+ reps '
            'at $weightStr. Increase by $incrementStr to $newWeightStr and '
            'aim for ${settings.minReps} reps.',
      );
    }

    if (avgReps != null && currentWeight != null) {
      final target = avgReps + 1 > settings.maxReps
          ? settings.maxReps
          : avgReps + 1;
      final weightStr = _formatWeight(currentWeight);
      return _buildRecommendation(
        exerciseId: exerciseId,
        sessionId: sessionId,
        previousWeight: currentWeight,
        previousReps: avgReps,
        recommendedWeight: currentWeight,
        recommendedReps: target,
        reasoning:
            'Averaged $avgReps reps at $weightStr (target: '
            '${settings.maxReps}). Maintain weight and build to '
            '${settings.maxReps} reps across all sets.',
      );
    }

    return null;
  }

  Future<List<OverloadRecommendation>> generateForSession({
    required String sessionId,
    required List<WorkoutSet> sessionSets,
    required ExerciseSettingsRepository settingsRepo,
    required WorkoutSetRepository setRepo,
    required OverloadRecommendationRepository recRepo,
  }) async {
    final exerciseIds = <String>{};
    for (final s in sessionSets) {
      if (!s.isWarmup) exerciseIds.add(s.exerciseId);
    }

    final recommendations = <OverloadRecommendation>[];

    for (final exerciseId in exerciseIds) {
      final settings = await settingsRepo.getOrCreateForExercise(exerciseId);

      final currentSessionSets = sessionSets
          .where((s) => s.exerciseId == exerciseId)
          .toList();

      if (!shouldSuggest(recentSets: currentSessionSets)) continue;

      final rec = generateRecommendation(
        exerciseId: exerciseId,
        settings: settings,
        recentSets: currentSessionSets,
        sessionId: sessionId,
      );

      if (rec != null) {
        await recRepo.create(rec);
        recommendations.add(rec);
      }
    }

    return recommendations;
  }

  String explainRecommendation(OverloadRecommendation rec, String weightUnit) {
    var text = rec.reasoning;
    if (weightUnit == 'lb' && rec.recommendedWeightKg != null) {
      final lbWeight = displayWeight(rec.recommendedWeightKg!, 'lb');
      text += ' (${lbWeight.toStringAsFixed(1)} lb)';
    }
    return text;
  }

  bool shouldSuggest({required List<WorkoutSet> recentSets}) {
    final working = recentSets
        .where((s) => !s.isWarmup && s.reps != 0)
        .toList();
    return working.length >= minimumSetsForSuggestion;
  }

  Future<void> applyRecommendation(
    OverloadRecommendation rec,
    OverloadRecommendationRepository repo,
  ) async {
    await repo.updateStatus(rec.id, 'accepted');
  }

  Future<void> dismissRecommendation(
    OverloadRecommendation rec,
    OverloadRecommendationRepository repo,
  ) async {
    await repo.updateStatus(rec.id, 'dismissed');
  }

  Future<OverloadRecommendation> editRecommendation(
    OverloadRecommendation rec, {
    double? newWeight,
    int? newReps,
    required OverloadRecommendationRepository repo,
  }) async {
    final edited = rec.copyWith(
      recommendedWeightKg: newWeight ?? rec.recommendedWeightKg,
      recommendedReps: newReps ?? rec.recommendedReps,
      status: 'edited',
    );
    await repo.update(edited);
    return edited;
  }

  OverloadRecommendation _buildRecommendation({
    required String exerciseId,
    String? sessionId,
    required double? previousWeight,
    required int? previousReps,
    required double? recommendedWeight,
    required int? recommendedReps,
    required String reasoning,
  }) {
    return OverloadRecommendation(
      id: generateId(),
      exerciseId: exerciseId,
      sessionId: sessionId,
      previousWeightKg: previousWeight,
      previousReps: previousReps,
      recommendedWeightKg: recommendedWeight,
      recommendedReps: recommendedReps,
      reasoning: reasoning,
      status: 'pending',
      createdAt: DateTime.now(),
    );
  }

  String _formatWeight(double? weight) {
    if (weight == null) return '—';
    return '${weight.toStringAsFixed(1)} kg';
  }

  double? _dominantWeight(List<WorkoutSet> sets) {
    final weights = sets
        .where((s) => s.weightKg != null)
        .map((s) => s.weightKg!)
        .toList();
    if (weights.isEmpty) return null;
    final counts = <double, int>{};
    for (final w in weights) {
      counts[w] = (counts[w] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  int? _averageReps(List<WorkoutSet> sets) {
    final reps = sets
        .where((s) => s.reps != null && s.reps! > 0)
        .map((s) => s.reps!);
    if (reps.isEmpty) return null;
    return (reps.reduce((a, b) => a + b) / reps.length).round();
  }
}
