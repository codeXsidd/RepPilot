import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/food.dart';
import '../../models/food_entry.dart';
import '../../repositories/food_entry_repository.dart';
import '../../repositories/food_repository.dart';

const _mealOptions = ['breakfast', 'lunch', 'dinner', 'snack'];
const _mealLabels = {
  'breakfast': 'Breakfast',
  'lunch': 'Lunch',
  'dinner': 'Dinner',
  'snack': 'Snack',
};

class FoodLogForm extends StatefulWidget {
  final DateTime date;
  final String initialMealType;
  final FoodEntry? existingEntry;

  const FoodLogForm({
    super.key,
    required this.date,
    this.initialMealType = 'snack',
    this.existingEntry,
  });

  @override
  State<FoodLogForm> createState() => _FoodLogFormState();
}

class _FoodLogFormState extends State<FoodLogForm> {
  late String _mealType;
  Food? _selectedFood;
  List<Food> _searchResults = [];
  bool _quickAdd = false;
  bool _saving = false;

  final _searchController = TextEditingController();
  final _servingsController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    _mealType = widget.existingEntry?.mealType ?? widget.initialMealType;
    if (_isEditing) {
      final entry = widget.existingEntry!;
      _quickAdd = true;
      _descriptionController.text = entry.description;
      _caloriesController.text = entry.calories?.toStringAsFixed(0) ?? '';
      _proteinController.text = entry.proteinGrams?.toStringAsFixed(0) ?? '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _servingsController.dispose();
    _descriptionController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final repo = context.read<FoodRepository>();
    final results = await repo.search(query);
    if (!mounted) return;
    setState(() => _searchResults = results);
  }

  void _selectFood(Food food) {
    setState(() {
      _selectedFood = food;
      _searchResults = [];
      _searchController.text = food.name;
      _servingsController.text = '1';
    });
  }

  double? _parsePositive(String text) {
    final v = double.tryParse(text);
    if (v == null || v < 0) return null;
    return v;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final repo = context.read<FoodEntryRepository>();
      final now = DateTime.now();

      if (_isEditing) {
        final entry = widget.existingEntry!;
        final updated = entry.copyWith(
          mealType: _mealType,
          description: _descriptionController.text.trim(),
          calories: _parsePositive(_caloriesController.text),
          proteinGrams: _parsePositive(_proteinController.text),
          updatedAt: now,
        );
        await repo.update(updated);
      } else if (_quickAdd) {
        final desc = _descriptionController.text.trim();
        if (desc.isEmpty) {
          _showError('Please enter a description.');
          return;
        }
        final calories = _parsePositive(_caloriesController.text);
        final protein = _parsePositive(_proteinController.text);

        final entry = FoodEntry(
          id: generateId(),
          date: widget.date,
          mealType: _mealType,
          description: desc,
          calories: calories,
          proteinGrams: protein,
          createdAt: now,
          updatedAt: now,
        );
        await repo.create(entry);
      } else {
        if (_selectedFood == null) {
          _showError('Please select a food or use quick add.');
          return;
        }
        final servings = double.tryParse(_servingsController.text);
        if (servings == null || servings <= 0) {
          _showError('Servings must be greater than zero.');
          return;
        }
        final food = _selectedFood!;
        final entry = FoodEntry(
          id: generateId(),
          date: widget.date,
          mealType: _mealType,
          description:
              '${food.name} (${servings.toStringAsFixed(1)} ${food.servingUnit})',
          calories: food.caloriesFor(servings),
          proteinGrams: food.proteinFor(servings),
          carbsGrams: food.carbsFor(servings),
          fatGrams: food.fatFor(servings),
          notes: food.isEstimate ? 'Nutrition values are estimates' : '',
          createdAt: now,
          updatedAt: now,
        );
        await repo.create(entry);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit Entry' : 'Log Food',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: _mealOptions
                    .map(
                      (m) =>
                          ButtonSegment(value: m, label: Text(_mealLabels[m]!)),
                    )
                    .toList(),
                selected: {_mealType},
                onSelectionChanged: (s) => setState(() => _mealType = s.first),
              ),
              const SizedBox(height: 12),
              if (!_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Search Food'),
                        selected: !_quickAdd,
                        onSelected: (_) => setState(() => _quickAdd = false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Quick Add'),
                        selected: _quickAdd,
                        onSelected: (_) => setState(() => _quickAdd = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (_quickAdd || _isEditing) ...[
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _caloriesController,
                        decoration: const InputDecoration(
                          labelText: 'Calories (kcal)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _proteinController,
                        decoration: const InputDecoration(
                          labelText: 'Protein (g)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search foods',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _search,
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (_, i) {
                        final food = _searchResults[i];
                        return ListTile(
                          dense: true,
                          title: Text(food.name),
                          subtitle: Text(
                            '${food.caloriesPerServing.toStringAsFixed(0)} kcal'
                            ' per ${food.servingSize} ${food.servingUnit}'
                            '${food.isEstimate ? ' (estimate)' : ''}',
                          ),
                          trailing: food.isFavorite
                              ? Icon(
                                  Icons.favorite_rounded,
                                  size: 16,
                                  color: theme.colorScheme.error,
                                )
                              : null,
                          onTap: () => _selectFood(food),
                        );
                      },
                    ),
                  ),
                if (_selectedFood != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFood!.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_selectedFood!.isEstimate)
                            Text(
                              'Nutrition values are estimates',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _servingsController,
                            decoration: InputDecoration(
                              labelText:
                                  'Servings (${_selectedFood!.servingSize} ${_selectedFood!.servingUnit} each)',
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (_) {
                              final s =
                                  double.tryParse(_servingsController.text) ??
                                  0;
                              final food = _selectedFood!;
                              return Text(
                                '${food.caloriesFor(s).toStringAsFixed(0)} kcal  '
                                '${food.proteinFor(s).toStringAsFixed(0)}g P  '
                                '${food.carbsFor(s).toStringAsFixed(0)}g C  '
                                '${food.fatFor(s).toStringAsFixed(0)}g F',
                                style: theme.textTheme.bodySmall,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_isEditing ? 'Update' : 'Log'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
