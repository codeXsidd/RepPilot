import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:rep_pilot/models/overload_recommendation.dart';
import 'package:rep_pilot/models/workout_session.dart';
import 'package:rep_pilot/models/workout_set.dart';
import 'package:rep_pilot/repositories/overload_recommendation_repository.dart';
import 'package:rep_pilot/services/overload_service.dart';
import 'package:rep_pilot/theme/app_theme.dart';

class SessionSummaryScreen extends StatefulWidget {
  final WorkoutSession session;
  final List<WorkoutSet> sets;
  final List<OverloadRecommendation> recommendations;

  const SessionSummaryScreen({
    super.key,
    required this.session,
    required this.sets,
    this.recommendations = const [],
  });

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  late List<OverloadRecommendation> _recs;
  final Map<String, String> _recStatuses = {};

  @override
  void initState() {
    super.initState();
    _recs = List.of(widget.recommendations);
    for (final rec in _recs) {
      _recStatuses[rec.id] = rec.status;
    }
  }

  String _exerciseName(String exerciseId) {
    for (final s in widget.sets) {
      if (s.exerciseId == exerciseId && s.exerciseName.isNotEmpty) {
        return s.exerciseName;
      }
    }
    return 'Exercise';
  }

  Future<void> _acceptRecommendation(OverloadRecommendation rec) async {
    final overloadService = context.read<OverloadService>();
    final recRepo = context.read<OverloadRecommendationRepository>();
    await overloadService.applyRecommendation(rec, recRepo);
    setState(() {
      _recStatuses[rec.id] = 'accepted';
    });
  }

  Future<void> _dismissRecommendation(OverloadRecommendation rec) async {
    final overloadService = context.read<OverloadService>();
    final recRepo = context.read<OverloadRecommendationRepository>();
    await overloadService.dismissRecommendation(rec, recRepo);
    setState(() {
      _recStatuses[rec.id] = 'dismissed';
    });
  }

  Future<void> _editRecommendation(OverloadRecommendation rec) async {
    final weightCtrl = TextEditingController(
      text: rec.recommendedWeightKg?.toStringAsFixed(1) ?? '',
    );
    final repsCtrl = TextEditingController(
      text: rec.recommendedReps?.toString() ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Suggestion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      weightCtrl.dispose();
      repsCtrl.dispose();
      return;
    }

    final newWeight = double.tryParse(weightCtrl.text);
    final newReps = int.tryParse(repsCtrl.text);
    weightCtrl.dispose();
    repsCtrl.dispose();

    final overloadService = context.read<OverloadService>();
    final recRepo = context.read<OverloadRecommendationRepository>();
    await overloadService.editRecommendation(
      rec,
      newWeight: newWeight,
      newReps: newReps,
      repo: recRepo,
    );
    setState(() {
      _recStatuses[rec.id] = 'edited';
    });
  }

  void _copySummary(
    List<WorkoutSet> completedSets,
    Duration duration,
    double totalVolume,
    Map<String, List<WorkoutSet>> exerciseGroups,
  ) {
    final buf = StringBuffer();
    final name = widget.session.routineName.isNotEmpty
        ? widget.session.routineName
        : 'Workout';
    buf.writeln(
      '$name - ${DateFormat.yMMMd().format(widget.session.startedAt)}',
    );
    buf.writeln(
      'Duration: ${_formatDuration(duration)} | '
      'Sets: ${completedSets.length} | '
      'Volume: ${totalVolume.toStringAsFixed(0)} kg',
    );
    buf.writeln();
    for (final entry in exerciseGroups.entries) {
      final exName = entry.value.first.exerciseName;
      buf.writeln(exName);
      for (final s in entry.value) {
        final w = s.weightKg?.toStringAsFixed(1) ?? '-';
        buf.writeln('  Set ${s.setNumber}: ${s.reps ?? 0} × $w kg');
      }
    }
    buf.writeln();
    buf.writeln('Logged with RepPilot');
    Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout summary copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedSets = widget.sets
        .where((s) => s.completed && !s.isWarmup)
        .toList();
    final warmupSets = widget.sets
        .where((s) => s.isWarmup && s.completed)
        .toList();
    final duration = widget.session.duration ?? Duration.zero;
    final totalVolume = completedSets.fold<double>(
      0,
      (sum, s) => sum + ((s.weightKg ?? 0) * (s.reps ?? 0)),
    );

    final exerciseGroups = <String, List<WorkoutSet>>{};
    for (final s in completedSets) {
      (exerciseGroups[s.exerciseId] ??= []).add(s);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Complete'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy summary',
            onPressed: () => _copySummary(
              completedSets,
              duration,
              totalVolume,
              exerciseGroups,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 36,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.session.routineName.isNotEmpty
                        ? widget.session.routineName
                        : 'Workout',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMd().add_Hm().format(
                      widget.session.startedAt,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: _formatDuration(duration),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_box_outlined,
                  label: 'Sets',
                  value: '${completedSets.length}',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.fitness_center_rounded,
                  label: 'Volume',
                  value: '${totalVolume.toStringAsFixed(0)} kg',
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.whatshot_rounded,
                  label: 'Warm-up Sets',
                  value: '${warmupSets.length}',
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          if (_recs.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'PROGRESSIVE OVERLOAD',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suggestions for your next session based on today\'s performance. '
              'These are training suggestions, not medical advice.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ..._recs.map((rec) {
              final status = _recStatuses[rec.id] ?? rec.status;
              final name = _exerciseName(rec.exerciseId);
              return _RecommendationCard(
                recommendation: rec,
                exerciseName: name,
                status: status,
                onAccept: status == 'pending'
                    ? () => _acceptRecommendation(rec)
                    : null,
                onDismiss: status == 'pending'
                    ? () => _dismissRecommendation(rec)
                    : null,
                onEdit: status == 'pending'
                    ? () => _editRecommendation(rec)
                    : null,
              );
            }),
          ],
          const SizedBox(height: 24),
          Text(
            'EXERCISE BREAKDOWN',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...exerciseGroups.entries.map((entry) {
            final exerciseSets = entry.value;
            if (exerciseSets.isEmpty) return const SizedBox.shrink();
            final name = exerciseSets.first.exerciseName;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...exerciseSets.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${s.setNumber}.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(
                              '${s.weightKg?.toStringAsFixed(1) ?? '--'} kg',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'x ${s.reps ?? 0}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (s.rpe != null) ...[
                              const SizedBox(width: 12),
                              Text(
                                'RPE ${s.rpe!.toStringAsFixed(0)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${s}s';
  }
}

class _RecommendationCard extends StatelessWidget {
  final OverloadRecommendation recommendation;
  final String exerciseName;
  final String status;
  final VoidCallback? onAccept;
  final VoidCallback? onDismiss;
  final VoidCallback? onEdit;

  const _RecommendationCard({
    required this.recommendation,
    required this.exerciseName,
    required this.status,
    this.onAccept,
    this.onDismiss,
    this.onEdit,
  });

  IconData _statusIcon() {
    switch (status) {
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'dismissed':
        return Icons.cancel_rounded;
      case 'edited':
        return Icons.edit_rounded;
      default:
        return Icons.trending_up_rounded;
    }
  }

  Color _statusColor(ThemeData theme) {
    switch (status) {
      case 'accepted':
        return theme.colorScheme.primary;
      case 'dismissed':
        return theme.colorScheme.outline;
      case 'edited':
        return theme.colorScheme.tertiary;
      default:
        return theme.colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rec = recommendation;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon(), size: 20, color: _statusColor(theme)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exerciseName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (status != 'pending')
                  Chip(
                    label: Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: theme.textTheme.labelSmall,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              rec.reasoning,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (rec.recommendedWeightKg != null ||
                rec.recommendedReps != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (rec.previousWeightKg != null)
                    Text(
                      '${rec.previousWeightKg!.toStringAsFixed(1)} kg',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (rec.previousWeightKg != null &&
                      rec.recommendedWeightKg != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  if (rec.recommendedWeightKg != null)
                    Text(
                      '${rec.recommendedWeightKg!.toStringAsFixed(1)} kg',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  if (rec.recommendedReps != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      'x ${rec.recommendedReps} reps',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Dismiss'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onAccept,
                    child: const Text('Accept'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
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
