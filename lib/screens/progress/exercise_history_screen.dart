import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/workout_set.dart';
import '../../repositories/user_profile_repository.dart';
import '../../repositories/workout_session_repository.dart';
import '../../repositories/workout_set_repository.dart';
import '../../widgets/empty_state.dart';

class ExerciseHistoryScreen extends StatefulWidget {
  final String exerciseId;
  final String exerciseName;

  const ExerciseHistoryScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  State<ExerciseHistoryScreen> createState() => _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends State<ExerciseHistoryScreen> {
  List<_SessionRecord> _records = [];
  String _weightUnit = 'kg';
  bool _loading = true;
  _ChartMode _chartMode = _ChartMode.maxWeight;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final setRepo = context.read<WorkoutSetRepository>();
    final sessionRepo = context.read<WorkoutSessionRepository>();
    final profileRepo = context.read<UserProfileRepository>();

    final sets = await setRepo.getByExerciseId(widget.exerciseId);
    final profile = await profileRepo.get();

    final grouped = <String, List<WorkoutSet>>{};
    for (final s in sets) {
      (grouped[s.sessionId] ??= []).add(s);
    }

    final records = <_SessionRecord>[];
    for (final entry in grouped.entries) {
      final session = await sessionRepo.getById(entry.key);
      if (session == null || session.completedAt == null) continue;
      final sessionSets = entry.value
          .where((s) => s.completed && !s.isWarmup)
          .toList();
      if (sessionSets.isEmpty) continue;

      final maxWeight = sessionSets
          .map((s) => s.weightKg ?? 0)
          .reduce((a, b) => a > b ? a : b);
      final maxReps = sessionSets
          .map((s) => s.reps ?? 0)
          .reduce((a, b) => a > b ? a : b);
      final volume = sessionSets.fold<double>(
        0,
        (sum, s) => sum + (s.weightKg ?? 0) * (s.reps ?? 0),
      );

      records.add(
        _SessionRecord(
          date: session.startedAt,
          sets: sessionSets,
          maxWeight: maxWeight,
          maxReps: maxReps,
          totalVolume: volume,
          totalSets: sessionSets.length,
        ),
      );
    }

    records.sort((a, b) => a.date.compareTo(b.date));

    if (!mounted) return;
    setState(() {
      _records = records;
      _weightUnit = profile?.weightUnit ?? 'kg';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.exerciseName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'No History',
              description: 'Complete workouts with this exercise to see your progression.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(records: _records, weightUnit: _weightUnit),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'PROGRESSION',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    SegmentedButton<_ChartMode>(
                      segments: const [
                        ButtonSegment(
                          value: _ChartMode.maxWeight,
                          label: Text('Weight'),
                        ),
                        ButtonSegment(
                          value: _ChartMode.volume,
                          label: Text('Volume'),
                        ),
                        ButtonSegment(
                          value: _ChartMode.reps,
                          label: Text('Reps'),
                        ),
                      ],
                      selected: {_chartMode},
                      onSelectionChanged: (s) =>
                          setState(() => _chartMode = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: _ProgressionChart(
                    records: _records,
                    mode: _chartMode,
                    weightUnit: _weightUnit,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'HISTORY',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ..._records.reversed.map(
                  (r) => _HistoryRow(record: r, weightUnit: _weightUnit),
                ),
              ],
            ),
    );
  }
}

enum _ChartMode { maxWeight, volume, reps }

class _SessionRecord {
  final DateTime date;
  final List<WorkoutSet> sets;
  final double maxWeight;
  final int maxReps;
  final double totalVolume;
  final int totalSets;

  const _SessionRecord({
    required this.date,
    required this.sets,
    required this.maxWeight,
    required this.maxReps,
    required this.totalVolume,
    required this.totalSets,
  });
}

class _SummaryCard extends StatelessWidget {
  final List<_SessionRecord> records;
  final String weightUnit;

  const _SummaryCard({required this.records, required this.weightUnit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitLabel = weightUnit == 'lb' ? 'lb' : 'kg';

    final allTimeMax = records
        .map((r) => r.maxWeight)
        .reduce((a, b) => a > b ? a : b);
    final allTimeMaxReps = records
        .map((r) => r.maxReps)
        .reduce((a, b) => a > b ? a : b);
    final latest = records.last;
    final first = records.first;

    final weightChange = latest.maxWeight - first.maxWeight;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Best Weight',
                    value:
                        '${displayWeight(allTimeMax, weightUnit).toStringAsFixed(1)} $unitLabel',
                    icon: Icons.emoji_events,
                    color: Colors.amber,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Best Reps',
                    value: '$allTimeMaxReps',
                    icon: Icons.repeat,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Sessions',
                    value: '${records.length}',
                    icon: Icons.calendar_today,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Progress',
                    value:
                        '${weightChange >= 0 ? '+' : ''}${displayWeight(weightChange, weightUnit).toStringAsFixed(1)} $unitLabel',
                    icon: weightChange >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: weightChange >= 0 ? Colors.green : Colors.red,
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressionChart extends StatelessWidget {
  final List<_SessionRecord> records;
  final _ChartMode mode;
  final String weightUnit;

  const _ProgressionChart({
    required this.records,
    required this.mode,
    required this.weightUnit,
  });

  @override
  Widget build(BuildContext context) {
    if (records.length < 2) {
      return const Center(child: Text('Need at least 2 sessions for a chart'));
    }

    final theme = Theme.of(context);
    final spots = <FlSpot>[];

    for (var i = 0; i < records.length; i++) {
      final r = records[i];
      final y = switch (mode) {
        _ChartMode.maxWeight => displayWeight(r.maxWeight, weightUnit),
        _ChartMode.volume => displayWeight(r.totalVolume, weightUnit),
        _ChartMode.reps => r.maxReps.toDouble(),
      };
      spots.add(FlSpot(i.toDouble(), y));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range > 0 ? range * 0.1 : 5;

    return LineChart(
      LineChartData(
        minY: (minY - padding).floorToDouble(),
        maxY: (maxY + padding).ceilToDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outlineVariant.withAlpha(60),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  value.toInt().toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (records.length / 5).ceilToDouble().clamp(1, 100),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= records.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat.MMMd().format(records[idx].date),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: theme.colorScheme.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: theme.colorScheme.primary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withAlpha(30),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                if (idx < 0 || idx >= records.length) return null;
                final r = records[idx];
                final label = switch (mode) {
                  _ChartMode.maxWeight =>
                    '${displayWeight(r.maxWeight, weightUnit).toStringAsFixed(1)} ${weightUnit == 'lb' ? 'lb' : 'kg'}',
                  _ChartMode.volume =>
                    '${displayWeight(r.totalVolume, weightUnit).toStringAsFixed(0)} ${weightUnit == 'lb' ? 'lb' : 'kg'}',
                  _ChartMode.reps => '${r.maxReps} reps',
                };
                return LineTooltipItem(
                  '$label\n${DateFormat.yMMMd().format(r.date)}',
                  TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final _SessionRecord record;
  final String weightUnit;

  const _HistoryRow({required this.record, required this.weightUnit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitLabel = weightUnit == 'lb' ? 'lb' : 'kg';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat.yMMMd().format(record.date),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${record.totalSets} sets',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              children: record.sets.map((s) {
                final w = s.weightKg != null
                    ? '${displayWeight(s.weightKg!, weightUnit).toStringAsFixed(1)} $unitLabel'
                    : 'BW';
                return Text(
                  '$w x ${s.reps ?? 0}',
                  style: theme.textTheme.bodySmall,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
