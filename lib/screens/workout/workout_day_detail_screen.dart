import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/exercise.dart';
import '../../models/routine.dart';
import '../../models/routine_exercise.dart';
import '../../models/workout_session.dart';
import '../../repositories/exercise_repository.dart';
import '../../repositories/overload_recommendation_repository.dart';
import '../../repositories/routine_exercise_repository.dart';
import '../../repositories/routine_repository.dart';
import '../../repositories/workout_session_repository.dart';
import '../../repositories/workout_set_repository.dart';
import '../../services/active_workout_service.dart';
import '../../theme/app_theme.dart';
import '../exercises/exercise_detail_screen.dart';
import 'live_workout_screen.dart';
import 'session_summary_screen.dart';

const _muscleGroupSvgs = <String, String>{
  'chest': 'assets/images/muscle_groups/chest.svg',
  'back': 'assets/images/muscle_groups/back.svg',
  'shoulders': 'assets/images/muscle_groups/shoulders.svg',
  'biceps': 'assets/images/muscle_groups/biceps.svg',
  'triceps': 'assets/images/muscle_groups/triceps.svg',
  'forearms': 'assets/images/muscle_groups/forearms.svg',
  'legs': 'assets/images/muscle_groups/legs.svg',
  'quadriceps': 'assets/images/muscle_groups/legs.svg',
  'hamstrings': 'assets/images/muscle_groups/hamstrings.svg',
  'glutes': 'assets/images/muscle_groups/glutes.svg',
  'calves': 'assets/images/muscle_groups/calves.svg',
  'core': 'assets/images/muscle_groups/core.svg',
  'abs': 'assets/images/muscle_groups/core.svg',
  'full body': 'assets/images/muscle_groups/full_body.svg',
  'full_body': 'assets/images/muscle_groups/full_body.svg',
  'mobility': 'assets/images/muscle_groups/mobility.svg',
};

String? _svgForMuscle(String muscle) {
  final key = muscle.toLowerCase().trim();
  return _muscleGroupSvgs[key];
}

class WorkoutDayDetailScreen extends StatefulWidget {
  final Routine routine;
  final DateTime date;

  const WorkoutDayDetailScreen({
    super.key,
    required this.routine,
    required this.date,
  });

  @override
  State<WorkoutDayDetailScreen> createState() => _WorkoutDayDetailScreenState();
}

class _WorkoutDayDetailScreenState extends State<WorkoutDayDetailScreen> {
  List<RoutineExercise> _routineExercises = [];
  Map<String, Exercise> _exercises = {};
  WorkoutSession? _existingSession;
  bool _loading = true;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final reRepo = context.read<RoutineExerciseRepository>();
    final exerciseRepo = context.read<ExerciseRepository>();
    final sessionRepo = context.read<WorkoutSessionRepository>();

    final routineExercises = await reRepo.getByRoutineId(widget.routine.id);
    final exercises = <String, Exercise>{};
    for (final re in routineExercises) {
      final ex = await exerciseRepo.getById(re.exerciseId);
      if (ex != null) exercises[re.exerciseId] = ex;
    }

    final dateStr = formatDateOnly(widget.date);
    final session = await sessionRepo.getForRoutineDate(
      widget.routine.id,
      dateStr,
    );

    if (!mounted) return;
    setState(() {
      _routineExercises = routineExercises;
      _exercises = exercises;
      _existingSession = session;
      _loading = false;
    });
  }

  Set<String> get _targetMuscles {
    final muscles = <String>{};
    for (final ex in _exercises.values) {
      if (ex.muscleGroup.isNotEmpty) muscles.add(ex.muscleGroup);
    }
    return muscles;
  }

  int get _totalSets =>
      _routineExercises.fold(0, (sum, re) => sum + re.targetSets);

  int get _estimatedMinutes {
    var totalSeconds = 0;
    for (final re in _routineExercises) {
      totalSeconds += re.targetSets * 45;
      totalSeconds += (re.targetSets - 1) * re.restSeconds;
    }
    return (totalSeconds / 60).ceil();
  }

  bool get _isCompleted =>
      _existingSession != null && !_existingSession!.isActive;

  bool get _isInProgress =>
      _existingSession != null && _existingSession!.isActive;

  Future<void> _startWorkout() async {
    if (_starting) return;
    setState(() => _starting = true);

    final workoutService = context.read<ActiveWorkoutService>();
    await workoutService.startFromRoutine(
      routineId: widget.routine.id,
      routineRepo: context.read<RoutineRepository>(),
      reRepo: context.read<RoutineExerciseRepository>(),
      exerciseRepo: context.read<ExerciseRepository>(),
      sessionRepo: context.read<WorkoutSessionRepository>(),
      setRepo: context.read<WorkoutSetRepository>(),
      recRepo: context.read<OverloadRecommendationRepository>(),
      plannedDate: formatDateOnly(widget.date),
    );

    if (!mounted) return;

    if (workoutService.lastError != null) {
      setState(() => _starting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(workoutService.lastError!)));
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const LiveWorkoutScreen()),
    );
    setState(() => _starting = false);
    _loadData();
  }

  Future<void> _resumeWorkout() async {
    final workoutService = context.read<ActiveWorkoutService>();
    final resumed = await workoutService.resumeSession(
      sessionRepo: context.read<WorkoutSessionRepository>(),
      setRepo: context.read<WorkoutSetRepository>(),
    );

    if (!mounted) return;
    if (resumed) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const LiveWorkoutScreen()),
      );
      _loadData();
    }
  }

  Future<void> _viewSummary() async {
    if (_existingSession == null) return;
    final setRepo = context.read<WorkoutSetRepository>();
    final sets = await setRepo.getBySessionId(_existingSession!.id);
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SessionSummaryScreen(session: _existingSession!, sets: sets),
      ),
    );
  }

  Future<void> _markIncomplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark Incomplete?'),
        content: const Text(
          'This will mark the workout as incomplete. '
          'Your logged sets will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark Incomplete'),
          ),
        ],
      ),
    );

    if (confirmed != true || _existingSession == null || !mounted) return;

    final sessionRepo = context.read<WorkoutSessionRepository>();
    await sessionRepo.uncomplete(_existingSession!.id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat.yMMMMEEEEd().format(widget.date);

    return Scaffold(
      appBar: AppBar(title: Text(widget.routine.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  dateLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _WorkoutOverviewCard(
                  routine: widget.routine,
                  targetMuscles: _targetMuscles,
                  exerciseCount: _routineExercises.length,
                  totalSets: _totalSets,
                  estimatedMinutes: _estimatedMinutes,
                  isCompleted: _isCompleted,
                  isInProgress: _isInProgress,
                ),
                const SizedBox(height: 16),
                if (_isCompleted) ...[
                  _CompletedBanner(
                    session: _existingSession!,
                    onViewSummary: _viewSummary,
                    onMarkIncomplete: _markIncomplete,
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'EXERCISES',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                if (_routineExercises.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No exercises in this routine yet.\nEdit the routine to add exercises.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ...List.generate(_routineExercises.length, (i) {
                    final re = _routineExercises[i];
                    final exercise = _exercises[re.exerciseId];
                    return _ExercisePreviewCard(
                      index: i + 1,
                      routineExercise: re,
                      exercise: exercise,
                      onTap: exercise != null
                          ? () => Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ExerciseDetailScreen(exercise: exercise),
                              ),
                            )
                          : null,
                    );
                  }),
                if (widget.routine.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notes',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.routine.notes,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildBottomAction(theme),
              ),
            ),
    );
  }

  Widget _buildBottomAction(ThemeData theme) {
    if (_isCompleted) {
      return FilledButton.tonal(
        onPressed: _viewSummary,
        child: const Text('View Workout Summary'),
      );
    }
    if (_isInProgress) {
      return FilledButton(
        onPressed: _resumeWorkout,
        child: const Text('Resume Workout'),
      );
    }
    return FilledButton.icon(
      onPressed: _starting ? null : _startWorkout,
      icon: _starting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_arrow_rounded),
      label: Text(_starting ? 'Starting...' : 'Start Workout'),
    );
  }
}

class _WorkoutOverviewCard extends StatelessWidget {
  final Routine routine;
  final Set<String> targetMuscles;
  final int exerciseCount;
  final int totalSets;
  final int estimatedMinutes;
  final bool isCompleted;
  final bool isInProgress;

  const _WorkoutOverviewCard({
    required this.routine,
    required this.targetMuscles,
    required this.exerciseCount,
    required this.totalSets,
    required this.estimatedMinutes,
    required this.isCompleted,
    required this.isInProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muscleList = targetMuscles.toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (muscleList.isNotEmpty) ...[
              Text(
                'Target Muscles',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: muscleList.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final muscle = muscleList[i];
                    final svgPath = _svgForMuscle(muscle);
                    return Column(
                      children: [
                        if (svgPath != null)
                          SvgPicture.asset(
                            svgPath,
                            width: 36,
                            height: 36,
                            colorFilter: ColorFilter.mode(
                              theme.colorScheme.primary,
                              BlendMode.srcIn,
                            ),
                          )
                        else
                          Icon(
                            Icons.fitness_center,
                            size: 36,
                            color: theme.colorScheme.primary,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          _capitalize(muscle),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                _InfoChip(
                  icon: Icons.fitness_center_rounded,
                  label: '$exerciseCount exercises',
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.check_box_outlined,
                  label: '$totalSets sets',
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: '~$estimatedMinutes min',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedBanner extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback onViewSummary;
  final VoidCallback onMarkIncomplete;

  const _CompletedBanner({
    required this.session,
    required this.onViewSummary,
    required this.onMarkIncomplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedAt = session.completedAt;
    final timeStr = completedAt != null
        ? DateFormat.jm().format(completedAt)
        : '';
    final duration = session.duration;
    final durationStr = duration != null
        ? '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s'
        : '';

    return Card(
      color: AppColors.success.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Workout Completed',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (timeStr.isNotEmpty || durationStr.isNotEmpty)
              Text(
                [
                  if (timeStr.isNotEmpty) 'Completed at $timeStr',
                  if (durationStr.isNotEmpty) 'Duration: $durationStr',
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewSummary,
                    child: const Text('View Summary'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onMarkIncomplete,
                  child: const Text('Mark Incomplete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExercisePreviewCard extends StatelessWidget {
  final int index;
  final RoutineExercise routineExercise;
  final Exercise? exercise;
  final VoidCallback? onTap;

  const _ExercisePreviewCard({
    required this.index,
    required this.routineExercise,
    required this.exercise,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ex = exercise;
    final svgPath = ex != null ? _svgForMuscle(ex.muscleGroup) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: svgPath != null
                      ? SvgPicture.asset(
                          svgPath,
                          width: 48,
                          height: 48,
                          colorFilter: ColorFilter.mode(
                            theme.colorScheme.primary.withValues(alpha: 0.6),
                            BlendMode.srcIn,
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$index',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex?.name ?? 'Exercise $index',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (ex != null && ex.muscleGroup.isNotEmpty)
                            _SmallChip(label: _capitalize(ex.muscleGroup)),
                          if (ex != null && ex.equipment.isNotEmpty)
                            _SmallChip(label: _capitalize(ex.equipment)),
                          if (ex != null && ex.difficulty.isNotEmpty)
                            _SmallChip(label: _capitalize(ex.difficulty)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${routineExercise.targetSets} sets × ${routineExercise.repsDisplay} reps'
                        '${routineExercise.targetWeightKg != null ? ' · ${routineExercise.targetWeightKg!.toStringAsFixed(1)} kg' : ''}'
                        ' · ${routineExercise.restSeconds}s rest',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (ex != null && ex.instructions.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          ex.instructions,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (ex != null && ex.safetyNotes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ex.safetyNotes,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.warning,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  const _SmallChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
