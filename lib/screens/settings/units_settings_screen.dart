import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/user_profile.dart';
import '../../repositories/user_profile_repository.dart';

class UnitsSettingsScreen extends StatefulWidget {
  const UnitsSettingsScreen({super.key});

  @override
  State<UnitsSettingsScreen> createState() => _UnitsSettingsScreenState();
}

class _UnitsSettingsScreenState extends State<UnitsSettingsScreen> {
  String _weightUnit = 'kg';
  bool _loading = true;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<UserProfileRepository>();
    final now = DateTime.now();
    final profile = await repo.getOrCreate(
      UserProfile(id: generateId(), createdAt: now, updatedAt: now),
    );
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _weightUnit = profile.weightUnit;
      _loading = false;
    });
  }

  Future<void> _setUnit(String unit) async {
    if (_profile == null || unit == _weightUnit) return;
    final repo = context.read<UserProfileRepository>();
    final updated = _profile!.copyWith(
      weightUnit: unit,
      updatedAt: DateTime.now(),
    );
    await repo.update(updated);
    if (!mounted) return;
    setState(() {
      _profile = updated;
      _weightUnit = unit;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Weight unit set to ${unit == 'kg' ? 'kilograms (kg)' : 'pounds (lb)'}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Units')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Weight Unit',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose how weights are displayed throughout the app. '
                  'All data is stored in kilograms internally.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      _UnitOption(
                        label: 'Kilograms (kg)',
                        selected: _weightUnit == 'kg',
                        onTap: () => _setUnit('kg'),
                      ),
                      const Divider(height: 1, indent: 56),
                      _UnitOption(
                        label: 'Pounds (lb)',
                        selected: _weightUnit == 'lb',
                        onTap: () => _setUnit('lb'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _UnitOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnitOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        Icons.straighten_rounded,
        color: selected ? theme.colorScheme.primary : null,
      ),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
