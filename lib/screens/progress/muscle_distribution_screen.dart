import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/exercise_repository.dart';
import '../../repositories/workout_session_repository.dart';
import '../../repositories/workout_set_repository.dart';
import '../../theme/app_theme.dart';

class MuscleDistributionScreen extends StatefulWidget {
  const MuscleDistributionScreen({super.key});

  @override
  State<MuscleDistributionScreen> createState() =>
      _MuscleDistributionScreenState();
}

class _MuscleDistributionScreenState extends State<MuscleDistributionScreen> {
  String _range = '30';
  Map<String, int> _distribution = {};
  int _totalSets = 0;
  bool _loading = true;

  static const _rangeOptions = ['7', '30', '90', '365'];
  static const _rangeLabels = {
    '7': 'Last 7 days',
    '30': 'Last 30 days',
    '90': 'Last 3 months',
    '365': 'Last year',
  };

  static const _muscleGroupOrder = [
    'chest',
    'back',
    'shoulders',
    'biceps',
    'triceps',
    'legs',
    'glutes',
    'calves',
    'core',
    'forearms',
  ];

  static final Map<String, Color> _muscleColors = {
    'chest': const Color(0xFFE53935),
    'back': const Color(0xFF448AFF),
    'shoulders': const Color(0xFFFFA726),
    'biceps': const Color(0xFF66BB6A),
    'triceps': const Color(0xFFAB47BC),
    'legs': const Color(0xFF26C6DA),
    'glutes': const Color(0xFFEF5350),
    'calves': const Color(0xFF8D6E63),
    'core': const Color(0xFFFDD835),
    'forearms': const Color(0xFF78909C),
    'full_body': const Color(0xFF5C6BC0),
    'mobility': const Color(0xFF4DB6AC),
  };

  @override
  void initState() {
    super.initState();
    _loadDistribution();
  }

  Future<void> _loadDistribution() async {
    setState(() => _loading = true);

    final sessionRepo = context.read<WorkoutSessionRepository>();
    final setRepo = context.read<WorkoutSetRepository>();
    final exerciseRepo = context.read<ExerciseRepository>();

    final days = int.parse(_range);
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));

    final sessions = await sessionRepo.getByDateRange(start, end);
    final completedSessions = sessions
        .where((s) => s.completedAt != null)
        .toList();

    final exerciseCache = <String, String>{};

    final dist = <String, int>{};
    for (final session in completedSessions) {
      final sets = await setRepo.getBySessionId(session.id);
      for (final s in sets) {
        if (!s.completed || s.isWarmup) continue;
        var group = exerciseCache[s.exerciseId];
        if (group == null) {
          final exercise = await exerciseRepo.getById(s.exerciseId);
          group = exercise?.category ?? 'other';
          exerciseCache[s.exerciseId] = group;
        }
        dist[group] = (dist[group] ?? 0) + 1;
      }
    }

    if (!mounted) return;
    setState(() {
      _distribution = dist;
      _totalSets = dist.values.fold(0, (a, b) => a + b);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Muscle Distribution')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<String>(
                  segments: _rangeOptions
                      .map(
                        (r) => ButtonSegment(
                          value: r,
                          label: Text(
                            _rangeLabels[r]!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                  selected: {_range},
                  onSelectionChanged: (v) {
                    _range = v.first;
                    _loadDistribution();
                  },
                ),
                const SizedBox(height: 20),
                if (_totalSets == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.pie_chart_outline_rounded,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No workout data for this period',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  _buildRadarChart(theme),
                  const SizedBox(height: 24),
                  _buildSummaryRow(theme),
                  const SizedBox(height: 16),
                  _buildBreakdown(theme),
                ],
              ],
            ),
    );
  }

  Widget _buildRadarChart(ThemeData theme) {
    final groups = _muscleGroupOrder
        .where((g) => _distribution.containsKey(g))
        .toList();
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }
    if (groups.length < 3) {
      return _buildSimpleBarChart(theme, groups);
    }

    final maxVal = groups
        .map((g) => _distribution[g]!)
        .reduce(math.max)
        .toDouble();
    if (maxVal == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 280,
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              titlePositionPercentageOffset: 0.2,
              dataSets: [
                RadarDataSet(
                  fillColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                  borderColor: AppColors.primaryBlue,
                  borderWidth: 2,
                  dataEntries: groups
                      .map(
                        (g) => RadarEntry(value: _distribution[g]!.toDouble()),
                      )
                      .toList(),
                ),
              ],
              getTitle: (index, angle) =>
                  RadarChartTitle(text: _formatGroup(groups[index]), angle: 0),
              tickCount: 4,
              ticksTextStyle: theme.textTheme.labelSmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
                fontSize: 9,
              ),
              tickBorderData: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
              gridBorderData: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
              titleTextStyle: theme.textTheme.labelSmall!.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleBarChart(ThemeData theme, List<String> groups) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: groups.map((g) {
            final sets = _distribution[g]!;
            final pct = _totalSets > 0 ? sets / _totalSets : 0.0;
            final color = _muscleColors[g] ?? AppColors.primaryBlue;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      _formatGroup(g),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$sets', style: theme.textTheme.bodySmall),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    final groupCount = _distribution.keys.where((k) => k != 'other').length;
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'Total Sets',
            value: '$_totalSets',
            theme: theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
            label: 'Muscle Groups',
            value: '$groupCount',
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdown(ThemeData theme) {
    final sorted = _distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Distribution',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in sorted) ...[
              _DistributionRow(
                group: entry.key,
                sets: entry.value,
                total: _totalSets,
                color: _muscleColors[entry.key] ?? AppColors.primaryBlue,
                theme: theme,
              ),
              if (entry != sorted.last)
                Divider(
                  height: 16,
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatGroup(String group) => group
      .split('_')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _StatChip({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
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
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final String group;
  final int sets;
  final int total;
  final Color color;
  final ThemeData theme;

  const _DistributionRow({
    required this.group,
    required this.sets,
    required this.total,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (sets / total * 100) : 0.0;
    final label = group
        .split('_')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? sets / total : 0,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 50,
          child: Text(
            '$sets sets',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.end,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 40,
          child: Text(
            '${pct.toStringAsFixed(0)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
