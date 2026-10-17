import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/routine.dart';
import '../../repositories/exercise_repository.dart';
import '../../repositories/overload_recommendation_repository.dart';
import '../../repositories/routine_exercise_repository.dart';
import '../../repositories/routine_repository.dart';
import '../../repositories/workout_session_repository.dart';
import '../../repositories/workout_set_repository.dart';
import '../../services/active_workout_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../exercises/exercise_list_screen.dart';
import 'live_workout_screen.dart';
import 'routine_form_screen.dart';
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final routineRepo = context.read<RoutineRepository>();
    final reRepo = context.read<RoutineExerciseRepository>();

    final routines = await routineRepo.getAll();
    final schedule = await routineRepo.getWeeklySchedule();
    final counts = <String, int>{};
    for (final r in routines) {
      final exercises = await reRepo.getByRoutineId(r.id);
      counts[r.id] = exercises.length;
    }

    if (!mounted) return;
    setState(() {
      _routines = routines;
      _schedule = schedule;
      _exerciseCounts = counts;
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
              leading: const Icon(Icons.hotel),
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
                leading: const Icon(Icons.fitness_center),
                title: Text(r.name),
                trailing: r.dayOfWeek == dayOfWeek
                    ? Icon(
                        Icons.check_circle,
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
            icon: const Icon(Icons.calendar_month),
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
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Quick Start',
            onPressed: _startStandaloneWorkout,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Workout History',
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const WorkoutHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.library_books),
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
                    ..._routines.map(
                      (r) => _RoutineCard(
                        routine: r,
                        exerciseCount: _exerciseCounts[r.id] ?? 0,
                        onTap: () => _navigateToForm(routine: r),
                        onStart: () => _startWorkout(r),
                        onEdit: () => _navigateToForm(routine: r),
                        onDuplicate: () => _duplicateRoutine(r),
                        onArchive: () => _archiveRoutine(r),
                        onDelete: () => _deleteRoutine(r),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        tooltip: 'New Routine',
        child: const Icon(Icons.add),
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
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 96,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isToday
                ? BorderSide(color: colorScheme.primary, width: 2)
                : BorderSide.none,
          ),
          color: isToday
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isToday
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  routineLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasRoutine
                        ? (isToday
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface)
                        : colorScheme.outlineVariant,
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
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _RoutineCard({
    required this.routine,
    required this.exerciseCount,
    required this.onTap,
    required this.onStart,
    required this.onEdit,
    required this.onDuplicate,
    required this.onArchive,
    required this.onDelete,
  });

  String? get _dayLabel {
    final d = routine.dayOfWeek;
    if (d == null || d < 1 || d > 7) return null;
    return _dayNames[d - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayLabel = _dayLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (dayLabel != null) ...[
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dayLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Icon(
                            Icons.fitness_center,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$exerciseCount exercise${exerciseCount == 1 ? '' : 's'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (exerciseCount > 0) ...[
                  FilledButton.tonal(
                    onPressed: onStart,
                    child: const Text('Start'),
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
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                    PopupMenuItem(value: 'archive', child: Text('Archive')),
                    PopupMenuDivider(),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
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
