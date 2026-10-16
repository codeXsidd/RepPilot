import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../repositories/food_entry_repository.dart';
import '../../widgets/section_header.dart';

class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  List<_DaySummary> _days = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWeek();
  }

  Future<void> _loadWeek() async {
    final repo = context.read<FoodEntryRepository>();
    final today = stripTime(DateTime.now());
    final start = today.subtract(const Duration(days: 6));

    final days = <_DaySummary>[];
    for (var i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));
      final totals = await repo.getDailyTotals(date);
      final entries = await repo.getByDate(date);
      days.add(
        _DaySummary(
          date: date,
          calories: totals['calories'] ?? 0,
          protein: totals['protein'] ?? 0,
          carbs: totals['carbs'] ?? 0,
          fat: totals['fat'] ?? 0,
          entryCount: entries.length,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _days = days;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysWithData = _days.where((d) => d.entryCount > 0).toList();

    final avgCalories = daysWithData.isEmpty
        ? 0.0
        : daysWithData.fold<double>(0, (s, d) => s + d.calories) /
              daysWithData.length;
    final avgProtein = daysWithData.isEmpty
        ? 0.0
        : daysWithData.fold<double>(0, (s, d) => s + d.protein) /
              daysWithData.length;

    final maxCal = _days.fold<double>(
      0,
      (m, d) => d.calories > m ? d.calories : m,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Summary')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SectionHeader(title: 'WEEKLY AVERAGES'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _AverageChip(
                            label: 'Avg Calories',
                            value: daysWithData.isEmpty
                                ? 'No data'
                                : '${avgCalories.toStringAsFixed(0)} kcal',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AverageChip(
                            label: 'Avg Protein',
                            value: daysWithData.isEmpty
                                ? 'No data'
                                : '${avgProtein.toStringAsFixed(0)}g',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (daysWithData.isEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'No meals logged in the past 7 days.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                const SectionHeader(title: 'DAILY BREAKDOWN'),
                for (final day in _days.reversed) ...[
                  _DayRow(day: day, maxCalories: maxCal),
                  const SizedBox(height: 4),
                ],
              ],
            ),
    );
  }
}

class _DaySummary {
  final DateTime date;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final int entryCount;

  const _DaySummary({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.entryCount,
  });
}

class _AverageChip extends StatelessWidget {
  final String label;
  final String value;

  const _AverageChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final _DaySummary day;
  final double maxCalories;

  const _DayRow({required this.day, required this.maxCalories});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = day.date == stripTime(DateTime.now());
    final hasData = day.entryCount > 0;
    final barFraction = maxCalories > 0
        ? (day.calories / maxCalories).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      color: isToday ? theme.colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isToday ? 'Today' : DateFormat.E().format(day.date),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isToday
                        ? theme.colorScheme.onPrimaryContainer
                        : null,
                  ),
                ),
                Text(
                  DateFormat.MMMd().format(day.date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (hasData) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: barFraction,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${day.calories.toStringAsFixed(0)} kcal  '
                '${day.protein.toStringAsFixed(0)}g P  '
                '${day.carbs.toStringAsFixed(0)}g C  '
                '${day.fat.toStringAsFixed(0)}g F',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else
              Text(
                'No data',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outlineVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
