import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise.dart';
import '../../repositories/exercise_repository.dart';
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
              _exercise.isFavorite ? Icons.star : Icons.star_border,
              color: _exercise.isFavorite ? Colors.amber : null,
            ),
            tooltip: _exercise.isFavorite ? 'Remove Favorite' : 'Add Favorite',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.tune),
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
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _exercise.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _Chip(
                label: _capitalize(_exercise.category),
                color: cs.primaryContainer,
                textColor: cs.onPrimaryContainer,
              ),
              if (_exercise.difficulty.isNotEmpty)
                _Chip(
                  label: _capitalize(_exercise.difficulty),
                  color: _difficultyColor(cs),
                  textColor: _difficultyTextColor(cs),
                ),
              if (_exercise.equipment.isNotEmpty)
                _Chip(
                  label: _equipmentLabel(_exercise.equipment),
                  color: cs.surfaceContainerHighest,
                  textColor: cs.onSurface,
                ),
              if (_exercise.isBodyweight)
                _Chip(
                  label: 'Bodyweight',
                  color: cs.tertiaryContainer,
                  textColor: cs.onTertiaryContainer,
                ),
              if (_exercise.suitableForHome)
                _Chip(
                  label: 'Home',
                  color: cs.secondaryContainer,
                  textColor: cs.onSecondaryContainer,
                ),
            ],
          ),

          if (_exercise.description.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle(text: 'DESCRIPTION'),
            const SizedBox(height: 4),
            Text(_exercise.description, style: theme.textTheme.bodyMedium),
          ],

          const SizedBox(height: 20),
          _SectionTitle(text: 'TARGET MUSCLES'),
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
            const SizedBox(height: 20),
            _SectionTitle(text: 'HOW TO PERFORM'),
            const SizedBox(height: 8),
            Text(_exercise.instructions, style: theme.textTheme.bodyMedium),
          ],

          if (_exercise.safetyNotes.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle(text: 'SAFETY NOTES'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withAlpha(50),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.error.withAlpha(60)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, size: 20, color: cs.error),
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

          const SizedBox(height: 20),
          _SectionTitle(text: 'DEFAULT PROGRAMMING'),
          const SizedBox(height: 8),
          _InfoRow(label: 'Sets', value: '${_exercise.defaultSets}'),
          _InfoRow(
            label: 'Rep Range',
            value: '${_exercise.defaultRepsMin}-${_exercise.defaultRepsMax}',
          ),
          _InfoRow(label: 'Rest', value: '${_exercise.defaultRestSeconds}s'),
          if (!_exercise.isBodyweight)
            _InfoRow(
              label: 'Increment',
              value: '${_exercise.defaultIncrementKg} kg',
            ),

          if (_exercise.movementPattern.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle(text: 'MOVEMENT INFO'),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Pattern',
              value: _capitalize(_exercise.movementPattern),
            ),
            if (_exercise.isUnilateral)
              _InfoRow(label: 'Type', value: 'Unilateral (single-side)'),
          ],

          if (_exercise.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle(text: 'NOTES'),
            const SizedBox(height: 4),
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
            icon: const Icon(Icons.show_chart),
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

  Color _difficultyColor(ColorScheme cs) {
    return switch (_exercise.difficulty) {
      'beginner' => Colors.green.withAlpha(40),
      'advanced' => Colors.orange.withAlpha(40),
      _ => cs.surfaceContainerHighest,
    };
  }

  Color _difficultyTextColor(ColorScheme cs) {
    return switch (_exercise.difficulty) {
      'beginner' => Colors.green.shade800,
      'advanced' => Colors.orange.shade800,
      _ => cs.onSurface,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
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
        letterSpacing: 0.5,
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
