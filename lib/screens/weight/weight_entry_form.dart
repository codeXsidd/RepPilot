import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/body_weight_entry.dart';
import 'package:rep_pilot/repositories/body_weight_repository.dart';

class WeightEntryForm extends StatefulWidget {
  final BodyWeightEntry? entry;
  final String weightUnit;
  final BodyWeightRepository repository;

  const WeightEntryForm({
    super.key,
    this.entry,
    required this.weightUnit,
    required this.repository,
  });

  @override
  State<WeightEntryForm> createState() => _WeightEntryFormState();
}

class _WeightEntryFormState extends State<WeightEntryForm> {
  late DateTime _date;
  late TextEditingController _weightController;
  late TextEditingController _notesController;
  bool _saving = false;
  String? _weightError;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _date = widget.entry?.date ?? DateTime.now();

    final displayVal = widget.entry != null
        ? displayWeight(
            widget.entry!.weightKg,
            widget.weightUnit,
          ).toStringAsFixed(1)
        : '';
    _weightController = TextEditingController(text: displayVal);
    _notesController = TextEditingController(text: widget.entry?.notes ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final text = _weightController.text.trim();
    final parsed = double.tryParse(text);

    if (parsed == null || parsed <= 0) {
      setState(() => _weightError = 'Enter a valid weight greater than 0');
      return;
    }

    setState(() {
      _weightError = null;
      _saving = true;
    });

    try {
      final weightKg = storageWeight(parsed, widget.weightUnit);
      final now = DateTime.now();
      final entry = BodyWeightEntry(
        id: widget.entry?.id ?? generateId(),
        date: stripTime(_date),
        weightKg: weightKg,
        notes: _notesController.text.trim(),
        createdAt: widget.entry?.createdAt ?? now,
        updatedAt: now,
      );

      await widget.repository.upsertByDate(entry);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save weight entry')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitLabel = widget.weightUnit == 'lb' ? 'lb' : 'kg';

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isEditing ? 'Edit Weight' : 'Log Weight',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                prefixIcon: Icon(Icons.calendar_today_rounded),
              ),
              child: Text(DateFormat.yMMMd().format(_date)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Weight ($unitLabel)',
              prefixIcon: const Icon(Icons.monitor_weight_rounded),
              errorText: _weightError,
            ),
            autofocus: !_isEditing,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              prefixIcon: Icon(Icons.note_rounded),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Update' : 'Save'),
          ),
        ],
      ),
    );
  }
}
