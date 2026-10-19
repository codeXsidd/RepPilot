import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/routine.dart';
import '../../models/workout_session.dart';
import '../../repositories/exercise_repository.dart';
import '../../repositories/overload_recommendation_repository.dart';
import '../../repositories/routine_exercise_repository.dart';
import '../../repositories/routine_repository.dart';
import '../../repositories/workout_session_repository.dart';
import '../../repositories/workout_set_repository.dart';
import '../../services/active_workout_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../exercises/exercise_list_screen.dart';
import 'live_workout_screen.dart';
import 'routine_form_screen.dart';
import 'session_summary_screen.dart';
import 'weekly_workouts_screen.dart';
import 'workout_history_screen.dart';

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  List<Routine> _routines = [];
  Map<int, List<Routine>> _schedule = {};
  Map<String, int> _exerciseCounts = {};
  Map<String, WorkoutSession?> _todaySessions = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final routineRepo = context.read<RoutineRepository>();
    final reRepo = context.read<RoutineExerciseRepository>();
    final sessionRepo = context.read<WorkoutSessionRepository>();

    final routines = await routineRepo.getAll();
    final schedule = await routineRepo.getWeeklySchedule();
    final counts = <String, int>{};
    final todayStr = formatDateOnly(DateTime.now());
    final sessions = <String, WorkoutSession?>{};

    for (final r in routines) {
      final exercises = await reRepo.getByRoutineId(r.id);
      counts[r.id] = exercises.length;
      final session = await sessionRepo.getForRoutineDate(r.id, todayStr);
      sessions[r.id] = session;
    }

    if (!mounted) return;
    setState(() {
      _routines = routines;
      _schedule = schedule;
      _exerciseCounts = counts;
      _todaySessions = sessions;
      _loading = false;
    });
  }

  Future<void> _navigateToForm({Routine? routine}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RoutineFormScreen(routine: routine)),
    );
    if (result == true) _loadData();
  }

  Future<void> _startWorkout(Routine routine) async {
    final workoutService = context.read<ActiveWorkoutService>();
    await workoutService.startFromRoutine(
      routineId: routine.id,
      routineRepo: context.read<RoutineRepository>(),
      reRepo: context.read<RoutineExerciseRepository>(),
      exerciseRepo: context.read<ExerciseRepository>(),
      sessionRepo: context.read<WorkoutSessionRepository>(),
      setRepo: context.read<WorkoutSetRepository>(),
      recRepo: context.read<OverloadRecommendationRepository>(),
    );

    if (!mounted) return;

    if (workoutService.lastError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(workoutService.lastError!)));
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const LiveWorkoutScreen()),
    );
    _loadData();
  }

  Future<void> _startStandaloneWorkout() async {
    final nameCtrl = TextEditingController(text: 'Quick Workout');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Workout'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Workout Name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      nameCtrl.dispose();
      return;
    }

    final name = nameCtrl.text.trim().isEmpty
        ? 'Quick Workout'
        : nameCtrl.text.trim();
    nameCtrl.dispose();

    final workoutService = context.read<ActiveWorkoutService>();
    await workoutService.startStandalone(
      name: name,
      sessionRepo: context.read<WorkoutSessionRepository>(),
    );

    if (!mounted) return;

    if (workoutService.lastError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(workoutService.lastError!)));
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const LiveWorkoutScreen()),
    );
    _loadData();
  }

  Future<void> _duplicateRoutine(Routine routine) async {
    final repo = context.read<RoutineRepository>();
    await repo.duplicate(routine.id);
    _loadData();
  }

  Future<void> _archiveRoutine(Routine routine) async {
    final repo = context.read<RoutineRepository>();
    await repo.archive(routine.id);
    _loadData();
  }

  Future<void> _deleteRoutine(Routine routine) async {
    final repo = context.read<RoutineRepository>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Routine'),
        content: Text(
          'Are you sure you want to delete "${routine.name}"? '
          'Completed workout history will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await repo.delete(routine.id);
    _loadData();
  }

  Future<void> _undoCompletion(Routine routine) async {
    final session = _todaySessions[routine.id];
    if (session == null || session.isActive) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Undo Completion?'),
        content: const Text(
          'This will mark the workout as incomplete for today. '
          'Your logged sets will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Undo'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final sessionRepo = context.read<WorkoutSessionRepository>();
    await sessionRepo.uncomplete(session.id);
    _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout marked as incomplete')),
    );
  }

  Future<void> _viewSummary(Routine routine) async {
    final session = _todaySessions[routine.id];
    if (session == null) return;
    final setRepo = context.read<WorkoutSetRepository>();
    final sets = await setRepo.getBySessionId(session.id);
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(session: session, sets: sets),
      ),
    );
    _loadData();
  }

  Future<void> _showDayAssignment(int dayOfWeek) async {
    final routineRepo = context.read<RoutineRepository>();
    final routines = await routineRepo.getAll();

    if (!mounted) return;

    final dayName = _dayNames[dayOfWeek - 1];
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Assign routine to $dayName',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.hotel_rounded),
              title: const Text('Rest Day (clear)'),
              onTap: () async {
                final current = _schedule[dayOfWeek];
                if (current != null) {
                  for (final r in current) {
                    await routineRepo.unschedule(r.id);
                  }
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
            ),
            const Divider(height: 1),
            ...routines.map(
              (r) => ListTile(
                leading: const Icon(Icons.fitness_center_rounded),
                title: Text(r.name),
                trailing: r.dayOfWeek == dayOfWeek
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(ctx).colorScheme.primary,
                      )
                    : null,
                onTap: () async {
                  final current = _schedule[dayOfWeek];
                  if (current != null) {
                    for (final old in current) {
                      if (old.id != r.id) {
                        await routineRepo.unschedule(old.id);
                      }
                    }
                  }
                  await routineRepo.schedule(r.id, dayOfWeek);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadData();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'My Weekly Workouts',
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const WeeklyWorkoutsScreen()),
              );
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            tooltip: 'Quick Start',
            onPressed: _startStandaloneWorkout,
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Workout History',
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const WorkoutHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.library_books_rounded),
            tooltip: 'Exercise Library',
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const ExerciseListScreen()),
              );
              _loadData();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SectionHeader(title: 'WEEKLY PLANNER'),
                  _WeeklyPlanner(
                    schedule: _schedule,
                    onDayTap: _showDayAssignment,
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'MY ROUTINES',
                    trailing: TextButton(
                      onPressed: () => _navigateToForm(),
                      child: const Text('New'),
                    ),
                  ),
                  if (_routines.isEmpty)
                    const EmptyState(
                      icon: Icons.fitness_center_outlined,
                      title: 'No Routines Yet',
                      description:
                          'Create your first workout routine to get started. '
                          'Add exercises, set your rep targets, and plan your week.',
                    )
                  else
                    ..._routines.map((r) {
                      final session = _todaySessions[r.id];
                      final isCompleted = session != null && !session.isActive;
                      final isInProgress = session != null && session.isActive;
                      return _RoutineCard(
                        routine: r,
                        exerciseCount: _exerciseCounts[r.id] ?? 0,
                        isCompleted: isCompleted,
                        isInProgress: isInProgress,
                        onTap: () => _navigateToForm(routine: r),
                        onStart: () => _startWorkout(r),
                        onEdit: () => _navigateToForm(routine: r),
                        onDuplicate: () => _duplicateRoutine(r),
                        onArchive: () => _archiveRoutine(r),
                        onDelete: () => _deleteRoutine(r),
                        onUndoCompletion: () => _undoCompletion(r),
                        onViewSummary: () => _viewSummary(r),
                      );
                    }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'workout_fab',
        onPressed: () => _navigateToForm(),
        tooltip: 'New Routine',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _WeeklyPlanner extends StatelessWidget {
  final Map<int, List<Routine>> schedule;
  final ValueChanged<int> onDayTap;

  const _WeeklyPlanner({required this.schedule, required this.onDayTap});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final dayOfWeek = index + 1;
          final isToday = dayOfWeek == today;
          final routines = schedule[dayOfWeek];
          final label = routines != null && routines.isNotEmpty
              ? routines.first.name
              : 'Rest';

          return _DayCard(
            dayName: _dayNames[index],
            routineLabel: label,
            isToday: isToday,
            hasRoutine: routines != null && routines.isNotEmpty,
            onTap: () => onDayTap(dayOfWeek),
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final String dayName;
  final String routineLabel;
  final bool isToday;
  final bool hasRoutine;
  final VoidCallback onTap;

  const _DayCard({
    required this.dayName,
    required this.routineLabel,
    required this.isToday,
    required this.hasRoutine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 96,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: isToday
                ? BorderSide(color: cs.primary, width: 1.5)
                : BorderSide(color: cs.outline.withValues(alpha: 0.15)),
          ),
          color: isToday ? cs.primary.withValues(alpha: 0.1) : null,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isToday ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  routineLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasRoutine
                        ? (isToday ? cs.primary : cs.onSurface)
                        : cs.onSurfaceVariant.withValues(alpha: 0.5),
                    fontWeight: hasRoutine ? FontWeight.w500 : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final int exerciseCount;
  final bool isCompleted;
  final bool isInProgress;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback onUndoCompletion;
  final VoidCallback onViewSummary;

  const _RoutineCard({
    required this.routine,
    required this.exerciseCount,
    this.isCompleted = false,
    this.isInProgress = false,
    required this.onTap,
    required this.onStart,
    required this.onEdit,
    required this.onDuplicate,
    required this.onArchive,
    required this.onDelete,
    required this.onUndoCompletion,
    required this.onViewSummary,
  });

  String? get _dayLabel {
    final d = routine.dayOfWeek;
    if (d == null || d < 1 || d > 7) return null;
    return _dayNames[d - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dayLabel = _dayLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (dayLabel != null) ...[
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dayLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Icon(
                            Icons.fitness_center_rounded,
                            size: 13,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$exerciseCount exercise${exerciseCount == 1 ? '' : 's'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCompleted) ...[
                  SizedBox(
                    height: 34,
                    child: FilledButton.icon(
                      onPressed: onViewSummary,
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: const Text('Completed'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: Size.zero,
                        textStyle: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ] else if (isInProgress) ...[
                  SizedBox(
                    height: 34,
                    child: FilledButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Resume'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: Size.zero,
                        textStyle: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ] else if (exerciseCount > 0) ...[
                  SizedBox(
                    height: 34,
                    child: FilledButton(
                      onPressed: onStart,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: Size.zero,
                        textStyle: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Start'),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                      case 'duplicate':
                        onDuplicate();
                      case 'archive':
                        onArchive();
                      case 'delete':
                        onDelete();
                      case 'undo':
                        onUndoCompletion();
                      case 'summary':
                        onViewSummary();
                    }
                  },
                  itemBuilder: (_) => [
                    if (isCompleted) ...[
                      const PopupMenuItem(
                        value: 'summary',
                        child: Text('View Summary'),
                      ),
                      const PopupMenuItem(
                        value: 'undo',
                        child: Text('Undo Completion'),
                      ),
                      const PopupMenuDivider(),
                    ],
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Text('Duplicate'),
                    ),
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text('Archive'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
