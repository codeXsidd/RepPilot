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
  String? _specialFilter;
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

    if (_specialFilter == 'recent') {
      exercises = await repo.getRecentlyUsed(limit: 30);
    } else if (_specialFilter == 'favorites') {
      exercises = await repo.getFavorites();
    } else {
      exercises = await repo.getFiltered(
        category: _selectedCategory,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
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
    if (query.isNotEmpty) {
      _specialFilter = null;
      _selectedCategory = null;
    }
    _loadExercises();
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
      _specialFilter = null;
    });
    _loadExercises();
  }

  void _onSpecialFilterSelected(String filter) {
    setState(() {
      _specialFilter = _specialFilter == filter ? null : filter;
      _selectedCategory = null;
      _searchQuery = '';
      _searchController.clear();
    });
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
                  icon: const Icon(Icons.check_rounded),
                  tooltip: 'Done',
                  onPressed: _done,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded),
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
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
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
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: const Icon(Icons.history_rounded, size: 16),
                    label: const Text('Recent'),
                    selected: _specialFilter == 'recent',
                    onSelected: (_) => _onSpecialFilterSelected('recent'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: const Icon(Icons.star_rounded, size: 16),
                    label: const Text('Favorites'),
                    selected: _specialFilter == 'favorites',
                    onSelected: (_) => _onSpecialFilterSelected('favorites'),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.only(right: 8),
                  color: theme.colorScheme.outlineVariant,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All'),
                    selected:
                        _selectedCategory == null && _specialFilter == null,
                    onSelected: (_) => _onCategorySelected(null),
                  ),
                ),
                ...exerciseCategories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_formatLabel(cat)),
                      selected: _selectedCategory == cat,
                      onSelected: (_) => _onCategorySelected(
                        _selectedCategory == cat ? null : cat,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _exercises.isEmpty
                ? EmptyState(
                    icon: _specialFilter == 'recent'
                        ? Icons.history_rounded
                        : _specialFilter == 'favorites'
                        ? Icons.star_border_rounded
                        : Icons.search_off_rounded,
                    title: _specialFilter == 'recent'
                        ? 'No Recent Exercises'
                        : _specialFilter == 'favorites'
                        ? 'No Favorites Yet'
                        : 'No Exercises Found',
                    description: _specialFilter == 'recent'
                        ? 'Complete a workout to see exercises here.'
                        : _specialFilter == 'favorites'
                        ? 'Star exercises to find them quickly.'
                        : 'Try a different search or category filter.',
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
                              _formatLabel(exercise.category),
                              if (exercise.muscleGroup.isNotEmpty)
                                exercise.muscleGroup,
                              if (exercise.difficulty.isNotEmpty)
                                _formatLabel(exercise.difficulty),
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

  static String _formatLabel(String s) {
    if (s.isEmpty) return s;
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
