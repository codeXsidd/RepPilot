import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/food.dart';
import '../../repositories/food_repository.dart';

const _categories = [
  'breakfast',
  'staples',
  'protein',
  'vegetables',
  'snacks',
  'drinks',
  'other',
];

class FoodFormScreen extends StatefulWidget {
  final Food? food;

  const FoodFormScreen({super.key, this.food});

  @override
  State<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends State<FoodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _servingSizeCtrl;
  late final TextEditingController _servingUnitCtrl;
  late final TextEditingController _caloriesCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;
  late String _category;
  late bool _isFavorite;
  bool _saving = false;

  bool get _isEditing => widget.food != null;

  @override
  void initState() {
    super.initState();
    final f = widget.food;
    _nameCtrl = TextEditingController(text: f?.name ?? '');
    _servingSizeCtrl = TextEditingController(
      text: (f?.servingSize ?? 1).toString(),
    );
    _servingUnitCtrl = TextEditingController(text: f?.servingUnit ?? 'serving');
    _caloriesCtrl = TextEditingController(
      text: f?.caloriesPerServing.toStringAsFixed(0) ?? '',
    );
    _proteinCtrl = TextEditingController(
      text: f?.proteinPerServing.toStringAsFixed(0) ?? '',
    );
    _carbsCtrl = TextEditingController(
      text: f?.carbsPerServing.toStringAsFixed(0) ?? '',
    );
    _fatCtrl = TextEditingController(
      text: f?.fatPerServing.toStringAsFixed(0) ?? '',
    );
    _category = f?.category ?? 'other';
    _isFavorite = f?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _servingSizeCtrl.dispose();
    _servingUnitCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required';
    return null;
  }

  String? _validatePositive(String? v, String field) {
    if (v == null || v.isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null || n < 0) return '$field must be zero or positive';
    return null;
  }

  String? _validateServingSize(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final n = double.tryParse(v);
    if (n == null || n <= 0) return 'Must be greater than zero';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);

    try {
      final repo = context.read<FoodRepository>();
      final now = DateTime.now();

      final food = Food(
        id: widget.food?.id ?? generateId(),
        name: _nameCtrl.text.trim(),
        category: _category,
        servingSize: double.tryParse(_servingSizeCtrl.text) ?? 1,
        servingUnit: _servingUnitCtrl.text.trim().isEmpty
            ? 'serving'
            : _servingUnitCtrl.text.trim(),
        caloriesPerServing: double.tryParse(_caloriesCtrl.text) ?? 0,
        proteinPerServing: double.tryParse(_proteinCtrl.text) ?? 0,
        carbsPerServing: double.tryParse(_carbsCtrl.text) ?? 0,
        fatPerServing: double.tryParse(_fatCtrl.text) ?? 0,
        isCustom: true,
        isEstimate: widget.food?.isEstimate ?? false,
        isFavorite: _isFavorite,
        createdAt: widget.food?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEditing) {
        await repo.update(food);
      } else {
        await repo.create(food);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEstimate = widget.food?.isEstimate ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Food' : 'New Food'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? theme.colorScheme.error : null,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
            tooltip: 'Favorite',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isEstimate)
              Card(
                color: theme.colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.onTertiaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nutrition values are estimates',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (isEstimate) const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: _validateName,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c[0].toUpperCase() + c.substring(1)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _servingSizeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Serving Size',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateServingSize,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _servingUnitCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Unit (e.g. cup, g)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Nutrition per serving',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _caloriesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Calories',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _validatePositive(v, 'Calories'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _proteinCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Protein (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _validatePositive(v, 'Protein'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _carbsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Carbs (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _validatePositive(v, 'Carbs'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _fatCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Fat (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _validatePositive(v, 'Fat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Update' : 'Save Food'),
            ),
          ],
        ),
      ),
    );
  }
}
