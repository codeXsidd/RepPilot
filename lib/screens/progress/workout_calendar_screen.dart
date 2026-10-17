import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:rep_pilot/models/workout_session.dart';
import 'package:rep_pilot/repositories/workout_session_repository.dart';
import 'package:rep_pilot/repositories/workout_set_repository.dart';
import 'package:rep_pilot/screens/workout/session_summary_screen.dart';
import 'package:rep_pilot/widgets/empty_state.dart';

class WorkoutCalendarScreen extends StatefulWidget {
  const WorkoutCalendarScreen({super.key});

  @override
  State<WorkoutCalendarScreen> createState() => _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends State<WorkoutCalendarScreen> {
  DateTime _displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  DateTime? _selectedDay;

  List<WorkoutSession> _monthSessions = [];
  Map<String, int> _setCounts = {};
  bool _loading = true;

  /// Sessions keyed by day-of-month for quick lookup.
  Map<int, List<WorkoutSession>> _sessionsByDay = {};

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() => _loading = true);

    final sessionRepo = context.read<WorkoutSessionRepository>();
    final setRepo = context.read<WorkoutSetRepository>();

    final start = DateTime(_displayedMonth.year, _displayedMonth.month);
    final end = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
    ).subtract(const Duration(seconds: 1));

    final sessions = await sessionRepo.getByDateRange(start, end);
    final completed = sessions.where((s) => s.completedAt != null).toList();

    final counts = <String, int>{};
    for (final s in completed) {
      final sets = await setRepo.getBySessionId(s.id);
      counts[s.id] = sets.where((ws) => ws.completed).length;
    }

    final byDay = <int, List<WorkoutSession>>{};
    for (final s in completed) {
      final day = s.startedAt.day;
      byDay.putIfAbsent(day, () => []).add(s);
    }

    if (!mounted) return;
    setState(() {
      _monthSessions = completed;
      _setCounts = counts;
      _sessionsByDay = byDay;
      _loading = false;
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
      _selectedDay = null;
    });
    _loadMonth();
  }

  void _goToNextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
      _selectedDay = null;
    });
    _loadMonth();
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = (_selectedDay == day) ? null : day;
    });
  }

  Future<void> _openSessionDetail(WorkoutSession session) async {
    final setRepo = context.read<WorkoutSetRepository>();
    final sets = await setRepo.getBySessionId(session.id);
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(session: session, sets: sets),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalWorkouts = _monthSessions.length;
    final monthLabel = DateFormat.yMMMM().format(_displayedMonth);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Calendar')),
      body: Column(
        children: [
          // Month navigation header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _goToPreviousMonth,
                  tooltip: 'Previous month',
                ),
                Column(
                  children: [
                    Text(
                      monthLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalWorkouts workout${totalWorkouts == 1 ? '' : 's'} this month',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _goToNextMonth,
                  tooltip: 'Next month',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Calendar grid
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _CalendarGrid(
                  displayedMonth: _displayedMonth,
                  sessionsByDay: _sessionsByDay,
                  selectedDay: _selectedDay,
                  onDaySelected: _selectDay,
                ),

          const Divider(height: 1),

          // Selected day sessions
          Expanded(child: _buildDaySessions(theme)),
        ],
      ),
    );
  }

  Widget _buildDaySessions(ThemeData theme) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    if (_selectedDay == null) {
      return Center(
        child: Text(
          'Tap a day to see workouts',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final daySessions = _sessionsByDay[_selectedDay!.day];
    if (daySessions == null || daySessions.isEmpty) {
      return const EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'Rest Day',
        description: 'No workouts recorded on this day.',
      );
    }

    final dayLabel = DateFormat.yMMMEd().format(_selectedDay!);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: daySessions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              dayLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          );
        }

        final session = daySessions[index - 1];
        final setCount = _setCounts[session.id] ?? 0;
        final duration = session.duration;
        final durationStr = duration != null ? _formatDuration(duration) : '--';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openSessionDetail(session),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.routineName.isNotEmpty
                              ? session.routineName
                              : 'Workout',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.Hm().format(session.startedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        durationStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$setCount sets',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

// ---------------------------------------------------------------------------
// Calendar grid widget
// ---------------------------------------------------------------------------

class _CalendarGrid extends StatelessWidget {
  final DateTime displayedMonth;
  final Map<int, List<WorkoutSession>> sessionsByDay;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const _CalendarGrid({
    required this.displayedMonth,
    required this.sessionsByDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final year = displayedMonth.year;
    final month = displayedMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);

    // Monday = 1, Sunday = 7 in Dart. We start the week on Monday.
    final firstWeekday = DateTime(year, month, 1).weekday; // 1-7
    final leadingBlanks = firstWeekday - 1; // blanks before day 1

    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day-of-week header row
          Row(
            children: dayLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),

          // Calendar cells via GridView
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: leadingBlanks + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingBlanks) {
                return const SizedBox.shrink();
              }

              final day = index - leadingBlanks + 1;
              final date = DateTime(year, month, day);
              final isToday = date == today;
              final isSelected = selectedDay != null && date == selectedDay;
              final hasWorkout = sessionsByDay.containsKey(day);

              return _DayCell(
                day: day,
                isToday: isToday,
                isSelected: isSelected,
                hasWorkout: hasWorkout,
                onTap: () => onDaySelected(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single day cell
// ---------------------------------------------------------------------------

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasWorkout;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasWorkout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color? bgColor;
    Color textColor = colorScheme.onSurface;

    if (isSelected) {
      bgColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
    } else if (isToday) {
      bgColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
    }

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: (isToday || isSelected) ? FontWeight.w700 : null,
                  color: textColor,
                ),
              ),
              if (hasWorkout && !isSelected)
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              if (hasWorkout && isSelected)
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
