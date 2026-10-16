import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/default_exercises.dart';
import '../../models/exercise.dart';
import '../../repositories/exercise_repository.dart';
import '../../widgets/empty_state.dart';

class ExercisePickerScreen extends StatefulWidget {
  final List<String> excludeIds;

  const ExercisePickerScreen({super.key, this.excludeIds = const []});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  List<Exercise> _exercises = [];
  final Set<String> _selectedIds = {};
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

    exercises = exercises
        .where((e) => !widget.excludeIds.contains(e.id))
        .toList();

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

  void _toggleExercise(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _done() {
    final selected = _exercises
        .where((e) => _selectedIds.contains(e.id))
        .toList();
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Exercises'),
        actions: [
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Badge(
                label: Text('${_selectedIds.length}'),
                child: IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Done',
                  onPressed: _done,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Done',
              onPressed: _done,
            ),
        ],
      ),
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
                    description: 'Try a different search or category filter.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _exercises[index];
                      final isSelected = _selectedIds.contains(exercise.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (_) => _toggleExercise(exercise.id),
                          title: Text(
                            exercise.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            [
                              _capitalize(exercise.category),
                              if (exercise.muscleGroup.isNotEmpty)
                                exercise.muscleGroup,
                            ].join(' • '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
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
