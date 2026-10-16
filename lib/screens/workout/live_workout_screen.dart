import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rep_pilot/repositories/exercise_repository.dart';
import 'package:rep_pilot/repositories/exercise_settings_repository.dart';
import 'package:rep_pilot/repositories/overload_recommendation_repository.dart';
import 'package:rep_pilot/repositories/routine_exercise_repository.dart';
import 'package:rep_pilot/repositories/routine_repository.dart';
import 'package:rep_pilot/repositories/workout_session_repository.dart';
import 'package:rep_pilot/repositories/workout_set_repository.dart';
import 'package:rep_pilot/services/active_workout_service.dart';
import 'package:rep_pilot/services/overload_service.dart';
import 'package:rep_pilot/services/rest_timer_service.dart';
import 'package:rep_pilot/models/workout_set.dart';
import 'package:rep_pilot/screens/workout/session_summary_screen.dart';
import 'package:rep_pilot/screens/exercises/exercise_picker_screen.dart';

class LiveWorkoutScreen extends StatefulWidget {
  final String? routineId;
  final bool resuming;

  const LiveWorkoutScreen({super.key, this.routineId, this.resuming = false});

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen> {
  Timer? _durationTimer;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initSession();
    }
  }

  Future<void> _initSession() async {
    final service = context.read<ActiveWorkoutService>();
    if (widget.resuming) {
      await service.resumeSession(
        sessionRepo: context.read<WorkoutSessionRepository>(),
        setRepo: context.read<WorkoutSetRepository>(),
      );
    } else if (widget.routineId != null) {
      await service.startFromRoutine(
        routineId: widget.routineId!,
        routineRepo: context.read<RoutineRepository>(),
        reRepo: context.read<RoutineExerciseRepository>(),
        exerciseRepo: context.read<ExerciseRepository>(),
        sessionRepo: context.read<WorkoutSessionRepository>(),
        setRepo: context.read<WorkoutSetRepository>(),
      );
    }
    if (mounted) {
      final err = context.read<ActiveWorkoutService>().lastError;
      if (err != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _previousPerformanceLabel(
    ActiveWorkoutService service,
    String exerciseId,
  ) {
    final prev = service.previousSets[exerciseId];
    if (prev == null || prev.isEmpty) return '';
    final sessionSets = <String, List<WorkoutSet>>{};
    for (final s in prev) {
      (sessionSets[s.sessionId] ??= []).add(s);
    }
    final lastSessionSets = sessionSets.values.first;
    if (lastSessionSets.isEmpty) return '';
    final completed = lastSessionSets.where((s) => s.completed).toList();
    if (completed.isEmpty) return '';
    final reps = completed.map((s) => s.reps ?? 0).toList();
    final weight = completed.first.weightKg;
    final sameReps = reps.every((r) => r == reps.first);
    final repsStr = sameReps
        ? '${completed.length}x${reps.first}'
        : completed.map((s) => '${s.reps}').join('/');
    final weightStr = weight != null ? ' @ ${weight.toStringAsFixed(1)}kg' : '';
    return 'Last: $repsStr$weightStr';
  }

  Future<void> _finishWorkout() async {
    final service = context.read<ActiveWorkoutService>();
    if (service.isFinishing) return;

    final hasIncomplete = service.sets.any((s) => !s.completed && !s.isWarmup);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Workout'),
        content: Text(
          hasIncomplete
              ? 'You have incomplete sets. Finish anyway?'
              : 'Complete this workout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Going'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final allSets = List<WorkoutSet>.from(service.sets);
    final completed = await service.finishWorkout(
      sessionRepo: context.read<WorkoutSessionRepository>(),
      overloadService: context.read<OverloadService>(),
      settingsRepo: context.read<ExerciseSettingsRepository>(),
      setRepo: context.read<WorkoutSetRepository>(),
      recRepo: context.read<OverloadRecommendationRepository>(),
      exerciseRepo: context.read<ExerciseRepository>(),
    );

    if (completed != null && mounted) {
      final recs = service.lastRecommendations;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SessionSummaryScreen(
            session: completed,
            sets: allSets,
            recommendations: recs,
          ),
        ),
      );
    }
  }

  Future<void> _cancelWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Workout'),
        content: const Text(
          'This will discard all progress for this session. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Going'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Workout'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final service = context.read<ActiveWorkoutService>();
    await service.cancelWorkout(
      sessionRepo: context.read<WorkoutSessionRepository>(),
      setRepo: context.read<WorkoutSetRepository>(),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addExercise() async {
    final service = context.read<ActiveWorkoutService>();
    final excludeIds = service.exerciseOrder.toList();
    final selected = await Navigator.push<List<dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ExercisePickerScreen(excludeIds: excludeIds),
      ),
    );
    if (selected == null || selected.isEmpty || !mounted) return;

    final setRepo = context.read<WorkoutSetRepository>();
    for (final exercise in selected) {
      await service.addExerciseSets(
        exerciseId: exercise.id as String,
        exerciseName: exercise.name as String,
        count: 3,
        setRepo: setRepo,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ActiveWorkoutService>();
    final restTimer = context.watch<RestTimerService>();
    final session = service.currentSession;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Leave Workout?'),
            content: const Text(
              'Your workout will be saved and you can resume it later.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        if (shouldLeave == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.routineName.isNotEmpty
                    ? session.routineName
                    : 'Workout',
                style: theme.textTheme.titleMedium,
              ),
              Text(
                _formatDuration(service.workoutDuration),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Exercise',
              onPressed: _addExercise,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'cancel') _cancelWorkout();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'cancel', child: Text('Cancel Workout')),
              ],
            ),
          ],
        ),
        body: service.exerciseOrder.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 48,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No exercises yet',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _addExercise,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Exercise'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 100,
                ),
                itemCount: service.exerciseOrder.length,
                itemBuilder: (context, index) {
                  final exerciseId = service.exerciseOrder[index];
                  final exerciseSets = service.setsForExercise(exerciseId);
                  if (exerciseSets.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final name = exerciseSets.first.exerciseName;
                  final prevLabel = _previousPerformanceLabel(
                    service,
                    exerciseId,
                  );

                  return _ExerciseSection(
                    exerciseId: exerciseId,
                    exerciseName: name,
                    previousLabel: prevLabel,
                    sets: exerciseSets,
                    restTimer: restTimer,
                    onAddSet: () {
                      service.addSet(
                        exerciseId: exerciseId,
                        setRepo: context.read<WorkoutSetRepository>(),
                      );
                    },
                  );
                },
              ),
        bottomNavigationBar: _BottomBar(
          completedSets: service.completedSetCount,
          totalSets: service.totalSetCount,
          progress: service.progressPercent,
          isFinishing: service.isFinishing,
          restTimer: restTimer,
          onFinish: _finishWorkout,
        ),
      ),
    );
  }
}

class _ExerciseSection extends StatelessWidget {
  final String exerciseId;
  final String exerciseName;
  final String previousLabel;
  final List<WorkoutSet> sets;
  final RestTimerService restTimer;
  final VoidCallback onAddSet;

  const _ExerciseSection({
    required this.exerciseId,
    required this.exerciseName,
    required this.previousLabel,
    required this.sets,
    required this.restTimer,
    required this.onAddSet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exerciseName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (previousLabel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            previousLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddSet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Set'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const SizedBox(
                    width: 36,
                    child: Text(
                      'SET',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'KG',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'REPS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ...sets.map((set) => _SetRow(key: ValueKey(set.id), set: set)),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final WorkoutSet set;
  const _SetRow({super.key, required this.set});

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.set.weightKg?.toStringAsFixed(1) ?? '',
    );
    _repsCtrl = TextEditingController(text: widget.set.reps?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.set.id != widget.set.id) {
      _weightCtrl.text = widget.set.weightKg?.toStringAsFixed(1) ?? '';
      _repsCtrl.text = widget.set.reps?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  void _onWeightChanged() {
    final parsed = double.tryParse(_weightCtrl.text);
    if (parsed == null && _weightCtrl.text.isNotEmpty) return;
    final service = context.read<ActiveWorkoutService>();
    service.updateSet(
      setId: widget.set.id,
      weightKg: parsed,
      setRepo: context.read<WorkoutSetRepository>(),
    );
  }

  void _onRepsChanged() {
    final parsed = int.tryParse(_repsCtrl.text);
    if (parsed == null && _repsCtrl.text.isNotEmpty) return;
    final service = context.read<ActiveWorkoutService>();
    service.updateSet(
      setId: widget.set.id,
      reps: parsed,
      setRepo: context.read<WorkoutSetRepository>(),
    );
  }

  void _onCheckToggle(bool? value) {
    final service = context.read<ActiveWorkoutService>();
    final setRepo = context.read<WorkoutSetRepository>();
    if (value == true) {
      if (_repsCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter reps before completing a set')),
        );
        return;
      }
      service.completeSet(setId: widget.set.id, setRepo: setRepo);
      final restTimer = context.read<RestTimerService>();
      if (!restTimer.isRunning) {
        restTimer.start(60);
      }
    } else {
      service.uncompleteSet(setId: widget.set.id, setRepo: setRepo);
    }
  }

  void _toggleWarmup() {
    final service = context.read<ActiveWorkoutService>();
    service.updateSet(
      setId: widget.set.id,
      isWarmup: !widget.set.isWarmup,
      setRepo: context.read<WorkoutSetRepository>(),
    );
  }

  Future<void> _showDetailSheet() async {
    final set = widget.set;
    double? selectedRpe = set.rpe;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${set.exerciseName} — Set ${set.setNumber}',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'RPE (Rate of Perceived Exertion)',
                  style: Theme.of(ctx).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final rpe in [6.0, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0])
                      ChoiceChip(
                        label: Text(
                          rpe == rpe.roundToDouble()
                              ? rpe.toStringAsFixed(0)
                              : rpe.toStringAsFixed(1),
                        ),
                        selected: selectedRpe == rpe,
                        onSelected: (selected) {
                          setSheetState(() {
                            selectedRpe = selected ? rpe : null;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    final service = ctx.read<ActiveWorkoutService>();
                    service.updateSet(
                      setId: set.id,
                      rpe: selectedRpe,
                      setRepo: ctx.read<WorkoutSetRepository>(),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final set = widget.set;
    final completedBg = set.completed
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
        : null;

    return Dismissible(
      key: ValueKey('dismiss-${set.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.errorContainer,
        child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) {
        context.read<ActiveWorkoutService>().removeSet(
          setId: set.id,
          setRepo: context.read<WorkoutSetRepository>(),
        );
      },
      child: GestureDetector(
        onLongPress: _showDetailSheet,
        child: Container(
          decoration: BoxDecoration(
            color: completedBg,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleWarmup,
                child: SizedBox(
                  width: 36,
                  child: Text(
                    set.isWarmup ? 'W' : '${set.setNumber}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: set.isWarmup
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(),
                      hintText: '--',
                    ),
                    onChanged: (_) => _onWeightChanged(),
                    enabled: !set.completed,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _repsCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(),
                      hintText: '--',
                    ),
                    onChanged: (_) => _onRepsChanged(),
                    enabled: !set.completed,
                  ),
                ),
              ),
              if (set.rpe != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    set.rpe!.toStringAsFixed(
                      set.rpe! == set.rpe!.roundToDouble() ? 0 : 1,
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              SizedBox(
                width: 48,
                child: Checkbox(
                  value: set.completed,
                  onChanged: _onCheckToggle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int completedSets;
  final int totalSets;
  final double progress;
  final bool isFinishing;
  final RestTimerService restTimer;
  final VoidCallback onFinish;

  const _BottomBar({
    required this.completedSets,
    required this.totalSets,
    required this.progress,
    required this.isFinishing,
    required this.restTimer,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (restTimer.isRunning || restTimer.isComplete) ...[
                _RestTimerBar(restTimer: restTimer),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$completedSets / $totalSets sets',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: isFinishing ? null : onFinish,
                    child: isFinishing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Finish'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestTimerBar extends StatelessWidget {
  final RestTimerService restTimer;
  const _RestTimerBar({required this.restTimer});

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplete = restTimer.isComplete;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isComplete
            ? theme.colorScheme.tertiaryContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.timer,
            size: 20,
            color: isComplete
                ? theme.colorScheme.onTertiaryContainer
                : theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isComplete
                  ? 'Rest complete!'
                  : 'Rest: ${_formatTimer(restTimer.remainingSeconds)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isComplete
                    ? theme.colorScheme.onTertiaryContainer
                    : theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          if (!isComplete && restTimer.isRunning)
            IconButton(
              icon: Icon(
                restTimer.isPaused ? Icons.play_arrow : Icons.pause,
                size: 20,
              ),
              onPressed: restTimer.isPaused
                  ? restTimer.resume
                  : restTimer.pause,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: restTimer.reset,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
