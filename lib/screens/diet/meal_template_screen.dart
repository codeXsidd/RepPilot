import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/food.dart';
import '../../models/food_entry.dart';
import '../../models/meal_template.dart';
import '../../models/meal_template_item.dart';
import '../../repositories/food_entry_repository.dart';
import '../../repositories/food_repository.dart';
import '../../repositories/meal_template_item_repository.dart';
import '../../repositories/meal_template_repository.dart';
import '../../widgets/empty_state.dart';
import 'food_search_screen.dart';

const _mealLabels = {
  'breakfast': 'Breakfast',
  'lunch': 'Lunch',
  'dinner': 'Dinner',
  'snack': 'Snack',
};

class MealTemplateScreen extends StatefulWidget {
  final DateTime date;

  const MealTemplateScreen({super.key, required this.date});

  @override
  State<MealTemplateScreen> createState() => _MealTemplateScreenState();
}

class _MealTemplateScreenState extends State<MealTemplateScreen> {
  List<MealTemplate> _templates = [];
  final Map<String, List<_TemplateItemWithFood>> _templateItems = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final templateRepo = context.read<MealTemplateRepository>();
    final itemRepo = context.read<MealTemplateItemRepository>();
    final foodRepo = context.read<FoodRepository>();

    final templates = await templateRepo.getAll();
    final itemsMap = <String, List<_TemplateItemWithFood>>{};
    for (final t in templates) {
      final items = await itemRepo.getByTemplateId(t.id);
      final withFood = <_TemplateItemWithFood>[];
      for (final item in items) {
        final food = await foodRepo.getById(item.foodId);
        if (food != null) {
          withFood.add(_TemplateItemWithFood(item: item, food: food));
        }
      }
      itemsMap[t.id] = withFood;
    }

    if (!mounted) return;
    setState(() {
      _templates = templates;
      _templateItems
        ..clear()
        ..addAll(itemsMap);
      _loading = false;
    });
  }

  Future<void> _useTemplate(MealTemplate template) async {
    final items = _templateItems[template.id] ?? [];
    if (items.isEmpty) return;

    final foodRepo = context.read<FoodEntryRepository>();
    final now = DateTime.now();
    for (final entry in items) {
      final food = entry.food;
      final servings = entry.item.servings;
      await foodRepo.create(
        FoodEntry(
          id: generateId(),
          date: widget.date,
          mealType: template.mealType,
          description:
              '${food.name} (${servings.toStringAsFixed(1)} ${food.servingUnit})',
          calories: food.caloriesFor(servings),
          proteinGrams: food.proteinFor(servings),
          carbsGrams: food.carbsFor(servings),
          fatGrams: food.fatFor(servings),
          notes: food.isEstimate ? 'Nutrition values are estimates' : '',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${items.length} items from "${template.name}"'),
      ),
    );
    Navigator.pop(context, true);
  }

  Future<void> _deleteTemplate(MealTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<MealTemplateRepository>().delete(template.id);
    _loadData();
  }

  Future<void> _createTemplate() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _TemplateFormScreen()),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Templates')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
          ? const EmptyState(
              icon: Icons.book_rounded,
              title: 'No Templates',
              description:
                  'Create meal templates to quickly log your regular meals.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _templates.length,
              itemBuilder: (_, i) {
                final t = _templates[i];
                final items = _templateItems[t.id] ?? [];
                final totalCal = items.fold<double>(
                  0,
                  (sum, e) => sum + e.food.caloriesFor(e.item.servings),
                );
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _useTemplate(t),
                    onLongPress: () => _deleteTemplate(t),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _mealLabels[t.mealType] ?? t.mealType,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${items.length} items  '
                            '${totalCal.toStringAsFixed(0)} kcal',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (items.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              items.map((e) => e.food.name).join(', '),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTemplate,
        tooltip: 'New Template',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _TemplateItemWithFood {
  final MealTemplateItem item;
  final Food food;
  const _TemplateItemWithFood({required this.item, required this.food});
}

class _TemplateFormScreen extends StatefulWidget {
  const _TemplateFormScreen();

  @override
  State<_TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends State<_TemplateFormScreen> {
  final _nameCtrl = TextEditingController();
  String _mealType = 'breakfast';
  final List<_PendingItem> _items = [];
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addFood() async {
    final food = await Navigator.push<Food>(
      context,
      MaterialPageRoute(builder: (_) => const FoodSearchScreen()),
    );
    if (food == null) return;
    setState(() => _items.add(_PendingItem(food: food, servings: 1)));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (_saving) return;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a template name')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one food item')),
      );
      return;
    }
    setState(() => _saving = true);

    try {
      final templateRepo = context.read<MealTemplateRepository>();
      final itemRepo = context.read<MealTemplateItemRepository>();
      final now = DateTime.now();
      final templateId = generateId();

      await templateRepo.create(
        MealTemplate(
          id: templateId,
          name: name,
          mealType: _mealType,
          createdAt: now,
          updatedAt: now,
        ),
      );

      for (final item in _items) {
        await itemRepo.create(
          MealTemplateItem(
            id: generateId(),
            templateId: templateId,
            foodId: item.food.id,
            servings: item.servings,
            createdAt: now,
          ),
        );
      }

      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Template'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Template Name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _mealType,
            decoration: const InputDecoration(
              labelText: 'Meal Type',
              border: OutlineInputBorder(),
            ),
            items: _mealLabels.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _mealType = v);
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Foods',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: _addFood,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          for (var i = 0; i < _items.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_items[i].food.name),
              subtitle: Text(
                '${_items[i].food.caloriesFor(_items[i].servings).toStringAsFixed(0)} kcal'
                '  (${_items[i].servings} ${_items[i].food.servingUnit})',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 60,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Qty',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      controller: TextEditingController(
                        text: _items[i].servings.toString(),
                      ),
                      onChanged: (v) {
                        final s = double.tryParse(v);
                        if (s != null && s > 0) {
                          setState(
                            () => _items[i] = _PendingItem(
                              food: _items[i].food,
                              servings: s,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => setState(() => _items.removeAt(i)),
                  ),
                ],
              ),
            ),
          if (_items.isNotEmpty) ...[
            const Divider(),
            Text(
              'Total: ${_items.fold<double>(0, (sum, e) => sum + e.food.caloriesFor(e.servings)).toStringAsFixed(0)} kcal',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PendingItem {
  final Food food;
  final double servings;
  const _PendingItem({required this.food, required this.servings});
}
