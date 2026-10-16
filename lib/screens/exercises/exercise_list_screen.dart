import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/default_exercises.dart';
import '../../models/exercise.dart';
import '../../repositories/exercise_repository.dart';
import '../../widgets/empty_state.dart';
import 'exercise_detail_screen.dart';
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
  String? _selectedEquipment;
  String? _selectedDifficulty;
  bool _showFavoritesOnly = false;
  bool _showHomeOnly = false;
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
    final exercises = await repo.getFiltered(
      category: _selectedCategory,
      equipment: _selectedEquipment,
      difficulty: _selectedDifficulty,
      suitableForHome: _showHomeOnly ? true : null,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      favoritesOnly: _showFavoritesOnly,
    );

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

  Future<void> _navigateToDetail(Exercise exercise) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(exercise: exercise),
      ),
    );
    _loadExercises();
  }

  Future<void> _navigateToForm({Exercise? exercise}) async {
    if (exercise != null && !exercise.isCustom) {
      await _navigateToDetail(exercise);
      return;
    }
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ExerciseFormScreen(exercise: exercise)),
    );
    if (result == true) _loadExercises();
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _FilterSheet(
        selectedEquipment: _selectedEquipment,
        selectedDifficulty: _selectedDifficulty,
        showFavoritesOnly: _showFavoritesOnly,
        showHomeOnly: _showHomeOnly,
        onApply: (equipment, difficulty, favorites, home) {
          Navigator.pop(ctx);
          setState(() {
            _selectedEquipment = equipment;
            _selectedDifficulty = difficulty;
            _showFavoritesOnly = favorites;
            _showHomeOnly = home;
          });
          _loadExercises();
        },
      ),
    );
  }

  int get _activeFilterCount {
    var count = 0;
    if (_selectedEquipment != null) count++;
    if (_selectedDifficulty != null) count++;
    if (_showFavoritesOnly) count++;
    if (_showHomeOnly) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [
          Badge(
            isLabelVisible: _activeFilterCount > 0,
            label: Text('$_activeFilterCount'),
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filters',
              onPressed: _showFilterSheet,
            ),
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
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_exercises.length} exercise${_exercises.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (_activeFilterCount > 0)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedEquipment = null;
                        _selectedDifficulty = null;
                        _showFavoritesOnly = false;
                        _showHomeOnly = false;
                      });
                      _loadExercises();
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear Filters'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _exercises.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'No Exercises Found',
                    description:
                        'Try a different search or filter combination, '
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
                          onTap: () => _navigateToDetail(_exercises[index]),
                          onEdit: _exercises[index].isCustom
                              ? () =>
                                    _navigateToForm(exercise: _exercises[index])
                              : null,
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
                label: Text(_formatLabel(cat)),
                selected: selected == cat,
                onSelected: (_) => onSelected(selected == cat ? null : cat),
              ),
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

class _ExerciseListItem extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _ExerciseListItem({
    required this.exercise,
    required this.onTap,
    this.onEdit,
  });

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
            _formatLabel(exercise.category),
            if (exercise.muscleGroup.isNotEmpty) exercise.muscleGroup,
            if (exercise.equipment.isNotEmpty)
              _equipmentLabel(exercise.equipment),
          ].join(' • '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        leading: _difficultyDot(theme),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (exercise.isFavorite)
              const Icon(Icons.star, size: 16, color: Colors.amber),
            if (exercise.isCustom)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
        onTap: onTap,
        onLongPress: onEdit,
      ),
    );
  }

  Widget _difficultyDot(ThemeData theme) {
    final color = switch (exercise.difficulty) {
      'beginner' => Colors.green,
      'advanced' => Colors.orange,
      _ => theme.colorScheme.primary,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

  static String _equipmentLabel(String equip) => _formatLabel(equip);
}

class _FilterSheet extends StatefulWidget {
  final String? selectedEquipment;
  final String? selectedDifficulty;
  final bool showFavoritesOnly;
  final bool showHomeOnly;
  final void Function(
    String? equipment,
    String? difficulty,
    bool favorites,
    bool home,
  )
  onApply;

  const _FilterSheet({
    required this.selectedEquipment,
    required this.selectedDifficulty,
    required this.showFavoritesOnly,
    required this.showHomeOnly,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _equipment;
  late String? _difficulty;
  late bool _favorites;
  late bool _home;

  @override
  void initState() {
    super.initState();
    _equipment = widget.selectedEquipment;
    _difficulty = widget.selectedDifficulty;
    _favorites = widget.showFavoritesOnly;
    _home = widget.showHomeOnly;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filters', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Text(
              'DIFFICULTY',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final d in difficultyLevels)
                  FilterChip(
                    label: Text(_formatLabel(d)),
                    selected: _difficulty == d,
                    onSelected: (_) => setState(
                      () => _difficulty = _difficulty == d ? null : d,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'EQUIPMENT',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final e in equipmentTypes)
                  FilterChip(
                    label: Text(_formatLabel(e)),
                    selected: _equipment == e,
                    onSelected: (_) =>
                        setState(() => _equipment = _equipment == e ? null : e),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Favorites Only'),
              value: _favorites,
              onChanged: (v) => setState(() => _favorites = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Home Workout Suitable'),
              value: _home,
              onChanged: (v) => setState(() => _home = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () =>
                  widget.onApply(_equipment, _difficulty, _favorites, _home),
              child: const Text('Apply Filters'),
            ),
          ],
        ),
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
