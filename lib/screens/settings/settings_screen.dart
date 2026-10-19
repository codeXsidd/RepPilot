import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/training_level_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/section_header.dart';
import 'backup_restore_screen.dart';
import 'plate_calculator_screen.dart';
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
                  icon: Icons.brightness_auto_rounded,
                  selected: themeCtrl.themeMode == ThemeMode.system,
                  onTap: () => themeCtrl.setThemeMode(ThemeMode.system),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
                _ThemeOption(
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  selected: themeCtrl.themeMode == ThemeMode.light,
                  onTap: () => themeCtrl.setThemeMode(ThemeMode.light),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
                _ThemeOption(
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
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
                        Divider(
                          height: 1,
                          indent: 56,
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ListTile(
                        leading: Icon(
                          switch (level) {
                            TrainingLevel.beginner => Icons.eco_rounded,
                            TrainingLevel.intermediate =>
                              Icons.fitness_center_rounded,
                            TrainingLevel.advanced => Icons.bolt_rounded,
                          },
                          color: levelCtrl.level == level
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          level.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: levelCtrl.level == level
                                ? FontWeight.w600
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          level.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: levelCtrl.level == level
                            ? Icon(
                                Icons.check_circle_rounded,
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
          const SectionHeader(title: 'WORKOUT TOOLS'),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.calculate_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: const Text('Plate Calculator'),
              subtitle: const Text(
                'Calculate plates needed for a target weight',
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const PlateCalculatorScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'NOTIFICATIONS'),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.notifications_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: const Text('Reminders'),
              subtitle: const Text('Workout, weight and hydration reminders'),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
                  leading: Icon(
                    Icons.straighten_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  title: const Text('Units'),
                  subtitle: const Text('Weight display: kg or lb'),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UnitsSettingsScreen(),
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
                ListTile(
                  leading: Icon(
                    Icons.backup_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  title: const Text('Backup & Restore'),
                  subtitle: const Text('Export or import your data'),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: const Icon(
                          Icons.fitness_center_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RepPilot',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Version 1.3.0',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'A free, offline-first fitness app. Your data stays on your '
                    'device — no accounts, no cloud, no ads.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
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
      leading: Icon(
        icon,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: selected ? FontWeight.w600 : null,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
