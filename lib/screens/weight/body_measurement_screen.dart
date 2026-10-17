import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:rep_pilot/models/body_measurement.dart';
import 'package:rep_pilot/repositories/body_measurement_repository.dart';
import 'package:rep_pilot/widgets/empty_state.dart';
import 'package:rep_pilot/widgets/section_header.dart';

import 'body_measurement_form.dart';

class BodyMeasurementScreen extends StatefulWidget {
  const BodyMeasurementScreen({super.key});

  @override
  State<BodyMeasurementScreen> createState() => _BodyMeasurementScreenState();
}

class _BodyMeasurementScreenState extends State<BodyMeasurementScreen> {
  List<BodyMeasurement> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = context.read<BodyMeasurementRepository>();
    final entries = await repo.getAll();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _addOrEdit({BodyMeasurement? entry}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BodyMeasurementForm(
        measurement: entry,
        repository: context.read<BodyMeasurementRepository>(),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _deleteEntry(BodyMeasurement entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Measurement'),
        content: Text(
          'Delete measurements for '
          '${DateFormat.yMMMd().format(entry.date)}?',
        ),
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
    await context.read<BodyMeasurementRepository>().delete(entry.id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Body Measurements')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_entries.isNotEmpty) ...[
                    _LatestMeasurementCard(entry: _entries.first),
                    const SizedBox(height: 16),
                  ],
                  const SectionHeader(title: 'HISTORY'),
                  if (_entries.isEmpty)
                    const EmptyState(
                      icon: Icons.straighten_rounded,
                      title: 'No Measurements',
                      description:
                          'Tap + to log body measurements. Trends will '
                          'appear once you have data.',
                    )
                  else
                    ..._entries.map(
                      (e) => _MeasurementTile(
                        entry: e,
                        onTap: () => _addOrEdit(entry: e),
                        onDismissed: () => _deleteEntry(e),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        tooltip: 'Log Measurements',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _LatestMeasurementCard extends StatelessWidget {
  final BodyMeasurement entry;

  const _LatestMeasurementCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[];
    if (entry.waistCm != null) {
      parts.add('Waist: ${entry.waistCm!.toStringAsFixed(1)} cm');
    }
    if (entry.chestCm != null) {
      parts.add('Chest: ${entry.chestCm!.toStringAsFixed(1)} cm');
    }
    if (entry.leftArmCm != null) {
      parts.add('L Arm: ${entry.leftArmCm!.toStringAsFixed(1)} cm');
    }
    if (entry.rightArmCm != null) {
      parts.add('R Arm: ${entry.rightArmCm!.toStringAsFixed(1)} cm');
    }
    if (entry.hipsCm != null) {
      parts.add('Hips: ${entry.hipsCm!.toStringAsFixed(1)} cm');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest — ${DateFormat.yMMMd().format(entry.date)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: parts
                  .map(
                    (p) => Text(
                      p,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementTile extends StatelessWidget {
  final BodyMeasurement entry;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _MeasurementTile({
    required this.entry,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[];
    if (entry.waistCm != null) {
      parts.add('W: ${entry.waistCm!.toStringAsFixed(1)}');
    }
    if (entry.chestCm != null) {
      parts.add('C: ${entry.chestCm!.toStringAsFixed(1)}');
    }
    if (entry.leftArmCm != null) {
      parts.add('LA: ${entry.leftArmCm!.toStringAsFixed(1)}');
    }
    if (entry.rightArmCm != null) {
      parts.add('RA: ${entry.rightArmCm!.toStringAsFixed(1)}');
    }
    if (entry.hipsCm != null) {
      parts.add('H: ${entry.hipsCm!.toStringAsFixed(1)}');
    }

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete_rounded, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) async {
        onDismissed();
        return false;
      },
      child: ListTile(
        title: Text(parts.join('  ·  ')),
        subtitle: Text(DateFormat.yMMMd().format(entry.date)),
        trailing: entry.notes.isNotEmpty
            ? Icon(
                Icons.note_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
