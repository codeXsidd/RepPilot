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
import '../../theme/app_theme.dart';
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
    final now = DateTime.now();
    final today = DateFormat.MMMEd().format(now);
    final motivation = context.read<MotivationService>();
    final todayMessage = motivation.getMessageForDate(now);

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    surfaceTintColor: Colors.transparent,
                    title: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'RepPilot',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.bar_chart_rounded),
                        tooltip: 'Weekly Report',
                        onPressed: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WeeklyReportScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Text(
                          today,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_hasActiveSession) ...[
                          _ResumeWorkoutBanner(onTap: _resumeWorkout),
                          const SizedBox(height: 12),
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
                        const SizedBox(height: 20),
                        _StatsRow(
                          sessions: _completedSessions,
                          streak: _currentStreak,
                          totalWorkouts: _totalWorkouts,
                        ),
                        const SizedBox(height: 20),
                        _QuickOverview(
                          calories: _todayCalories,
                          protein: _todayProtein,
                          waterMl: _todayWaterMl,
                          latestWeight: _latestWeight,
                        ),
                        const SizedBox(height: 20),
                        _MotivationCard(message: todayMessage),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ResumeWorkoutBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ResumeWorkoutBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_filled_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout In Progress',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Tap to resume where you left off',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.hotel_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 2),
                    Text(
                      'No workout scheduled. Enjoy recovery!',
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

    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    if (isCompleted) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'Completed';
    } else if (isInProgress) {
      statusColor = AppColors.warning;
      statusIcon = Icons.play_circle_rounded;
      statusLabel = 'In Progress';
    } else {
      statusColor = theme.colorScheme.primary;
      statusIcon = Icons.fitness_center_rounded;
      statusLabel = 'Ready to start';
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 2),
                    Text(
                      statusLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('Week')),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int sessions;
  final int streak;
  final int totalWorkouts;

  const _StatsRow({
    required this.sessions,
    required this.streak,
    required this.totalWorkouts,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '$sessions',
            label: 'This Week',
            icon: Icons.fitness_center_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '$streak',
            label: 'Day Streak',
            icon: Icons.local_fire_department_rounded,
            accentColor: streak > 0 ? AppColors.warning : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '$totalWorkouts',
            label: 'Total',
            icon: Icons.emoji_events_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? accentColor;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickOverview extends StatelessWidget {
  final double calories;
  final double protein;
  final int waterMl;
  final BodyWeightEntry? latestWeight;

  const _QuickOverview({
    required this.calories,
    required this.protein,
    required this.waterMl,
    required this.latestWeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TODAY\'S OVERVIEW',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.0,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _OverviewItem(
                    icon: Icons.local_fire_department_rounded,
                    value: calories > 0 ? calories.toStringAsFixed(0) : '--',
                    unit: 'kcal',
                    color: theme.colorScheme.primary,
                  ),
                ),
                _VerticalDivider(color: theme.colorScheme.outline),
                Expanded(
                  child: _OverviewItem(
                    icon: Icons.egg_rounded,
                    value: protein > 0
                        ? '${protein.toStringAsFixed(0)}g'
                        : '--',
                    unit: 'protein',
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                _VerticalDivider(color: theme.colorScheme.outline),
                Expanded(
                  child: _OverviewItem(
                    icon: Icons.water_drop_rounded,
                    value: waterMl > 0 ? '$waterMl' : '--',
                    unit: 'ml',
                    color: const Color(0xFF42A5F5),
                  ),
                ),
                _VerticalDivider(color: theme.colorScheme.outline),
                Expanded(
                  child: _OverviewItem(
                    icon: Icons.monitor_weight_rounded,
                    value: latestWeight != null
                        ? latestWeight!.weightKg.toStringAsFixed(1)
                        : '--',
                    unit: 'kg',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final Color color;

  const _OverviewItem({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = value == '--';

    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: isEmpty ? color.withValues(alpha: 0.3) : color,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isEmpty
                ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                : null,
          ),
        ),
        Text(
          unit,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final Color color;
  const _VerticalDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: color.withValues(alpha: 0.15),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  final String message;
  const _MotivationCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        color: theme.colorScheme.primary.withValues(
          alpha: isDark ? 0.08 : 0.05,
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
