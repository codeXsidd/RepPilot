import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food.dart';
import '../../repositories/food_repository.dart';
import 'food_form_screen.dart';

const _categories = [
  'all',
  'breakfast',
  'staples',
  'protein',
  'vegetables',
  'snacks',
  'drinks',
  'other',
];

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  List<Food> _foods = [];
  String _selectedCategory = 'all';
  bool _favoritesOnly = false;
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFoods() async {
    final repo = context.read<FoodRepository>();
    List<Food> foods;

    if (_searchCtrl.text.isNotEmpty) {
      foods = await repo.search(_searchCtrl.text);
    } else if (_favoritesOnly) {
      foods = await repo.getFavorites();
    } else if (_selectedCategory != 'all') {
      foods = await repo.getByCategory(_selectedCategory);
    } else {
      foods = await repo.getAll();
    }

    if (_favoritesOnly &&
        _searchCtrl.text.isEmpty &&
        _selectedCategory == 'all') {
      // already filtered
    } else if (_favoritesOnly) {
      foods = foods.where((f) => f.isFavorite).toList();
    }

    if (!mounted) return;
    setState(() {
      _foods = foods;
      _loading = false;
    });
  }

  Future<void> _toggleFavorite(Food food) async {
    await context.read<FoodRepository>().toggleFavorite(food.id);
    _loadFoods();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Food Database')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search foods...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _loadFoods();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _loadFoods(),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: const Text('Favorites'),
                    selected: _favoritesOnly,
                    onSelected: (v) {
                      setState(() => _favoritesOnly = v);
                      _loadFoods();
                    },
                  ),
                ),
                for (final cat in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        cat == 'all'
                            ? 'All'
                            : cat[0].toUpperCase() + cat.substring(1),
                      ),
                      selected: _selectedCategory == cat,
                      onSelected: (_) {
                        setState(() => _selectedCategory = cat);
                        _loadFoods();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _foods.isEmpty
                ? Center(
                    child: Text(
                      'No foods found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _foods.length,
                    itemBuilder: (_, i) {
                      final food = _foods[i];
                      return ListTile(
                        title: Text(food.name),
                        subtitle: Text(
                          '${food.caloriesPerServing.toStringAsFixed(0)} kcal'
                          ' / ${food.servingSize} ${food.servingUnit}'
                          '${food.isEstimate ? '  (estimate)' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            food.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: food.isFavorite
                                ? theme.colorScheme.error
                                : null,
                            size: 20,
                          ),
                          onPressed: () => _toggleFavorite(food),
                        ),
                        onTap: () => Navigator.pop(context, food),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const FoodFormScreen()),
          );
          if (result == true) _loadFoods();
        },
        tooltip: 'New Food',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
