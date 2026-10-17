import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../repositories/food_entry_repository.dart';
import '../../repositories/water_entry_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  double _calories = 0;
  double _protein = 0;
  double _carbs = 0;
  double _fat = 0;
  int _waterMl = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    final food = context.read<FoodEntryRepository>();
    final water = context.read<WaterEntryRepository>();
    final now = DateTime.now();

    final totals = await food.getDailyTotals(now);
    final waterTotal = await water.getDailyTotalMl(now);

    if (!mounted) return;
    setState(() {
      _calories = totals['calories'] ?? 0;
      _protein = totals['protein'] ?? 0;
      _carbs = totals['carbs'] ?? 0;
      _fat = totals['fat'] ?? 0;
      _waterMl = waterTotal;
      _loading = false;
    });
  }

  bool get _hasData => _calories > 0 || _waterMl > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateFormat.yMMMd().format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadToday,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    today,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(title: 'DAILY SUMMARY'),
                  _MacroRow(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Calories',
                    value: _calories > 0
                        ? '${_calories.toStringAsFixed(0)} kcal'
                        : '--',
                  ),
                  const SizedBox(height: 8),
                  _MacroRow(
                    icon: Icons.egg_rounded,
                    label: 'Protein',
                    value: _protein > 0
                        ? '${_protein.toStringAsFixed(0)}g'
                        : '--',
                  ),
                  const SizedBox(height: 8),
                  _MacroRow(
                    icon: Icons.grain_rounded,
                    label: 'Carbs',
                    value: _carbs > 0 ? '${_carbs.toStringAsFixed(0)}g' : '--',
                  ),
                  const SizedBox(height: 8),
                  _MacroRow(
                    icon: Icons.opacity_rounded,
                    label: 'Fat',
                    value: _fat > 0 ? '${_fat.toStringAsFixed(0)}g' : '--',
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(title: 'WATER INTAKE'),
                  _MacroRow(
                    icon: Icons.water_drop_rounded,
                    label: 'Water',
                    value: _waterMl > 0 ? '$_waterMl ml' : '--',
                  ),
                  const SizedBox(height: 24),
                  if (!_hasData)
                    const EmptyState(
                      icon: Icons.restaurant_rounded,
                      title: 'No Meals Logged Today',
                      description:
                          'Track your meals, calories, protein, and water intake. '
                          'Meal logging will be available in a future update.',
                    ),
                ],
              ),
            ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MacroRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(label, style: theme.textTheme.bodyMedium),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
