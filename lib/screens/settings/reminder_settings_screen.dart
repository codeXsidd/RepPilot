import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/reminder_service.dart';
import '../../widgets/section_header.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  late ReminderPreferences _prefs;

  @override
  void initState() {
    super.initState();
    final service = context.read<ReminderService>();
    _prefs = service.loadPreferences();
  }

  Future<void> _save() async {
    final service = context.read<ReminderService>();
    await service.updateAndApply(_prefs);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Reminders updated')));
    }
  }

  Future<void> _pickTime({
    required int currentHour,
    required int currentMinute,
    required void Function(int hour, int minute) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
    );
    if (picked != null) {
      onPicked(picked.hour, picked.minute);
    }
  }

  String _formatTime(int hour, int minute) {
    return TimeOfDay(hour: hour, minute: minute).format(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = context.read<ReminderService>();
    final available = service.notificationsAvailable;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!available)
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notifications are not available on this device. '
                        'Reminder preferences are saved but notifications '
                        'will not appear.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!available) const SizedBox(height: 16),
          const SectionHeader(title: 'WORKOUT REMINDER'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Workout reminder'),
                  subtitle: const Text('Daily reminder to train'),
                  value: _prefs.workoutEnabled,
                  onChanged: (v) {
                    setState(() => _prefs = _prefs.copyWith(workoutEnabled: v));
                    _save();
                  },
                ),
                if (_prefs.workoutEnabled)
                  ListTile(
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Reminder time'),
                    trailing: Text(
                      _formatTime(_prefs.workoutHour, _prefs.workoutMinute),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => _pickTime(
                      currentHour: _prefs.workoutHour,
                      currentMinute: _prefs.workoutMinute,
                      onPicked: (h, m) {
                        setState(
                          () => _prefs = _prefs.copyWith(
                            workoutHour: h,
                            workoutMinute: m,
                          ),
                        );
                        _save();
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'WEIGHT TRACKING'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Weight reminder'),
                  subtitle: const Text('Daily reminder to weigh in'),
                  value: _prefs.weightEnabled,
                  onChanged: (v) {
                    setState(() => _prefs = _prefs.copyWith(weightEnabled: v));
                    _save();
                  },
                ),
                if (_prefs.weightEnabled)
                  ListTile(
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Reminder time'),
                    trailing: Text(
                      _formatTime(_prefs.weightHour, _prefs.weightMinute),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => _pickTime(
                      currentHour: _prefs.weightHour,
                      currentMinute: _prefs.weightMinute,
                      onPicked: (h, m) {
                        setState(
                          () => _prefs = _prefs.copyWith(
                            weightHour: h,
                            weightMinute: m,
                          ),
                        );
                        _save();
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'HYDRATION'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Water reminder'),
                  subtitle: const Text('Periodic hydration reminders'),
                  value: _prefs.waterEnabled,
                  onChanged: (v) {
                    setState(() => _prefs = _prefs.copyWith(waterEnabled: v));
                    _save();
                  },
                ),
                if (_prefs.waterEnabled) ...[
                  ListTile(
                    leading: const Icon(Icons.repeat_rounded),
                    title: const Text('Interval'),
                    trailing: DropdownButton<int>(
                      value: _prefs.waterIntervalHours,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Every hour')),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Every 2 hours'),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('Every 3 hours'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(
                            () =>
                                _prefs = _prefs.copyWith(waterIntervalHours: v),
                          );
                          _save();
                        }
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Active hours'),
                    trailing: Text(
                      '${_prefs.waterStartHour}:00 — ${_prefs.waterEndHour}:00',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
