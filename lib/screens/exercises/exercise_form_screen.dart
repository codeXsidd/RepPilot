import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/data/default_exercises.dart';
import '../../models/exercise.dart';
import '../../repositories/exercise_repository.dart';
import 'exercise_detail_screen.dart';
import 'exercise_settings_screen.dart';

class ExerciseFormScreen extends StatefulWidget {
  final Exercise? exercise;

  const ExerciseFormScreen({super.key, this.exercise});

  @override
  State<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends State<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _muscleGroupController;
  late final TextEditingController _notesController;
  late String _category;
  late String _equipment;
  bool _saving = false;

  bool get _isEdit => widget.exercise != null;
  bool get _readOnly => widget.exercise != null && !widget.exercise!.isCustom;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise?.name ?? '');
    _muscleGroupController = TextEditingController(
      text: widget.exercise?.muscleGroup ?? '',
    );
    _notesController = TextEditingController(
      text: widget.exercise?.notes ?? '',
    );
    _category = widget.exercise?.category ?? exerciseCategories.first;
    _equipment = widget.exercise?.equipment ?? equipmentTypes.first;

    if (_readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute(
            builder: (_) => ExerciseDetailScreen(exercise: widget.exercise!),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _muscleGroupController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final repo = context.read<ExerciseRepository>();
    final now = DateTime.now();

    try {
      if (_isEdit) {
        final updated = widget.exercise!.copyWith(
          name: _nameController.text.trim(),
          category: _category,
          muscleGroup: _muscleGroupController.text.trim(),
          equipment: _equipment,
          notes: _notesController.text.trim(),
          updatedAt: now,
        );
        await repo.update(updated);
      } else {
        final exercise = Exercise(
          id: generateId(),
          name: _nameController.text.trim(),
          category: _category,
          muscleGroup: _muscleGroupController.text.trim(),
          equipment: _equipment,
          notes: _notesController.text.trim(),
          isCustom: true,
          createdAt: now,
          updatedAt: now,
        );
        await repo.create(exercise);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save exercise.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _readOnly
        ? 'Exercise Details'
        : (_isEdit ? 'Edit Exercise' : 'New Exercise');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Overload Settings',
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseSettingsScreen(
                      exerciseId: widget.exercise!.id,
                      exerciseName: widget.exercise!.name,
                    ),
                  ),
                );
              },
            ),
          if (!_readOnly)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Save',
              onPressed: _saving ? null : _save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              readOnly: _readOnly,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g., Barbell Bench Press',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an exercise name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: exerciseCategories.contains(_category)
                  ? _category
                  : exerciseCategories.first,
              decoration: const InputDecoration(labelText: 'Category'),
              items: exerciseCategories
                  .map(
                    (c) =>
                        DropdownMenuItem(value: c, child: Text(_capitalize(c))),
                  )
                  .toList(),
              onChanged: _readOnly
                  ? null
                  : (value) {
                      if (value != null) setState(() => _category = value);
                    },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _muscleGroupController,
              readOnly: _readOnly,
              decoration: const InputDecoration(
                labelText: 'Muscle Group',
                hintText: 'e.g., Pectorals, Quadriceps',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: equipmentTypes.contains(_equipment)
                  ? _equipment
                  : equipmentTypes.first,
              decoration: const InputDecoration(labelText: 'Equipment'),
              items: equipmentTypes
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(_equipmentLabel(e)),
                    ),
                  )
                  .toList(),
              onChanged: _readOnly
                  ? null
                  : (value) {
                      if (value != null) setState(() => _equipment = value);
                    },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              readOnly: _readOnly,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Tips, form cues, etc.',
              ),
              maxLines: 3,
              minLines: 1,
            ),
            if (_readOnly) ...[
              const SizedBox(height: 24),
              Text(
                'This is a built-in exercise and cannot be edited.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (_saving) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static String _equipmentLabel(String equip) {
    return equip.replaceAll('_', ' ').split(' ').map(_capitalize).join(' ');
  }
}
