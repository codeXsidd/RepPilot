import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/body_measurement.dart';
import 'package:rep_pilot/repositories/body_measurement_repository.dart';

class BodyMeasurementForm extends StatefulWidget {
  final BodyMeasurement? measurement;
  final BodyMeasurementRepository repository;

  const BodyMeasurementForm({
    super.key,
    this.measurement,
    required this.repository,
  });

  @override
  State<BodyMeasurementForm> createState() => _BodyMeasurementFormState();
}

class _BodyMeasurementFormState extends State<BodyMeasurementForm> {
  late DateTime _date;
  late TextEditingController _waistController;
  late TextEditingController _chestController;
  late TextEditingController _leftArmController;
  late TextEditingController _rightArmController;
  late TextEditingController _hipsController;
  late TextEditingController _notesController;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.measurement != null;

  @override
  void initState() {
    super.initState();
    final m = widget.measurement;
    _date = m?.date ?? DateTime.now();
    _waistController = TextEditingController(
      text: m?.waistCm?.toStringAsFixed(1) ?? '',
    );
    _chestController = TextEditingController(
      text: m?.chestCm?.toStringAsFixed(1) ?? '',
    );
    _leftArmController = TextEditingController(
      text: m?.leftArmCm?.toStringAsFixed(1) ?? '',
    );
    _rightArmController = TextEditingController(
      text: m?.rightArmCm?.toStringAsFixed(1) ?? '',
    );
    _hipsController = TextEditingController(
      text: m?.hipsCm?.toStringAsFixed(1) ?? '',
    );
    _notesController = TextEditingController(text: m?.notes ?? '');
  }

  @override
  void dispose() {
    _waistController.dispose();
    _chestController.dispose();
    _leftArmController.dispose();
    _rightArmController.dispose();
    _hipsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? _parseField(TextEditingController ctrl) {
    final text = ctrl.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
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
    final waist = _parseField(_waistController);
    final chest = _parseField(_chestController);
    final leftArm = _parseField(_leftArmController);
    final rightArm = _parseField(_rightArmController);
    final hips = _parseField(_hipsController);

    if (waist == null &&
        chest == null &&
        leftArm == null &&
        rightArm == null &&
        hips == null) {
      setState(() => _error = 'Enter at least one measurement');
      return;
    }

    for (final val in [waist, chest, leftArm, rightArm, hips]) {
      if (val != null && val <= 0) {
        setState(() => _error = 'Measurements must be greater than 0');
        return;
      }
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    try {
      final now = DateTime.now();
      final entry = BodyMeasurement(
        id: widget.measurement?.id ?? generateId(),
        date: stripTime(_date),
        waistCm: waist,
        chestCm: chest,
        leftArmCm: leftArm,
        rightArmCm: rightArm,
        hipsCm: hips,
        notes: _notesController.text.trim(),
        createdAt: widget.measurement?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEditing) {
        await widget.repository.update(entry);
      } else {
        await widget.repository.create(entry);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save measurement')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit Measurements' : 'Body Measurements',
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
            _MeasurementField(
              controller: _waistController,
              label: 'Waist (cm)',
            ),
            const SizedBox(height: 8),
            _MeasurementField(
              controller: _chestController,
              label: 'Chest (cm)',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MeasurementField(
                    controller: _leftArmController,
                    label: 'Left Arm (cm)',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MeasurementField(
                    controller: _rightArmController,
                    label: 'Right Arm (cm)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _MeasurementField(controller: _hipsController, label: 'Hips (cm)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.note_rounded),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
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
      ),
    );
  }
}

class _MeasurementField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _MeasurementField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}
