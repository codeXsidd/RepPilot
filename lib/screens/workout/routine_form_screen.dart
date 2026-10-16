import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/exercise.dart';
import '../../models/routine.dart';
import '../../models/routine_exercise.dart';
import '../../repositories/exercise_repository.dart';
import '../../repositories/routine_exercise_repository.dart';
import '../../repositories/routine_repository.dart';
import '../exercises/exercise_picker_screen.dart';

const _dayOptions = <int?, String>{
  null: 'Unscheduled',
  1: 'Monday',
  2: 'Tuesday',
  3: 'Wednesday',
  4: 'Thursday',
  5: 'Friday',
  6: 'Saturday',
  7: 'Sunday',
};

class RoutineFormScreen extends StatefulWidget {
  final Routine? routine;

  const RoutineFormScreen({super.key, this.routine});

  @override
  State<RoutineFormScreen> createState() => _RoutineFormScreenState();
}

class _RoutineFormScreenState extends State<RoutineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  int? _dayOfWeek;
  final List<_RoutineExerciseEntry> _exercises = [];
  bool _loading = false;
  bool _initialLoading = true;

  bool get _isEdit => widget.routine != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine?.name ?? '');
    _notesController = TextEditingController(text: widget.routine?.notes ?? '');
    _dayOfWeek = widget.routine?.dayOfWeek;
    if (_isEdit) {
      _loadExistingExercises();
    } else {
      _initialLoading = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingExercises() async {
    final reRepo = context.read<RoutineExerciseRepository>();
    final exerciseRepo = context.read<ExerciseRepository>();

    final routineExercises = await reRepo.getByRoutineId(widget.routine!.id);
    final entries = <_RoutineExerciseEntry>[];

    for (final re in routineExercises) {
      final exercise = await exerciseRepo.getById(re.exerciseId);
      if (exercise != null) {
        entries.add(
          _RoutineExerciseEntry(
            exercise: exercise,
            targetSets: re.targetSets,
            targetRepsMin: re.targetRepsMin,
            targetRepsMax: re.targetRepsMax,
            targetWeightKg: re.targetWeightKg,
            restSeconds: re.restSeconds,
            notes: re.notes,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _exercises.addAll(entries);
      _initialLoading = false;
    });
  }

  Future<void> _addExercises() async {
    final excludeIds = _exercises.map((e) => e.exercise.id).toList();
    final selected = await Navigator.push<List<Exercise>>(
      context,
      MaterialPageRoute(
        builder: (_) => ExercisePickerScreen(excludeIds: excludeIds),
      ),
    );
    if (selected == null || selected.isEmpty) return;

    setState(() {
      for (final exercise in selected) {
        _exercises.add(_RoutineExerciseEntry(exercise: exercise));
      }
    });
  }

  void _removeExercise(int index) {
    setState(() => _exercises.removeAt(index));
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });
  }

  Future<void> _editExerciseDetails(int index) async {
    final entry = _exercises[index];
    final setsCtrl = TextEditingController(text: entry.targetSets.toString());
    final minRepsCtrl = TextEditingController(
      text: (entry.targetRepsMin ?? '').toString(),
    );
    final maxRepsCtrl = TextEditingController(
      text: (entry.targetRepsMax ?? '').toString(),
    );
    final weightCtrl = TextEditingController(
      text: entry.targetWeightKg?.toStringAsFixed(1) ?? '',
    );
    final restCtrl = TextEditingController(text: entry.restSeconds.toString());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              entry.exercise.name,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: setsCtrl,
                    decoration: const InputDecoration(labelText: 'Sets'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: minRepsCtrl,
                    decoration: const InputDecoration(labelText: 'Min Reps'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: maxRepsCtrl,
                    decoration: const InputDecoration(labelText: 'Max Reps'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: weightCtrl,
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: restCtrl,
                    decoration: const InputDecoration(labelText: 'Rest (sec)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() {
                  entry.targetSets =
                      int.tryParse(setsCtrl.text) ?? entry.targetSets;
                  final minR = int.tryParse(minRepsCtrl.text);
                  final maxR = int.tryParse(maxRepsCtrl.text);
                  entry.targetRepsMin = minR;
                  entry.targetRepsMax = maxR;
                  entry.targetWeightKg = double.tryParse(weightCtrl.text);
                  entry.restSeconds =
                      int.tryParse(restCtrl.text) ?? entry.restSeconds;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );

    setsCtrl.dispose();
    minRepsCtrl.dispose();
    maxRepsCtrl.dispose();
    weightCtrl.dispose();
    restCtrl.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final routineRepo = context.read<RoutineRepository>();
    final reRepo = context.read<RoutineExerciseRepository>();
    final now = DateTime.now();

    try {
      String routineId;
      if (_isEdit) {
        routineId = widget.routine!.id;
        final updated = widget.routine!.copyWith(
          name: _nameController.text.trim(),
          dayOfWeek: _dayOfWeek ?? widget.routine!.dayOfWeek,
          notes: _notesController.text.trim(),
          updatedAt: now,
        );
        if (_dayOfWeek == null && widget.routine!.dayOfWeek != null) {
          await routineRepo.unschedule(routineId);
          await routineRepo.update(updated.copyWith(updatedAt: now));
        } else if (_dayOfWeek != null) {
          await routineRepo.update(updated);
          await routineRepo.schedule(routineId, _dayOfWeek!);
        } else {
          await routineRepo.update(updated);
        }
      } else {
        routineId = generateId();
        final routine = Routine(
          id: routineId,
          name: _nameController.text.trim(),
          dayOfWeek: _dayOfWeek,
          notes: _notesController.text.trim(),
          createdAt: now,
          updatedAt: now,
        );
        await routineRepo.create(routine);
      }

      await reRepo.deleteAllForRoutine(routineId);

      for (var i = 0; i < _exercises.length; i++) {
        final entry = _exercises[i];
        final targetReps = entry.targetRepsMax ?? entry.targetRepsMin ?? 10;
        final re = RoutineExercise(
          id: generateId(),
          routineId: routineId,
          exerciseId: entry.exercise.id,
          targetSets: entry.targetSets,
          targetReps: targetReps,
          targetRepsMin: entry.targetRepsMin,
          targetRepsMax: entry.targetRepsMax,
          targetWeightKg: entry.targetWeightKg,
          restSeconds: entry.restSeconds,
          sortOrder: i,
          notes: entry.notes,
          createdAt: now,
          updatedAt: now,
        );
        await reRepo.create(re);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save routine.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Routine' : 'New Routine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _loading ? null : _save,
          ),
        ],
      ),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Routine Name',
                      hintText: 'e.g., Push Day, Upper Body',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a routine name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    initialValue: _dayOfWeek,
                    decoration: const InputDecoration(labelText: 'Day of Week'),
                    items: _dayOptions.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _dayOfWeek = value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Any notes about this routine',
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel(text: 'EXERCISES'),
                  if (_exercises.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No exercises added yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _exercises.length,
                      onReorderItem: (oldIndex, newIndex) =>
                          _reorderExercises(oldIndex, newIndex),
                      itemBuilder: (context, index) {
                        final entry = _exercises[index];
                        return _ExerciseTile(
                          key: ValueKey('${entry.exercise.id}-$index'),
                          entry: entry,
                          onTap: () => _editExerciseDetails(index),
                          onDismissed: () => _removeExercise(index),
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _addExercises,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Exercises'),
                  ),
                  if (_loading) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final _RoutineExerciseEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _ExerciseTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDismissed,
  });

  String get _repsLabel {
    final min = entry.targetRepsMin;
    final max = entry.targetRepsMax;
    if (min != null && max != null) {
      return min == max ? '$min' : '$min-$max';
    }
    if (min != null) return '$min+';
    if (max != null) return '$max';
    return '10';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weightLabel = entry.targetWeightKg != null
        ? '${entry.targetWeightKg!.toStringAsFixed(1)} kg'
        : null;

    return Dismissible(
      key: ValueKey('dismiss-${entry.exercise.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.errorContainer,
        child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(
            entry.exercise.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            [
              '${entry.targetSets}x$_repsLabel',
              ?weightLabel,
              '${entry.restSeconds}s rest',
            ].join(' • '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: ReorderableDragStartListener(
            index: 0,
            child: const Icon(Icons.drag_handle),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _RoutineExerciseEntry {
  final Exercise exercise;
  int targetSets;
  int? targetRepsMin;
  int? targetRepsMax;
  double? targetWeightKg;
  int restSeconds;
  String notes;

  _RoutineExerciseEntry({
    required this.exercise,
    this.targetSets = 3,
    this.targetRepsMin = 8,
    this.targetRepsMax = 12,
    this.targetWeightKg,
    this.restSeconds = 60,
    this.notes = '',
  });
}
