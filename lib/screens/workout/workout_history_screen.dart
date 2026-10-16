import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:rep_pilot/models/workout_session.dart';
import 'package:rep_pilot/repositories/workout_session_repository.dart';
import 'package:rep_pilot/repositories/workout_set_repository.dart';
import 'package:rep_pilot/screens/workout/session_summary_screen.dart';
import 'package:rep_pilot/widgets/empty_state.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  List<WorkoutSession> _sessions = [];
  Map<String, int> _setCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final sessionRepo = context.read<WorkoutSessionRepository>();
    final setRepo = context.read<WorkoutSetRepository>();

    final sessions = await sessionRepo.getAll();
    final completedSessions = sessions
        .where((s) => s.completedAt != null)
        .toList();

    final counts = <String, int>{};
    for (final s in completedSessions) {
      final sets = await setRepo.getBySessionId(s.id);
      counts[s.id] = sets.where((ws) => ws.completed).length;
    }

    if (!mounted) return;
    setState(() {
      _sessions = completedSessions;
      _setCounts = counts;
      _loading = false;
    });
  }

  Future<void> _openDetail(WorkoutSession session) async {
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

    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'No Workout History',
              description:
                  'Complete a workout to see it here. Your training '
                  'history helps track progress over time.',
            )
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  final setCount = _setCounts[session.id] ?? 0;
                  final duration = session.duration;
                  final durationStr = duration != null
                      ? _formatDuration(duration)
                      : '--';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openDetail(session),
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
                                    DateFormat.yMMMd().add_Hm().format(
                                      session.startedAt,
                                    ),
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
                              Icons.chevron_right,
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
