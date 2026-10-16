import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/food_entry.dart';
import '../../models/personal_goal.dart';
import '../../models/water_entry.dart';
import '../../repositories/food_entry_repository.dart';
import '../../repositories/personal_goal_repository.dart';
import '../../repositories/water_entry_repository.dart';
import 'food_log_form.dart';
import 'food_search_screen.dart';
import 'meal_template_screen.dart';
import 'weekly_summary.dart';

const _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
const _mealLabels = {
  'breakfast': 'Breakfast',
  'lunch': 'Lunch',
  'dinner': 'Dinner',
  'snack': 'Snacks',
};
const _mealIcons = {
  'breakfast': Icons.wb_sunny_outlined,
  'lunch': Icons.wb_cloudy_outlined,
  'dinner': Icons.nightlight_outlined,
  'snack': Icons.cookie_outlined,
};

class NutritionDashboard extends StatefulWidget {
  const NutritionDashboard({super.key});

  @override
  State<NutritionDashboard> createState() => _NutritionDashboardState();
}

class _NutritionDashboardState extends State<NutritionDashboard> {
  DateTime _selectedDate = stripTime(DateTime.now());
  Map<String, List<FoodEntry>> _mealEntries = {};
  List<WaterEntry> _waterEntries = [];
  int _waterTotalMl = 0;
  double _caloriesTotal = 0;
  double _proteinTotal = 0;
  double _carbsTotal = 0;
  double _fatTotal = 0;
  double? _calorieGoal;
  double? _proteinGoal;
  double? _waterGoalMl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final foodRepo = context.read<FoodEntryRepository>();
    final waterRepo = context.read<WaterEntryRepository>();
    final goalRepo = context.read<PersonalGoalRepository>();

    final entries = await foodRepo.getByDate(_selectedDate);
    final waterEntries = await waterRepo.getByDate(_selectedDate);
    final waterTotal = await waterRepo.getDailyTotalMl(_selectedDate);
    final totals = await foodRepo.getDailyTotals(_selectedDate);

    final calGoal = await goalRepo.getActiveByType('daily_calories');
    final proGoal = await goalRepo.getActiveByType('daily_protein');
    final waterGoal = await goalRepo.getActiveByType('daily_water_ml');

    final grouped = <String, List<FoodEntry>>{};
    for (final type in _mealTypes) {
      grouped[type] = entries.where((e) => e.mealType == type).toList();
    }

    if (!mounted) return;
    setState(() {
      _mealEntries = grouped;
      _waterEntries = waterEntries;
      _waterTotalMl = waterTotal;
      _caloriesTotal = totals['calories'] ?? 0;
      _proteinTotal = totals['protein'] ?? 0;
      _carbsTotal = totals['carbs'] ?? 0;
      _fatTotal = totals['fat'] ?? 0;
      _calorieGoal = calGoal?.targetValue;
      _proteinGoal = proGoal?.targetValue;
      _waterGoalMl = waterGoal?.targetValue;
      _loading = false;
    });
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _loading = true;
    });
    _loadData();
  }

  void _goToToday() {
    final today = stripTime(DateTime.now());
    if (_selectedDate == today) return;
    setState(() {
      _selectedDate = today;
      _loading = true;
    });
    _loadData();
  }

  Future<void> _addFoodEntry(String mealType) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          FoodLogForm(date: _selectedDate, initialMealType: mealType),
    );
    if (result == true) _loadData();
  }

  Future<void> _editFoodEntry(FoodEntry entry) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FoodLogForm(date: _selectedDate, existingEntry: entry),
    );
    if (result == true) _loadData();
  }

  Future<void> _deleteFoodEntry(FoodEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Remove "${entry.description}" from your log?'),
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
    await context.read<FoodEntryRepository>().delete(entry.id);
    _loadData();
  }

  Future<void> _addWater(int ml) async {
    final repo = context.read<WaterEntryRepository>();
    if (ml <= 0) return;
    final entry = WaterEntry(
      id: generateId(),
      date: _selectedDate,
      amountMl: ml,
      createdAt: DateTime.now(),
    );
    await repo.create(entry);
    _loadData();
  }

  Future<void> _deleteWater(WaterEntry entry) async {
    await context.read<WaterEntryRepository>().delete(entry.id);
    _loadData();
  }

  Future<void> _setGoal(String goalType, String label, double? current) async {
    final controller = TextEditingController(
      text: current?.toStringAsFixed(0) ?? '',
    );
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set $label Goal'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: 'Enter target $label'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;

    final goalRepo = context.read<PersonalGoalRepository>();
    final existing = await goalRepo.getActiveByType(goalType);
    final now = DateTime.now();
    if (existing != null) {
      await goalRepo.update(
        existing.copyWith(targetValue: value, updatedAt: now),
      );
    } else {
      await goalRepo.create(
        PersonalGoal(
          id: generateId(),
          goalType: goalType,
          targetValue: value,
          unit: goalType == 'daily_water_ml'
              ? 'ml'
              : goalType == 'daily_protein'
              ? 'g'
              : 'kcal',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _selectedDate == stripTime(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.book_outlined),
            tooltip: 'Meal Templates',
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => MealTemplateScreen(date: _selectedDate),
                ),
              );
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Food Database',
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const FoodSearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Weekly Summary',
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const WeeklySummaryScreen()),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _DateNavigator(
                    date: _selectedDate,
                    isToday: isToday,
                    onPrevious: () => _changeDate(-1),
                    onNext: () => _changeDate(1),
                    onToday: _goToToday,
                  ),
                  const SizedBox(height: 16),
                  _DailySummaryCard(
                    calories: _caloriesTotal,
                    protein: _proteinTotal,
                    carbs: _carbsTotal,
                    fat: _fatTotal,
                    calorieGoal: _calorieGoal,
                    proteinGoal: _proteinGoal,
                    onSetCalorieGoal: () =>
                        _setGoal('daily_calories', 'Calorie', _calorieGoal),
                    onSetProteinGoal: () =>
                        _setGoal('daily_protein', 'Protein', _proteinGoal),
                  ),
                  const SizedBox(height: 16),
                  for (final mealType in _mealTypes) ...[
                    _MealSection(
                      mealType: mealType,
                      entries: _mealEntries[mealType] ?? [],
                      onAdd: () => _addFoodEntry(mealType),
                      onTap: _editFoodEntry,
                      onDelete: _deleteFoodEntry,
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                  _WaterSection(
                    entries: _waterEntries,
                    totalMl: _waterTotalMl,
                    goalMl: _waterGoalMl,
                    onAdd: _addWater,
                    onDelete: _deleteWater,
                    onSetGoal: () =>
                        _setGoal('daily_water_ml', 'Water (ml)', _waterGoalMl),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addFoodEntry('snack'),
        tooltip: 'Log Food',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  const _DateNavigator({
    required this.date,
    required this.isToday,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrevious),
        GestureDetector(
          onTap: isToday ? null : onToday,
          child: Column(
            children: [
              Text(
                isToday ? 'Today' : DateFormat.yMMMEd().format(date),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isToday)
                Text(
                  'Tap for today',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isToday ? null : onNext,
        ),
      ],
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? calorieGoal;
  final double? proteinGoal;
  final VoidCallback onSetCalorieGoal;
  final VoidCallback onSetProteinGoal;

  const _DailySummaryCard({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.calorieGoal,
    this.proteinGoal,
    required this.onSetCalorieGoal,
    required this.onSetProteinGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Summary',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _NutrientProgress(
              label: 'Calories',
              value: calories,
              goal: calorieGoal,
              unit: 'kcal',
              color: theme.colorScheme.primary,
              onSetGoal: onSetCalorieGoal,
            ),
            const SizedBox(height: 10),
            _NutrientProgress(
              label: 'Protein',
              value: protein,
              goal: proteinGoal,
              unit: 'g',
              color: theme.colorScheme.tertiary,
              onSetGoal: onSetProteinGoal,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MacroChip(
                  label: 'Carbs',
                  value: '${carbs.toStringAsFixed(0)}g',
                ),
                const SizedBox(width: 8),
                _MacroChip(label: 'Fat', value: '${fat.toStringAsFixed(0)}g'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrientProgress extends StatelessWidget {
  final String label;
  final double value;
  final double? goal;
  final String unit;
  final Color color;
  final VoidCallback onSetGoal;

  const _NutrientProgress({
    required this.label,
    required this.value,
    this.goal,
    required this.unit,
    required this.color,
    required this.onSetGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goal != null && goal! > 0
        ? (value / goal!).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            GestureDetector(
              onTap: onSetGoal,
              child: Text(
                goal != null
                    ? '${value.toStringAsFixed(0)} / ${goal!.toStringAsFixed(0)} $unit'
                    : '${value.toStringAsFixed(0)} $unit (tap to set goal)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: goal == null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        if (goal != null) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;

  const _MacroChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label: $value', style: theme.textTheme.labelSmall),
    );
  }
}

class _MealSection extends StatelessWidget {
  final String mealType;
  final List<FoodEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<FoodEntry> onTap;
  final ValueChanged<FoodEntry> onDelete;

  const _MealSection({
    required this.mealType,
    required this.entries,
    required this.onAdd,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _mealLabels[mealType] ?? mealType;
    final icon = _mealIcons[mealType] ?? Icons.restaurant;
    final mealCalories = entries.fold<double>(
      0,
      (sum, e) => sum + (e.calories ?? 0),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (entries.isNotEmpty)
                  Text(
                    '${mealCalories.toStringAsFixed(0)} kcal',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(width: 4),
                SizedBox(
                  height: 28,
                  width: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    icon: const Icon(Icons.add),
                    onPressed: onAdd,
                  ),
                ),
              ],
            ),
            if (entries.isNotEmpty) ...[
              const Divider(height: 12),
              for (final entry in entries)
                Dismissible(
                  key: ValueKey(entry.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: theme.colorScheme.error,
                    child: Icon(Icons.delete, color: theme.colorScheme.onError),
                  ),
                  onDismissed: (_) => onDelete(entry),
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      entry.description.isEmpty
                          ? 'Food entry'
                          : entry.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: Text(
                      '${(entry.calories ?? 0).toStringAsFixed(0)} kcal  '
                      '${(entry.proteinGrams ?? 0).toStringAsFixed(0)}g P',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () => onTap(entry),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WaterSection extends StatelessWidget {
  final List<WaterEntry> entries;
  final int totalMl;
  final double? goalMl;
  final ValueChanged<int> onAdd;
  final ValueChanged<WaterEntry> onDelete;
  final VoidCallback onSetGoal;

  const _WaterSection({
    required this.entries,
    required this.totalMl,
    this.goalMl,
    required this.onAdd,
    required this.onDelete,
    required this.onSetGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goalMl != null && goalMl! > 0
        ? (totalMl / goalMl!).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.water_drop_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Water',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onSetGoal,
                  child: Text(
                    goalMl != null
                        ? '$totalMl / ${goalMl!.toStringAsFixed(0)} ml'
                        : '$totalMl ml (tap to set goal)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: goalMl == null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (goalMl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.15,
                  ),
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                  minHeight: 6,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                ActionChip(
                  label: const Text('+250 ml'),
                  onPressed: () => onAdd(250),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('+500 ml'),
                  onPressed: () => onAdd(500),
                ),
              ],
            ),
            if (entries.isNotEmpty) ...[
              const Divider(height: 16),
              for (final entry in entries)
                Dismissible(
                  key: ValueKey(entry.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: theme.colorScheme.error,
                    child: Icon(Icons.delete, color: theme.colorScheme.onError),
                  ),
                  onDismissed: (_) => onDelete(entry),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${entry.amountMl} ml',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          DateFormat.Hm().format(entry.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
