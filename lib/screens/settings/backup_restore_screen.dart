import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/default_exercises.dart';
import '../../core/data/default_foods.dart';
import '../../repositories/exercise_repository.dart';
import '../../repositories/food_repository.dart';
import '../../services/backup_service.dart';
import '../../widgets/section_header.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _busy = false;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _exportJson() async {
    setState(() => _busy = true);
    try {
      final service = context.read<BackupService>();
      final backup = await service.exportToJson();
      final jsonStr = service.encodeJson(backup);
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));
      final now = DateTime.now();
      final fileName =
          'reppilot_backup_'
          '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}.json';

      final uri = await FilePicker.saveFile(
        dialogTitle: 'Save backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (!mounted) return;
      if (uri != null) {
        _showSnackBar('Backup saved successfully');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Export failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportCsv(String tableName, String label) async {
    setState(() => _busy = true);
    try {
      final service = context.read<BackupService>();
      final csv = await service.exportTableToCsv(tableName);
      if (csv.isEmpty) {
        if (!mounted) return;
        _showSnackBar('No $label data to export');
        return;
      }

      final bytes = Uint8List.fromList(utf8.encode(csv));
      final now = DateTime.now();
      final fileName =
          'reppilot_${tableName}_'
          '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}.csv';

      final uri = await FilePicker.saveFile(
        dialogTitle: 'Save $label CSV',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );

      if (!mounted) return;
      if (uri != null) {
        _showSnackBar('$label CSV exported');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('CSV export failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importBackup() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null) return;
    if (!mounted) return;

    final service = context.read<BackupService>();
    setState(() => _busy = true);
    try {
      final bytes = await file.readAsBytes();
      final jsonStr = utf8.decode(bytes);
      final data = service.parseBackupJson(jsonStr);
      if (data == null) {
        if (!mounted) return;
        _showSnackBar('File is not valid JSON');
        return;
      }

      final validation = service.validateBackup(data);
      if (!validation.isValid) {
        if (!mounted) return;
        await _showErrorDialog('Invalid Backup', validation.errors.join('\n'));
        return;
      }

      final preview = service.getRestorePreview(data);
      if (preview == null) return;

      if (!mounted) return;
      final confirmed = await _showRestorePreviewDialog(
        preview,
        validation.warnings,
      );
      if (confirmed != true) return;

      if (!mounted) return;
      final restoreResult = await service.restoreFromJson(data);

      if (!mounted) return;
      if (restoreResult.warnings.isNotEmpty) {
        await _showErrorDialog(
          'Restore Complete',
          '${restoreResult.recordsRestored} records restored.\n\n'
              'Warnings:\n${restoreResult.warnings.join('\n')}',
        );
      } else {
        _showSnackBar('Restored ${restoreResult.recordsRestored} records');
      }
    } on BackupRestoreException catch (e) {
      if (!mounted) return;
      await _showErrorDialog('Restore Failed', e.message);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all your workouts, exercises, '
          'body weight entries, nutrition logs, and settings.\n\n'
          'This action cannot be undone. Consider creating a backup first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final doubleConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: const Text(
          'All data will be permanently deleted and default exercises '
          'and foods will be restored. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (doubleConfirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final service = context.read<BackupService>();
      await service.resetAllData();

      if (!mounted) return;
      final exerciseRepo = context.read<ExerciseRepository>();
      final foodRepo = context.read<FoodRepository>();
      await exerciseRepo.seedDefaults(buildDefaultExercises());
      await foodRepo.seedDefaults(buildDefaultFoods());

      if (!mounted) return;
      _showSnackBar('All data has been reset');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Reset failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showErrorDialog(String title, String message) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showRestorePreviewDialog(
    RestorePreview preview,
    List<String> warnings,
  ) {
    final nonEmpty = preview.recordCounts.entries
        .where((e) => e.value > 0)
        .toList();

    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Text('Restore Preview'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will replace all current data with '
                  '${preview.totalRecords} records from the backup.',
                ),
                const SizedBox(height: 8),
                Text(
                  'Exported: ${preview.exportedAt}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Schema version: ${preview.schemaVersion}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                for (final entry in nonEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_tableDisplayName(entry.key)),
                        Text('${entry.value}'),
                      ],
                    ),
                  ),
                if (warnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Warnings:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  for (final w in warnings)
                    Text(
                      w,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );
  }

  String _tableDisplayName(String tableName) {
    return tableName
        .replaceAll('_', ' ')
        .replaceFirstMapped(
          RegExp(r'^[a-z]'),
          (m) => m.group(0)!.toUpperCase(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SectionHeader(title: 'EXPORT'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.save_alt),
                        title: const Text('Create JSON Backup'),
                        subtitle: const Text('Full backup of all your data'),
                        onTap: _exportJson,
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.table_chart_outlined),
                        title: const Text('Export Weight Log (CSV)'),
                        onTap: () =>
                            _exportCsv('body_weight_entries', 'Weight'),
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.table_chart_outlined),
                        title: const Text('Export Food Log (CSV)'),
                        onTap: () => _exportCsv('food_entries', 'Food'),
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.table_chart_outlined),
                        title: const Text('Export Workouts (CSV)'),
                        onTap: () => _exportCsv('workout_sessions', 'Workouts'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'RESTORE'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Restore from Backup'),
                    subtitle: const Text(
                      'Import a previously exported JSON backup',
                    ),
                    onTap: _importBackup,
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'DANGER ZONE'),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_forever,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      'Reset All Data',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    subtitle: const Text('Delete everything and start fresh'),
                    onTap: _resetAllData,
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'ABOUT YOUR DATA'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'All data is stored locally on your device. '
                      'Backups are exported as human-readable JSON files '
                      'that you control. RepPilot never sends your data '
                      'over the internet. Uninstalling the app will '
                      'delete all data unless you have created a backup.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
