import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/weekly_report.dart';
import '../../repositories/body_weight_repository.dart';
import '../../repositories/food_entry_repository.dart';
import '../../repositories/water_entry_repository.dart';
import '../../repositories/workout_session_repository.dart';
import '../../repositories/workout_set_repository.dart';
import '../../services/weekly_report_service.dart';
import '../../widgets/section_header.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  WeeklyReport? _report;
  bool _loading = true;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);

    try {
      final service = context.read<WeeklyReportService>();
      final report = await service.generateReport(
        weekStart: _weekStart,
        sessionRepo: context.read<WorkoutSessionRepository>(),
        setRepo: context.read<WorkoutSetRepository>(),
        weightRepo: context.read<BodyWeightRepository>(),
        foodRepo: context.read<FoodEntryRepository>(),
        waterRepo: context.read<WaterEntryRepository>(),
      );

      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load report: $e')));
    }
  }

  void _previousWeek() {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    _loadReport();
  }

  void _nextWeek() {
    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    final nextStart = _weekStart.add(const Duration(days: 7));
    if (!nextStart.isAfter(
      DateTime(currentMonday.year, currentMonday.month, currentMonday.day),
    )) {
      _weekStart = nextStart;
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat.MMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Report')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previousWeek,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '${df.format(_report!.weekStart)} — ${df.format(_report!.weekEnd)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: _nextWeek,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!_report!.hasAnyData)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No data recorded this week.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_report!.hasWorkoutData) ...[
                  const SectionHeader(title: 'TRAINING'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _StatRow(
                            'Workouts completed',
                            '${_report!.workoutsCompleted}',
                          ),
                          if (_report!.totalVolumeKg > 0) ...[
                            const Divider(height: 24),
                            _StatRow(
                              'Total volume',
                              '${_report!.totalVolumeKg.toStringAsFixed(0)} kg',
                            ),
                          ],
                          if (_report!.currentStreak > 0) ...[
                            const Divider(height: 24),
                            _StatRow(
                              'Current streak',
                              '${_report!.currentStreak} days',
                            ),
                          ],
                          if (_report!.longestStreak > 0) ...[
                            const Divider(height: 24),
                            _StatRow(
                              'Longest streak',
                              '${_report!.longestStreak} days',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_report!.newPersonalRecords.isNotEmpty) ...[
                  const SectionHeader(title: 'NEW PERSONAL RECORDS'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: _report!.newPersonalRecords
                            .map(
                              (pr) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.emoji_events,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${pr.exerciseName}: '
                                        '${pr.weightKg.toStringAsFixed(1)} kg '
                                        'x ${pr.reps}',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_report!.hasWeightData) ...[
                  const SectionHeader(title: 'BODY WEIGHT'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_report!.weightStart != null)
                            _StatRow(
                              'Week start',
                              '${_report!.weightStart!.toStringAsFixed(1)} kg',
                            ),
                          if (_report!.weightEnd != null) ...[
                            const Divider(height: 24),
                            _StatRow(
                              'Week end',
                              '${_report!.weightEnd!.toStringAsFixed(1)} kg',
                            ),
                          ],
                          if (_report!.weightChange != null) ...[
                            const Divider(height: 24),
                            _StatRow(
                              'Change',
                              '${_report!.weightChange! >= 0 ? '+' : ''}'
                                  '${_report!.weightChange!.toStringAsFixed(1)} kg',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_report!.hasNutritionData) ...[
                  const SectionHeader(title: 'NUTRITION (DAILY AVERAGES)'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _StatRow(
                            'Calories',
                            '${_report!.averageCalories!.toStringAsFixed(0)} kcal',
                          ),
                          if (_report!.averageProtein != null) ...[
                            const Divider(height: 24),
                            _StatRow(
                              'Protein',
                              '${_report!.averageProtein!.toStringAsFixed(0)} g',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_report!.hasWaterData) ...[
                  const SectionHeader(title: 'HYDRATION (DAILY AVERAGE)'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _StatRow(
                        'Water',
                        '${_report!.averageWaterMl!.toStringAsFixed(0)} ml',
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

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
