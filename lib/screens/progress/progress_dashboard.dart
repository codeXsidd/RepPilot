import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/body_measurement.dart';
import 'package:rep_pilot/models/body_weight_entry.dart';
import 'package:rep_pilot/models/workout_set.dart';
import 'package:rep_pilot/repositories/body_measurement_repository.dart';
import 'package:rep_pilot/repositories/body_weight_repository.dart';
import 'package:rep_pilot/repositories/user_profile_repository.dart';
import 'package:rep_pilot/repositories/workout_session_repository.dart';
import 'package:rep_pilot/repositories/workout_set_repository.dart';
import 'package:rep_pilot/services/weight_analytics_service.dart';
import 'package:rep_pilot/widgets/empty_state.dart';
import 'package:rep_pilot/widgets/section_header.dart';

import '../weight/body_measurement_screen.dart';
import '../weight/weight_chart.dart';
import '../weight/weight_screen.dart';
import 'workout_calendar_screen.dart';

class ProgressDashboard extends StatefulWidget {
  const ProgressDashboard({super.key});

  @override
  State<ProgressDashboard> createState() => _ProgressDashboardState();
}

class _ProgressDashboardState extends State<ProgressDashboard>
    with SingleTickerProviderStateMixin {
  static const _analytics = WeightAnalyticsService();

  late TabController _tabController;

  List<BodyWeightEntry> _weightEntries = [];
  List<BodyMeasurement> _measurements = [];
  String _weightUnit = 'kg';
  int _sessionsThisWeek = 0;
  int _sessionsLastWeek = 0;
  double _volumeThisWeek = 0;
  Map<String, ({double maxWeight, int maxReps, String exerciseName})> _records =
      {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final bwRepo = context.read<BodyWeightRepository>();
      final bmRepo = context.read<BodyMeasurementRepository>();
      final profileRepo = context.read<UserProfileRepository>();
      final sessionRepo = context.read<WorkoutSessionRepository>();
      final setRepo = context.read<WorkoutSetRepository>();

      final now = DateTime.now();
      final weekStart = stripTime(
        now.subtract(Duration(days: now.weekday - 1)),
      );
      final weekEnd = weekStart.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );
      final prevWeekStart = weekStart.subtract(const Duration(days: 7));
      final prevWeekEnd = weekStart.subtract(const Duration(seconds: 1));

      final entries = await bwRepo.getAll();
      final measurements = await bmRepo.getAll();
      final profile = await profileRepo.get();
      final thisWeek = await sessionRepo.countByDateRange(weekStart, weekEnd);
      final lastWeek = await sessionRepo.countByDateRange(
        prevWeekStart,
        prevWeekEnd,
      );

      final weekSessions = await sessionRepo.getByDateRange(weekStart, weekEnd);
      final allWeekSets = <WorkoutSet>[];
      for (final session in weekSessions) {
        if (session.completedAt != null) {
          final sets = await setRepo.getBySessionId(session.id);
          allWeekSets.addAll(sets);
        }
      }

      final allSessions = await sessionRepo.getAll();
      final allSets = <WorkoutSet>[];
      for (final session in allSessions) {
        if (session.completedAt != null) {
          final sets = await setRepo.getBySessionId(session.id);
          allSets.addAll(sets);
        }
      }

      if (!mounted) return;
      setState(() {
        _weightEntries = entries;
        _measurements = measurements;
        _weightUnit = profile?.weightUnit ?? 'kg';
        _sessionsThisWeek = thisWeek;
        _sessionsLastWeek = lastWeek;
        _volumeThisWeek = _analytics.calculateTotalVolume(allWeekSets);
        _records = _analytics.findPersonalRecords(allSets);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load progress: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Workout Calendar',
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const WorkoutCalendarScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Weight'),
            Tab(text: 'Measurements'),
            Tab(text: 'Training'),
            Tab(text: 'Records'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _WeightTab(
                  entries: _weightEntries,
                  weightUnit: _weightUnit,
                  analytics: _analytics,
                  onOpenWeightScreen: _openWeightScreen,
                ),
                _MeasurementsTab(
                  measurements: _measurements,
                  onOpenMeasurementScreen: _openMeasurementScreen,
                ),
                _TrainingTab(
                  sessionsThisWeek: _sessionsThisWeek,
                  sessionsLastWeek: _sessionsLastWeek,
                  volumeThisWeek: _volumeThisWeek,
                  weightUnit: _weightUnit,
                  analytics: _analytics,
                ),
                _RecordsTab(records: _records, weightUnit: _weightUnit),
              ],
            ),
    );
  }

  void _openWeightScreen() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const WeightScreen()),
    ).then((_) => _loadAll());
  }

  void _openMeasurementScreen() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const BodyMeasurementScreen()),
    ).then((_) => _loadAll());
  }
}

class _WeightTab extends StatelessWidget {
  final List<BodyWeightEntry> entries;
  final String weightUnit;
  final WeightAnalyticsService analytics;
  final VoidCallback onOpenWeightScreen;

  const _WeightTab({
    required this.entries,
    required this.weightUnit,
    required this.analytics,
    required this.onOpenWeightScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitLabel = weightUnit == 'lb' ? 'lb' : 'kg';

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyState(
              icon: Icons.monitor_weight_outlined,
              title: 'No Weight Data',
              description:
                  'Log your body weight to see trends and averages here.',
            ),
            FilledButton.tonal(
              onPressed: onOpenWeightScreen,
              child: const Text('Go to Weight Tracker'),
            ),
          ],
        ),
      );
    }

    final sortedAsc = List<BodyWeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final latest = entries.first;
    final sevenDayAvg = analytics.getSevenDayAverage(entries, DateTime.now());
    final change = analytics.getWeightChange(entries);

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest: ${displayWeight(latest.weightKg, weightUnit).toStringAsFixed(1)} $unitLabel',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (sevenDayAvg != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '7-day avg: ${displayWeight(sevenDayAvg, weightUnit).toStringAsFixed(1)} $unitLabel',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (change != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Change: ${change.change >= 0 ? '+' : ''}${displayWeight(change.change, weightUnit).toStringAsFixed(1)} $unitLabel '
                      'over ${change.days} days',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'TREND (LAST 30 DAYS)'),
          Builder(
            builder: (_) {
              final now = DateTime.now();
              final cutoff = now.subtract(const Duration(days: 30));
              final recent = sortedAsc
                  .where((e) => !e.date.isBefore(stripTime(cutoff)))
                  .toList();
              if (recent.isEmpty) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: Text('No data in the last 30 days')),
                );
              }
              final recentAvg = analytics.calculateMovingAverage(recent, 7);
              return WeightChart(
                entries: recent,
                movingAveragePoints: recentAvg,
                weightUnit: weightUnit,
              );
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.tonal(
              onPressed: onOpenWeightScreen,
              child: const Text('Full Weight Tracker'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingTab extends StatelessWidget {
  final int sessionsThisWeek;
  final int sessionsLastWeek;
  final double volumeThisWeek;
  final String weightUnit;
  final WeightAnalyticsService analytics;

  const _TrainingTab({
    required this.sessionsThisWeek,
    required this.sessionsLastWeek,
    required this.volumeThisWeek,
    required this.weightUnit,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitLabel = weightUnit == 'lb' ? 'lb' : 'kg';

    if (sessionsThisWeek == 0 && sessionsLastWeek == 0) {
      return const Center(
        child: EmptyState(
          icon: Icons.fitness_center_outlined,
          title: 'No Workout Data',
          description:
              'Complete workouts to see training stats and volume here.',
        ),
      );
    }

    final consistency = analytics.getWorkoutConsistency(
      sessionsThisWeek,
      sessionsLastWeek,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'WORKOUT CONSISTENCY'),
        Card(
          child: ListTile(
            leading: Icon(
              Icons.fitness_center,
              color: theme.colorScheme.primary,
            ),
            title: Text(consistency),
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'WEEKLY VOLUME'),
        Card(
          child: ListTile(
            leading: Icon(Icons.bar_chart, color: theme.colorScheme.primary),
            title: Text(
              volumeThisWeek > 0
                  ? '${displayWeight(volumeThisWeek, weightUnit).toStringAsFixed(0)} $unitLabel total'
                  : 'No volume data this week',
            ),
            subtitle: volumeThisWeek > 0
                ? const Text('Sum of weight x reps for working sets')
                : null,
          ),
        ),
      ],
    );
  }
}

class _MeasurementsTab extends StatelessWidget {
  final List<BodyMeasurement> measurements;
  final VoidCallback onOpenMeasurementScreen;

  const _MeasurementsTab({
    required this.measurements,
    required this.onOpenMeasurementScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (measurements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyState(
              icon: Icons.straighten,
              title: 'No Measurements',
              description:
                  'Log body measurements to track your progress over time.',
            ),
            FilledButton.tonal(
              onPressed: onOpenMeasurementScreen,
              child: const Text('Go to Measurements'),
            ),
          ],
        ),
      );
    }

    final latest = measurements.first;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest — ${DateFormat.yMMMd().format(latest.date)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (latest.waistCm != null)
                  _MeasurementRow(label: 'Waist', value: latest.waistCm!),
                if (latest.chestCm != null)
                  _MeasurementRow(label: 'Chest', value: latest.chestCm!),
                if (latest.leftArmCm != null)
                  _MeasurementRow(label: 'Left Arm', value: latest.leftArmCm!),
                if (latest.rightArmCm != null)
                  _MeasurementRow(
                    label: 'Right Arm',
                    value: latest.rightArmCm!,
                  ),
                if (latest.hipsCm != null)
                  _MeasurementRow(label: 'Hips', value: latest.hipsCm!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'RECENT ENTRIES'),
        ...measurements
            .take(10)
            .map(
              (m) => ListTile(
                title: Text(_summaryText(m)),
                subtitle: Text(DateFormat.yMMMd().format(m.date)),
                dense: true,
              ),
            ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.tonal(
            onPressed: onOpenMeasurementScreen,
            child: const Text('Full Measurement History'),
          ),
        ),
      ],
    );
  }

  String _summaryText(BodyMeasurement m) {
    final parts = <String>[];
    if (m.waistCm != null) parts.add('W: ${m.waistCm!.toStringAsFixed(1)}');
    if (m.chestCm != null) parts.add('C: ${m.chestCm!.toStringAsFixed(1)}');
    if (m.leftArmCm != null) {
      parts.add('LA: ${m.leftArmCm!.toStringAsFixed(1)}');
    }
    if (m.rightArmCm != null) {
      parts.add('RA: ${m.rightArmCm!.toStringAsFixed(1)}');
    }
    if (m.hipsCm != null) parts.add('H: ${m.hipsCm!.toStringAsFixed(1)}');
    return parts.join('  ·  ');
  }
}

class _MeasurementRow extends StatelessWidget {
  final String label;
  final double value;

  const _MeasurementRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} cm',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordsTab extends StatelessWidget {
  final Map<String, ({double maxWeight, int maxReps, String exerciseName})>
  records;
  final String weightUnit;

  const _RecordsTab({required this.records, required this.weightUnit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitLabel = weightUnit == 'lb' ? 'lb' : 'kg';

    if (records.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.emoji_events_outlined,
          title: 'No Personal Records',
          description:
              'Complete workouts to see your personal records per exercise.',
        ),
      );
    }

    final sortedEntries = records.entries.toList()
      ..sort((a, b) => b.value.maxWeight.compareTo(a.value.maxWeight));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedEntries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SectionHeader(title: 'PERSONAL RECORDS'),
          );
        }
        final entry = sortedEntries[index - 1];
        final record = entry.value;
        return Card(
          child: ListTile(
            leading: Icon(Icons.emoji_events, color: theme.colorScheme.primary),
            title: Text(record.exerciseName),
            subtitle: Text(
              '${displayWeight(record.maxWeight, weightUnit).toStringAsFixed(1)} $unitLabel '
              'x ${record.maxReps} reps',
            ),
          ),
        );
      },
    );
  }
}
