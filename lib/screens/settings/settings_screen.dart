import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/training_level_service.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/section_header.dart';
import 'backup_restore_screen.dart';
import 'reminder_settings_screen.dart';
import 'units_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeCtrl = context.watch<ThemeController>();
    final levelCtrl = context.watch<TrainingLevelService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'APPEARANCE'),
          Card(
            child: Column(
              children: [
                _ThemeOption(
                  label: 'System Default',
                  icon: Icons.brightness_auto,
                  selected: themeCtrl.themeMode == ThemeMode.system,
                  onTap: () => themeCtrl.setThemeMode(ThemeMode.system),
                ),
                const Divider(height: 1, indent: 56),
                _ThemeOption(
                  label: 'Light',
                  icon: Icons.light_mode,
                  selected: themeCtrl.themeMode == ThemeMode.light,
                  onTap: () => themeCtrl.setThemeMode(ThemeMode.light),
                ),
                const Divider(height: 1, indent: 56),
                _ThemeOption(
                  label: 'Dark',
                  icon: Icons.dark_mode,
                  selected: themeCtrl.themeMode == ThemeMode.dark,
                  onTap: () => themeCtrl.setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'TRAINING EXPERIENCE'),
          Card(
            child: Column(
              children: [
                for (final level in TrainingLevel.values)
                  Column(
                    children: [
                      if (level != TrainingLevel.values.first)
                        const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: Icon(
                          switch (level) {
                            TrainingLevel.beginner => Icons.eco,
                            TrainingLevel.intermediate => Icons.fitness_center,
                            TrainingLevel.advanced => Icons.bolt,
                          },
                          color: levelCtrl.level == level
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        title: Text(level.label),
                        subtitle: Text(
                          level.description,
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: levelCtrl.level == level
                            ? Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        onTap: () => levelCtrl.setLevel(level),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'NOTIFICATIONS'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Reminders'),
              subtitle: const Text('Workout, weight and hydration reminders'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReminderSettingsScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'DATA'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.straighten),
                  title: const Text('Units'),
                  subtitle: const Text('Weight display: kg or lb'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UnitsSettingsScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Backup & Restore'),
                  subtitle: const Text('Export or import your data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BackupRestoreScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'ABOUT'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RepPilot',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A free, offline-first fitness app. Your data stays on your '
                    'device — no accounts, no cloud, no ads.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: selected ? theme.colorScheme.primary : null),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
