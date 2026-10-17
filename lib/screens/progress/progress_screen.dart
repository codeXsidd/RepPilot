import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/body_weight_repository.dart';
import '../../repositories/workout_session_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _totalSessions = 0;
  int _totalWeightEntries = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final sessions = context.read<WorkoutSessionRepository>();
    final bodyWeight = context.read<BodyWeightRepository>();

    final allSessions = await sessions.getAll();
    final allWeights = await bodyWeight.getAll();

    if (!mounted) return;
    setState(() {
      _totalSessions = allSessions.length;
      _totalWeightEntries = allWeights.length;
      _loading = false;
    });
  }

  bool get _hasData => _totalSessions > 0 || _totalWeightEntries > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProgress,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SectionHeader(title: 'BODY WEIGHT'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _totalWeightEntries > 0
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_totalWeightEntries entries recorded',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Weight trend charts will appear here once '
                                  'chart support is added.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Icon(
                                  Icons.show_chart_rounded,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No weight entries yet. Log your body weight '
                                    'to see trends.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'TRAINING HISTORY'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _totalSessions > 0
                          ? Text(
                              '$_totalSessions workout sessions recorded.',
                              style: theme.textTheme.bodyMedium,
                            )
                          : Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Complete workouts to build your training history.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (!_hasData) ...[
                    const SizedBox(height: 24),
                    const EmptyState(
                      icon: Icons.trending_up_rounded,
                      title: 'No Progress Data Yet',
                      description:
                          'Start logging workouts and body weight to track your '
                          'fitness progress over time. Weekly reports will be '
                          'available once you have data.',
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
