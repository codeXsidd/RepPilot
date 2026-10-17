import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise.dart';
import '../../repositories/exercise_repository.dart';
import '../../theme/app_theme.dart';
import '../progress/exercise_history_screen.dart';
import 'exercise_settings_screen.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late Exercise _exercise;

  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
  }

  Future<void> _toggleFavorite() async {
    final repo = context.read<ExerciseRepository>();
    await repo.toggleFavorite(_exercise.id);
    final updated = await repo.getById(_exercise.id);
    if (updated != null && mounted) {
      setState(() => _exercise = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Details'),
        actions: [
          IconButton(
            icon: Icon(
              _exercise.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: _exercise.isFavorite ? AppColors.warning : null,
            ),
            tooltip: _exercise.isFavorite ? 'Remove Favorite' : 'Add Favorite',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Overload Settings',
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => ExerciseSettingsScreen(
                    exerciseId: _exercise.id,
                    exerciseName: _exercise.name,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Text(
            _exercise.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Chip(
                label: _capitalize(_exercise.category),
                color: cs.primary.withValues(alpha: 0.12),
                textColor: cs.primary,
              ),
              if (_exercise.difficulty.isNotEmpty)
                _Chip(
                  label: _capitalize(_exercise.difficulty),
                  color: _difficultyColor().withValues(alpha: 0.12),
                  textColor: _difficultyColor(),
                ),
              if (_exercise.equipment.isNotEmpty)
                _Chip(
                  label: _equipmentLabel(_exercise.equipment),
                  color: cs.onSurface.withValues(alpha: 0.08),
                  textColor: cs.onSurfaceVariant,
                ),
              if (_exercise.isBodyweight)
                _Chip(
                  label: 'Bodyweight',
                  color: cs.tertiary.withValues(alpha: 0.12),
                  textColor: cs.tertiary,
                ),
              if (_exercise.suitableForHome)
                _Chip(
                  label: 'Home',
                  color: cs.secondary.withValues(alpha: 0.12),
                  textColor: cs.secondary,
                ),
            ],
          ),

          if (_exercise.description.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionTitle(text: 'DESCRIPTION'),
            const SizedBox(height: 6),
            Text(_exercise.description, style: theme.textTheme.bodyMedium),
          ],

          const SizedBox(height: 24),
          const _SectionTitle(text: 'TARGET MUSCLES'),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Primary',
            value: _exercise.muscleGroup.isNotEmpty
                ? _exercise.muscleGroup
                : 'Not specified',
          ),
          if (_exercise.secondaryMuscles.isNotEmpty)
            _InfoRow(label: 'Secondary', value: _exercise.secondaryMuscles),

          if (_exercise.instructions.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionTitle(text: 'HOW TO PERFORM'),
            const SizedBox(height: 8),
            Text(
              _exercise.instructions,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],

          if (_exercise.safetyNotes.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionTitle(text: 'SAFETY NOTES'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _exercise.safetyNotes,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          const _SectionTitle(text: 'DEFAULT PROGRAMMING'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                children: [
                  _ProgramRow(label: 'Sets', value: '${_exercise.defaultSets}'),
                  _ProgramRow(
                    label: 'Rep Range',
                    value:
                        '${_exercise.defaultRepsMin}–${_exercise.defaultRepsMax}',
                  ),
                  _ProgramRow(
                    label: 'Rest',
                    value: '${_exercise.defaultRestSeconds}s',
                  ),
                  if (!_exercise.isBodyweight)
                    _ProgramRow(
                      label: 'Increment',
                      value: '${_exercise.defaultIncrementKg} kg',
                    ),
                ],
              ),
            ),
          ),

          if (_exercise.movementPattern.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionTitle(text: 'MOVEMENT INFO'),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Pattern',
              value: _capitalize(_exercise.movementPattern),
            ),
            if (_exercise.isUnilateral)
              const _InfoRow(label: 'Type', value: 'Unilateral (single-side)'),
          ],

          if (_exercise.notes.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionTitle(text: 'NOTES'),
            const SizedBox(height: 6),
            Text(_exercise.notes, style: theme.textTheme.bodyMedium),
          ],

          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => ExerciseHistoryScreen(
                    exerciseId: _exercise.id,
                    exerciseName: _exercise.name,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.show_chart_rounded),
            label: const Text('View History & Progression'),
          ),

          if (!_exercise.isCustom) ...[
            const SizedBox(height: 16),
            Text(
              'Built-in exercise',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _difficultyColor() {
    return switch (_exercise.difficulty) {
      'beginner' => AppColors.success,
      'advanced' => AppColors.warning,
      _ => AppColors.primaryBlue,
    };
  }

  static String _capitalize(String s) => s.isEmpty
      ? s
      : '${s[0].toUpperCase()}${s.substring(1).replaceAll('_', ' ')}';

  static String _equipmentLabel(String equip) =>
      equip.replaceAll('_', ' ').split(' ').map(_capitalize).join(' ');
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Chip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.0,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _ProgramRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProgramRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
