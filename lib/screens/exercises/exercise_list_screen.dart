import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/default_exercises.dart';
import '../../models/exercise.dart';
import '../../repositories/exercise_repository.dart';
import '../../widgets/empty_state.dart';
import 'exercise_form_screen.dart';

class ExerciseListScreen extends StatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  List<Exercise> _exercises = [];
  String _searchQuery = '';
  String? _selectedCategory;
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    final repo = context.read<ExerciseRepository>();

    List<Exercise> exercises;
    if (_searchQuery.isNotEmpty) {
      exercises = await repo.search(_searchQuery);
    } else if (_selectedCategory != null) {
      exercises = await repo.getByCategory(_selectedCategory!);
    } else {
      exercises = await repo.getAll();
    }

    if (_searchQuery.isNotEmpty && _selectedCategory != null) {
      exercises = exercises
          .where((e) => e.category == _selectedCategory)
          .toList();
    }

    if (!mounted) return;
    setState(() {
      _exercises = exercises;
      _loading = false;
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _loadExercises();
  }

  void _onCategorySelected(String? category) {
    setState(() => _selectedCategory = category);
    _loadExercises();
  }

  Future<void> _navigateToForm({Exercise? exercise}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ExerciseFormScreen(exercise: exercise)),
    );
    if (result == true) _loadExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Library')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(height: 12),
          _CategoryChips(
            categories: exerciseCategories,
            selected: _selectedCategory,
            onSelected: _onCategorySelected,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _exercises.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'No Exercises Found',
                    description:
                        'Try a different search or category filter, '
                        'or create a custom exercise.',
                  )
                : RefreshIndicator(
                    onRefresh: _loadExercises,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _exercises.length,
                      itemBuilder: (context, index) {
                        return _ExerciseListItem(
                          exercise: _exercises[index],
                          onTap: () =>
                              _navigateToForm(exercise: _exercises[index]),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        tooltip: 'New Exercise',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_capitalize(cat)),
                selected: selected == cat,
                onSelected: (_) => onSelected(selected == cat ? null : cat),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _ExerciseListItem extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _ExerciseListItem({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          exercise.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          [
            _capitalize(exercise.category),
            if (exercise.muscleGroup.isNotEmpty) exercise.muscleGroup,
            if (exercise.equipment.isNotEmpty)
              _equipmentLabel(exercise.equipment),
          ].join(' • '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: exercise.isCustom
            ? Icon(Icons.person, size: 18, color: theme.colorScheme.primary)
            : null,
        onTap: onTap,
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static String _equipmentLabel(String equip) {
    return equip.replaceAll('_', ' ').split(' ').map(_capitalize).join(' ');
  }
}
