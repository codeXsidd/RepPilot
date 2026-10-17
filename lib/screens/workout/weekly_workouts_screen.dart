import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/routine.dart';
import '../../models/workout_session.dart';
import '../../repositories/routine_repository.dart';
import '../../repositories/workout_session_repository.dart';
import '../../theme/app_theme.dart';
import 'workout_day_detail_screen.dart';

const _dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

enum _DayStatus { rest, planned, inProgress, completed }

class WeeklyWorkoutsScreen extends StatefulWidget {
  const WeeklyWorkoutsScreen({super.key});

  @override
  State<WeeklyWorkoutsScreen> createState() => _WeeklyWorkoutsScreenState();
}

class _WeeklyWorkoutsScreenState extends State<WeeklyWorkoutsScreen> {
  DateTime _weekStart = _currentWeekStart();
  Map<int, List<Routine>> _schedule = {};
  Map<String, List<WorkoutSession>> _sessions = {};
  bool _loading = true;

  static DateTime _currentWeekStart() {
    final now = DateTime.now();
    return stripTime(now.subtract(Duration(days: now.weekday - 1)));
  }

  @override
  void initState() {
    super.initState();
    _loadWeek();
  }

  Future<void> _loadWeek() async {
    setState(() => _loading = true);
    final routineRepo = context.read<RoutineRepository>();
    final sessionRepo = context.read<WorkoutSessionRepository>();
    final schedule = await routineRepo.getWeeklySchedule();

    final sessions = <String, List<WorkoutSession>>{};
    for (var i = 0; i < 7; i++) {
      final date = _weekStart.add(Duration(days: i));
      final dateStr = formatDateOnly(date);
      final daySessions = await sessionRepo.getForPlannedDate(dateStr);
      if (daySessions.isNotEmpty) {
        sessions[dateStr] = daySessions;
      }
    }

    if (!mounted) return;
    setState(() {
      _schedule = schedule;
      _sessions = sessions;
      _loading = false;
    });
  }

  void _previousWeek() {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    _loadWeek();
  }

  void _nextWeek() {
    _weekStart = _weekStart.add(const Duration(days: 7));
    _loadWeek();
  }

  void _goToCurrentWeek() {
    _weekStart = _currentWeekStart();
    _loadWeek();
  }

  _DayStatus _statusForDay(int dayOfWeek, String dateStr) {
    final daySessions = _sessions[dateStr] ?? [];
    final hasCompleted = daySessions.any((s) => !s.isActive);
    final hasActive = daySessions.any((s) => s.isActive);
    if (hasCompleted) return _DayStatus.completed;
    if (hasActive) return _DayStatus.inProgress;
    final routines = _schedule[dayOfWeek] ?? [];
    if (routines.isNotEmpty) return _DayStatus.planned;
    return _DayStatus.rest;
  }

  bool get _isCurrentWeek => _weekStart == _currentWeekStart();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final weekLabel =
        '${DateFormat.MMMd().format(_weekStart)} – ${DateFormat.MMMd().format(weekEnd)}';
    final today = stripTime(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('My Weekly Workouts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWeek,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _previousWeek,
                        icon: const Icon(Icons.chevron_left_rounded),
                        tooltip: 'Previous week',
                      ),
                      GestureDetector(
                        onTap: _isCurrentWeek ? null : _goToCurrentWeek,
                        child: Column(
                          children: [
                            Text(
                              weekLabel,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!_isCurrentWeek)
                              Text(
                                'Tap for this week',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _nextWeek,
                        icon: const Icon(Icons.chevron_right_rounded),
                        tooltip: 'Next week',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _WeeklyProgress(
                    schedule: _schedule,
                    sessions: _sessions,
                    weekStart: _weekStart,
                  ),
                  const SizedBox(height: 20),
                  for (var i = 0; i < 7; i++) _buildDayCard(i, today, theme),
                ],
              ),
            ),
    );
  }

  Widget _buildDayCard(int index, DateTime today, ThemeData theme) {
    final dayOfWeek = index + 1;
    final date = _weekStart.add(Duration(days: index));
    final dateStr = formatDateOnly(date);
    final isToday = date == today;
    final routines = _schedule[dayOfWeek] ?? [];
    final status = _statusForDay(dayOfWeek, dateStr);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: isToday
              ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
              : BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: routines.isNotEmpty
              ? () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutDayDetailScreen(
                        routine: routines.first,
                        date: date,
                      ),
                    ),
                  );
                  _loadWeek();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Column(
                    children: [
                      Text(
                        _dayShort[index],
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${date.day}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routines.isNotEmpty ? routines.first.name : 'Rest Day',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: routines.isEmpty
                              ? theme.colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                )
                              : null,
                        ),
                      ),
                      if (isToday)
                        Text(
                          'Today',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _DayStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case _DayStatus.completed:
        return _buildBadge(
          context,
          Icons.check_circle_rounded,
          'Done',
          AppColors.success,
        );
      case _DayStatus.inProgress:
        return _buildBadge(
          context,
          Icons.play_circle_rounded,
          'In Progress',
          AppColors.warning,
        );
      case _DayStatus.planned:
        return _buildBadge(
          context,
          Icons.event_rounded,
          'Planned',
          theme.colorScheme.primary,
        );
      case _DayStatus.rest:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBadge(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyProgress extends StatelessWidget {
  final Map<int, List<Routine>> schedule;
  final Map<String, List<WorkoutSession>> sessions;
  final DateTime weekStart;

  const _WeeklyProgress({
    required this.schedule,
    required this.sessions,
    required this.weekStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var planned = 0;
    var completed = 0;
    for (var i = 0; i < 7; i++) {
      final day = i + 1;
      if ((schedule[day] ?? []).isNotEmpty) planned++;
      final dateStr = formatDateOnly(weekStart.add(Duration(days: i)));
      final daySessions = sessions[dateStr] ?? [];
      if (daySessions.any((s) => !s.isActive)) completed++;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Progress',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$completed / $planned',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: planned > 0 ? completed / planned : 0,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
