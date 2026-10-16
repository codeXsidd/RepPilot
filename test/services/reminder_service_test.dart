import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rep_pilot/services/reminder_service.dart';

class RecordingScheduler implements NotificationScheduler {
  final List<String> calls = [];
  @override
  final bool isAvailable;

  RecordingScheduler({this.isAvailable = true});

  @override
  Future<bool> initialize() async {
    calls.add('initialize');
    return isAvailable;
  }

  @override
  Future<bool> requestPermission() async {
    calls.add('requestPermission');
    return isAvailable;
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    calls.add('scheduleDaily:$id:$hour:$minute');
  }

  @override
  Future<void> scheduleRepeating({
    required int id,
    required String title,
    required String body,
    required int intervalHours,
    required int startHour,
    required int endHour,
  }) async {
    calls.add('scheduleRepeating:$id:$intervalHours:$startHour-$endHour');
  }

  @override
  Future<void> cancel(int id) async {
    calls.add('cancel:$id');
  }

  @override
  Future<void> cancelAll() async {
    calls.add('cancelAll');
  }
}

void main() {
  group('ReminderPreferences', () {
    test('defaults are sensible', () {
      const prefs = ReminderPreferences();
      expect(prefs.workoutEnabled, false);
      expect(prefs.workoutHour, 7);
      expect(prefs.workoutMinute, 0);
      expect(prefs.weightEnabled, false);
      expect(prefs.weightHour, 7);
      expect(prefs.weightMinute, 30);
      expect(prefs.waterEnabled, false);
      expect(prefs.waterIntervalHours, 2);
      expect(prefs.waterStartHour, 8);
      expect(prefs.waterEndHour, 22);
    });

    test('copyWith overrides specific fields', () {
      const prefs = ReminderPreferences();
      final updated = prefs.copyWith(workoutEnabled: true, workoutHour: 18);
      expect(updated.workoutEnabled, true);
      expect(updated.workoutHour, 18);
      expect(updated.weightEnabled, false);
    });
  });

  group('ReminderService preferences', () {
    test('loadPreferences returns defaults when empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final scheduler = NoOpNotificationScheduler();
      final service = ReminderService(prefs, scheduler);

      final loaded = service.loadPreferences();
      expect(loaded.workoutEnabled, false);
      expect(loaded.workoutHour, 7);
    });

    test('savePreferences persists all values', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final scheduler = NoOpNotificationScheduler();
      final service = ReminderService(prefs, scheduler);

      const reminder = ReminderPreferences(
        workoutEnabled: true,
        workoutHour: 18,
        workoutMinute: 30,
        weightEnabled: true,
        weightHour: 8,
        weightMinute: 0,
        waterEnabled: true,
        waterIntervalHours: 3,
        waterStartHour: 9,
        waterEndHour: 21,
      );
      await service.savePreferences(reminder);

      final loaded = service.loadPreferences();
      expect(loaded.workoutEnabled, true);
      expect(loaded.workoutHour, 18);
      expect(loaded.workoutMinute, 30);
      expect(loaded.weightEnabled, true);
      expect(loaded.weightHour, 8);
      expect(loaded.weightMinute, 0);
      expect(loaded.waterEnabled, true);
      expect(loaded.waterIntervalHours, 3);
      expect(loaded.waterStartHour, 9);
      expect(loaded.waterEndHour, 21);
    });

    test('loadPreferences reads saved values', () async {
      SharedPreferences.setMockInitialValues({
        'reminder_workout_enabled': true,
        'reminder_workout_hour': 6,
        'reminder_workout_minute': 45,
      });
      final prefs = await SharedPreferences.getInstance();
      final service = ReminderService(prefs, NoOpNotificationScheduler());

      final loaded = service.loadPreferences();
      expect(loaded.workoutEnabled, true);
      expect(loaded.workoutHour, 6);
      expect(loaded.workoutMinute, 45);
    });
  });

  group('applySchedule with available scheduler', () {
    test('schedules workout reminder when enabled', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final scheduler = RecordingScheduler(isAvailable: true);
      final service = ReminderService(prefs, scheduler);

      await service.applySchedule(
        const ReminderPreferences(
          workoutEnabled: true,
          workoutHour: 7,
          workoutMinute: 0,
        ),
      );

      expect(scheduler.calls, contains('scheduleDaily:100:7:0'));
    });

    test('schedules weight reminder when enabled', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final scheduler = RecordingScheduler(isAvailable: true);
      final service = ReminderService(prefs, scheduler);

      await service.applySchedule(
        const ReminderPreferences(
          weightEnabled: true,
          weightHour: 8,
          weightMinute: 30,
        ),
      );

      expect(scheduler.calls, contains('scheduleDaily:200:8:30'));
    });

    test('schedules water reminders when enabled', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final scheduler = RecordingScheduler(isAvailable: true);
      final service = ReminderService(prefs, scheduler);

      await service.applySchedule(
        const ReminderPreferences(
          waterEnabled: true,
          waterIntervalHours: 2,
          waterStartHour: 8,
          waterEndHour: 22,
        ),
      );

      expect(scheduler.calls, contains('scheduleRepeating:300:2:8-22'));
    });

    test('cancels existing before scheduling new', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final scheduler = RecordingScheduler(isAvailable: true);
      final service = ReminderService(prefs, scheduler);

      await service.applySchedule(
        const ReminderPreferences(workoutEnabled: true),
      );

      expect(scheduler.calls.first, startsWith('cancel:'));
    });

    test('does not schedule when disabled', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final scheduler = RecordingScheduler(isAvailable: true);
      final service = ReminderService(prefs, scheduler);

      await service.applySchedule(const ReminderPreferences());

      expect(
        scheduler.calls.where((c) => c.startsWith('scheduleDaily')),
        isEmpty,
      );
    });
  });

  group('disabled notifications', () {
    test('notificationsAvailable returns false with NoOp scheduler', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = ReminderService(prefs, NoOpNotificationScheduler());
      expect(service.notificationsAvailable, false);
    });

    test('applySchedule is no-op when scheduler unavailable', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final scheduler = RecordingScheduler(isAvailable: false);
      final service = ReminderService(prefs, scheduler);

      await service.applySchedule(
        const ReminderPreferences(workoutEnabled: true),
      );

      expect(scheduler.calls, isEmpty);
    });

    test('preferences still save when notifications unavailable', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = ReminderService(prefs, NoOpNotificationScheduler());

      const reminder = ReminderPreferences(
        workoutEnabled: true,
        workoutHour: 18,
      );
      await service.updateAndApply(reminder);

      final loaded = service.loadPreferences();
      expect(loaded.workoutEnabled, true);
      expect(loaded.workoutHour, 18);
    });

    test('cancelAll works with NoOp scheduler', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = ReminderService(prefs, NoOpNotificationScheduler());

      await service.cancelAll();
    });
  });

  group('updateAndApply', () {
    test('saves preferences and applies schedule', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final scheduler = RecordingScheduler(isAvailable: true);
      final service = ReminderService(prefs, scheduler);

      await service.updateAndApply(
        const ReminderPreferences(
          workoutEnabled: true,
          workoutHour: 6,
          workoutMinute: 30,
        ),
      );

      final loaded = service.loadPreferences();
      expect(loaded.workoutEnabled, true);
      expect(loaded.workoutHour, 6);

      expect(scheduler.calls, contains('scheduleDaily:100:6:30'));
    });
  });
}
