import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../core/data/default_exercises.dart';
import '../../models/exercise.dart';
import '../../repositories/exercise_repository.dart';
import 'exercise_detail_screen.dart';

const _muscleGroupSvgMap = <String, String>{
  'chest': 'assets/images/muscle_groups/chest.svg',
  'back': 'assets/images/muscle_groups/back.svg',
  'shoulders': 'assets/images/muscle_groups/shoulders.svg',
  'biceps': 'assets/images/muscle_groups/biceps.svg',
  'triceps': 'assets/images/muscle_groups/triceps.svg',
  'forearms': 'assets/images/muscle_groups/forearms.svg',
  'legs': 'assets/images/muscle_groups/legs.svg',
  'glutes': 'assets/images/muscle_groups/glutes.svg',
  'calves': 'assets/images/muscle_groups/calves.svg',
  'core': 'assets/images/muscle_groups/core.svg',
  'full_body': 'assets/images/muscle_groups/full_body.svg',
  'mobility': 'assets/images/muscle_groups/mobility.svg',
};

class MuscleGroupExplorerScreen extends StatefulWidget {
  const MuscleGroupExplorerScreen({super.key});

  @override
  State<MuscleGroupExplorerScreen> createState() =>
      _MuscleGroupExplorerScreenState();
}

class _MuscleGroupExplorerScreenState extends State<MuscleGroupExplorerScreen> {
  String? _selectedGroup;
  List<Exercise> _exercises = [];
  bool _loading = false;

  Future<void> _selectGroup(String group) async {
    setState(() {
      _selectedGroup = group;
      _loading = true;
    });

    final repo = context.read<ExerciseRepository>();
    final exercises = await repo.getFiltered(category: group);

    if (!mounted) return;
    setState(() {
      _exercises = exercises;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Muscle Groups'),
        actions: [
          if (_selectedGroup != null)
            IconButton(
              icon: const Icon(Icons.grid_view),
              tooltip: 'Show all groups',
              onPressed: () => setState(() {
                _selectedGroup = null;
                _exercises = [];
              }),
            ),
        ],
      ),
      body: _selectedGroup == null ? _buildGrid(theme) : _buildDetail(theme),
    );
  }

  Widget _buildGrid(ThemeData theme) {
    final groups = exerciseCategories;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _MuscleCard(
          group: group,
          svgPath: _muscleGroupSvgMap[group],
          onTap: () => _selectGroup(group),
        );
      },
    );
  }

  Widget _buildDetail(ThemeData theme) {
    final group = _selectedGroup!;
    final svgPath = _muscleGroupSvgMap[group];

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: theme.colorScheme.surfaceContainerLow,
          child: Column(
            children: [
              if (svgPath != null)
                SvgPicture.asset(
                  svgPath,
                  height: 100,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                _formatGroupName(group),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!_loading)
                Text(
                  '${_exercises.length} exercises',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: _exercises.isEmpty
                ? Center(
                    child: Text(
                      'No exercises in this category',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _exercises.length,
                    itemBuilder: (context, index) {
                      final ex = _exercises[index];
                      return _ExerciseTile(
                        exercise: ex,
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExerciseDetailScreen(exercise: ex),
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  static String _formatGroupName(String group) => group
      .split('_')
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _MuscleCard extends StatelessWidget {
  final String group;
  final String? svgPath;
  final VoidCallback onTap;

  const _MuscleCard({
    required this.group,
    required this.svgPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: svgPath != null
                    ? SvgPicture.asset(
                        svgPath!,
                        colorFilter: ColorFilter.mode(
                          theme.colorScheme.primary.withAlpha(180),
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(
                        Icons.fitness_center,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                _MuscleGroupExplorerScreenState._formatGroupName(group),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _ExerciseTile({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diffColor = switch (exercise.difficulty) {
      'beginner' => Colors.green,
      'advanced' => Colors.orange,
      _ => theme.colorScheme.primary,
    };

    return ListTile(
      title: Text(exercise.name),
      subtitle: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: diffColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            exercise.difficulty.isNotEmpty
                ? exercise.difficulty[0].toUpperCase() +
                      exercise.difficulty.substring(1)
                : '',
            style: theme.textTheme.bodySmall,
          ),
          if (exercise.equipment.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              exercise.equipment.replaceAll('_', ' '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      trailing: exercise.isFavorite
          ? const Icon(Icons.star, size: 18, color: Colors.amber)
          : null,
      onTap: onTap,
    );
  }
}
