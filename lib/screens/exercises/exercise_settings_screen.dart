import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise_settings.dart';
import '../../repositories/exercise_settings_repository.dart';

class ExerciseSettingsScreen extends StatefulWidget {
  final String exerciseId;
  final String exerciseName;

  const ExerciseSettingsScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  State<ExerciseSettingsScreen> createState() => _ExerciseSettingsScreenState();
}

class _ExerciseSettingsScreenState extends State<ExerciseSettingsScreen> {
  ExerciseSettings? _settings;
  bool _loading = true;
  bool _saving = false;

  late TextEditingController _minRepsCtrl;
  late TextEditingController _maxRepsCtrl;
  late TextEditingController _incrementCtrl;
  late TextEditingController _machineIncrementCtrl;
  bool _isBodyweight = false;

  @override
  void initState() {
    super.initState();
    _minRepsCtrl = TextEditingController();
    _maxRepsCtrl = TextEditingController();
    _incrementCtrl = TextEditingController();
    _machineIncrementCtrl = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = context.read<ExerciseSettingsRepository>();
    final settings = await repo.getOrCreateForExercise(widget.exerciseId);
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _minRepsCtrl.text = settings.minReps.toString();
      _maxRepsCtrl.text = settings.maxReps.toString();
      _incrementCtrl.text = settings.weightIncrementKg.toStringAsFixed(1);
      _machineIncrementCtrl.text =
          settings.machineIncrementKg?.toStringAsFixed(1) ?? '';
      _isBodyweight = settings.isBodyweight;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_settings == null) return;

    final minReps = int.tryParse(_minRepsCtrl.text);
    final maxReps = int.tryParse(_maxRepsCtrl.text);
    final increment = double.tryParse(_incrementCtrl.text);

    if (minReps == null || minReps < 1) {
      _showError('Min reps must be at least 1');
      return;
    }
    if (maxReps == null || maxReps < minReps) {
      _showError('Max reps must be >= min reps');
      return;
    }
    if (!_isBodyweight && (increment == null || increment <= 0)) {
      _showError('Weight increment must be > 0');
      return;
    }

    final machineIncrement = double.tryParse(_machineIncrementCtrl.text);

    setState(() => _saving = true);

    final updated = _settings!.copyWith(
      minReps: minReps,
      maxReps: maxReps,
      weightIncrementKg: increment ?? _settings!.weightIncrementKg,
      isBodyweight: _isBodyweight,
      machineIncrementKg: machineIncrement,
      updatedAt: DateTime.now(),
    );

    final repo = context.read<ExerciseSettingsRepository>();
    await repo.update(updated);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _minRepsCtrl.dispose();
    _maxRepsCtrl.dispose();
    _incrementCtrl.dispose();
    _machineIncrementCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overload Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _saving || _loading ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.exerciseName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure how progressive overload suggestions '
                  'are calculated for this exercise.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'REP RANGE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minRepsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min Reps',
                          helperText: 'Reset target after increase',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _maxRepsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Reps',
                          helperText: 'Trigger for weight increase',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Bodyweight Exercise'),
                  subtitle: const Text('No weight increase — reps only'),
                  value: _isBodyweight,
                  onChanged: (value) => setState(() => _isBodyweight = value),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!_isBodyweight) ...[
                  const SizedBox(height: 16),
                  Text(
                    'LOAD INCREMENTS',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _incrementCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Default Increment (kg)',
                      helperText: 'e.g., 2.5 for barbell, 1.0 for dumbbell',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _machineIncrementCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Machine Increment (kg, optional)',
                      helperText:
                          'Fixed plate step for machines — overrides default',
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'When all sets reach max reps at the current weight, the '
                  'engine will suggest adding one increment and resetting '
                  'reps to the minimum.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (_saving) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
    );
  }
}
