import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/body_weight_entry.dart';
import '../../models/routine.dart';
import '../../models/workout_session.dart';
import '../../repositories/body_weight_repository.dart';
import '../../repositories/food_entry_repository.dart';
import '../../repositories/routine_repository.dart';
import '../../repositories/water_entry_repository.dart';
import '../../repositories/workout_session_repository.dart';
import '../../repositories/workout_set_repository.dart';
import '../../services/active_workout_service.dart';
import '../../services/motivation_service.dart';
import '../../services/streak_service.dart';
import '../../widgets/section_header.dart';
import '../workout/live_workout_screen.dart';
import '../workout/weekly_workouts_screen.dart';
import '../workout/workout_day_detail_screen.dart';
import 'weekly_report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _completedSessions = 0;
  int _todayWaterMl = 0;
  double _todayCalories = 0;
  double _todayProtein = 0;
  BodyWeightEntry? _latestWeight;
  bool _loading = true;
  bool _hasActiveSession = false;
  int _currentStreak = 0;
  int _totalWorkouts = 0;
  Routine? _todayRoutine;
  WorkoutSession? _todaySession;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final sessions = context.read<WorkoutSessionRepository>();
      final water = context.read<WaterEntryRepository>();
      final bodyWeight = context.read<BodyWeightRepository>();
      final food = context.read<FoodEntryRepository>();
      final streakService = context.read<StreakService>();
      final routineRepo = context.read<RoutineRepository>();

      final now = DateTime.now();
      final today = stripTime(now);
      final weekStart = today.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );

      final weekSessions = await sessions.countByDateRange(weekStart, weekEnd);
      final todayWater = await water.getDailyTotalMl(now);
      final latest = await bodyWeight.getLatest();
      final todayTotals = await food.getDailyTotals(now);
      final active = await sessions.getActiveSession();

      final allSessions = await sessions.getAll();
      final streak = streakService.getCurrentStreak(allSessions, now);
      final total = streakService.getTotalWorkouts(allSessions);

      final todayDow = now.weekday;
      final todayRoutines = await routineRepo.getByDayOfWeek(todayDow);
      final todayRoutine = todayRoutines.isNotEmpty
          ? todayRoutines.first
          : null;

      WorkoutSession? todaySession;
      if (todayRoutine != null) {
        final dateStr = formatDateOnly(now);
        todaySession = await sessions.getForRoutineDate(
          todayRoutine.id,
          dateStr,
        );
      }

      if (!mounted) return;
      setState(() {
        _completedSessions = weekSessions;
        _todayWaterMl = todayWater;
        _latestWeight = latest;
        _todayCalories = todayTotals['calories'] ?? 0;
        _todayProtein = todayTotals['protein'] ?? 0;
        _hasActiveSession = active != null;
        _currentStreak = streak;
        _totalWorkouts = total;
        _todayRoutine = todayRoutine;
        _todaySession = todaySession;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load dashboard: $e')));
    }
  }

  Future<void> _resumeWorkout() async {
    final service = context.read<ActiveWorkoutService>();
    final resumed = await service.resumeSession(
      sessionRepo: context.read<WorkoutSessionRepository>(),
      setRepo: context.read<WorkoutSetRepository>(),
    );

    if (!mounted) return;

    if (resumed) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const LiveWorkoutScreen()),
      );
      _loadDashboard();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not resume workout')));
      setState(() => _hasActiveSession = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateFormat.yMMMMEEEEd().format(DateTime.now());
    final motivation = context.read<MotivationService>();
    final streakService = context.read<StreakService>();
    final todayMessage = motivation.getMessageForDate(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.fitness_center, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('RepPilot'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Weekly Report',
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const WeeklyReportScreen()),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_hasActiveSession) ...[
                    Card(
                      color: theme.colorScheme.primaryContainer,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _resumeWorkout,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.play_circle_fill,
                                color: theme.colorScheme.onPrimaryContainer,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Unfinished Workout',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                    ),
                                    Text(
                                      'Tap to resume where you left off',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _TodaysWorkoutCard(
                    routine: _todayRoutine,
                    session: _todaySession,
                    onTap: _todayRoutine != null
                        ? () async {
                            await Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkoutDayDetailScreen(
                                  routine: _todayRoutine!,
                                  date: stripTime(DateTime.now()),
                                ),
                              ),
                            );
                            _loadDashboard();
                          }
                        : null,
                    onViewAll: () async {
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WeeklyWorkoutsScreen(),
                        ),
                      );
                      _loadDashboard();
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    today,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.format_quote,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              todayMessage,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_currentStreak > 0 || _totalWorkouts > 0) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              _currentStreak > 0
                                  ? Icons.local_fire_department
                                  : Icons.fitness_center,
                              color: _currentStreak > 0
                                  ? Colors.orange
                                  : theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                streakService.getStreakMessage(_currentStreak),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'TODAY\'S OVERVIEW'),
                  _SummaryGrid(
                    items: [
                      _SummaryItem(
                        icon: Icons.fitness_center,
                        label: 'Workouts This Week',
                        value: '$_completedSessions',
                        isEmpty: _completedSessions == 0,
                      ),
                      _SummaryItem(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Body Weight',
                        value: _latestWeight != null
                            ? '${_latestWeight!.weightKg.toStringAsFixed(1)} kg'
                            : '--',
                        isEmpty: _latestWeight == null,
                      ),
                      _SummaryItem(
                        icon: Icons.local_fire_department_outlined,
                        label: 'Calories Today',
                        value: _todayCalories > 0
                            ? '${_todayCalories.toStringAsFixed(0)} kcal'
                            : '--',
                        isEmpty: _todayCalories == 0,
                      ),
                      _SummaryItem(
                        icon: Icons.water_drop_outlined,
                        label: 'Water Today',
                        value: _todayWaterMl > 0 ? '$_todayWaterMl ml' : '--',
                        isEmpty: _todayWaterMl == 0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'QUICK STATS'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _QuickStatRow(
                            label: 'Protein today',
                            value: _todayProtein > 0
                                ? '${_todayProtein.toStringAsFixed(0)}g'
                                : 'No meals logged',
                          ),
                          const Divider(height: 24),
                          _QuickStatRow(
                            label: 'Current streak',
                            value: _currentStreak > 0
                                ? '$_currentStreak days'
                                : 'Start today!',
                          ),
                          const Divider(height: 24),
                          _QuickStatRow(
                            label: 'Total workouts',
                            value: '$_totalWorkouts',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final List<_SummaryItem> items;
  const _SummaryGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: items.map((item) => _SummaryCard(item: item)).toList(),
    );
  }
}

class _SummaryItem {
  final IconData icon;
  final String label;
  final String value;
  final bool isEmpty;
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isEmpty = false,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryItem item;
  const _SummaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              item.icon,
              size: 22,
              color: item.isEmpty
                  ? theme.colorScheme.outlineVariant
                  : theme.colorScheme.primary,
            ),
            Text(
              item.value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: item.isEmpty
                    ? theme.colorScheme.outlineVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
            Text(
              item.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatRow extends StatelessWidget {
  final String label;
  final String value;
  const _QuickStatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TodaysWorkoutCard extends StatelessWidget {
  final Routine? routine;
  final WorkoutSession? session;
  final VoidCallback? onTap;
  final VoidCallback onViewAll;

  const _TodaysWorkoutCard({
    required this.routine,
    required this.session,
    required this.onTap,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (routine == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.hotel,
                color: theme.colorScheme.outlineVariant,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rest Day',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'No workout scheduled for today.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('Week')),
            ],
          ),
        ),
      );
    }

    final isCompleted = session != null && !session!.isActive;
    final isInProgress = session != null && session!.isActive;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : isInProgress
                    ? Icons.play_circle_fill
                    : Icons.fitness_center,
                color: isCompleted
                    ? Colors.green[700]
                    : isInProgress
                    ? Colors.orange[700]
                    : theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine!.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      isCompleted
                          ? 'Completed'
                          : isInProgress
                          ? 'In Progress — tap to resume'
                          : 'Tap to view workout plan',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isCompleted
                            ? Colors.green[700]
                            : isInProgress
                            ? Colors.orange[700]
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('Week')),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
