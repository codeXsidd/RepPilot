import 'package:shared_preferences/shared_preferences.dart';

class ReminderPreferences {
  final bool workoutEnabled;
  final int workoutHour;
  final int workoutMinute;
  final bool weightEnabled;
  final int weightHour;
  final int weightMinute;
  final bool waterEnabled;
  final int waterIntervalHours;
  final int waterStartHour;
  final int waterEndHour;

  const ReminderPreferences({
    this.workoutEnabled = false,
    this.workoutHour = 7,
    this.workoutMinute = 0,
    this.weightEnabled = false,
    this.weightHour = 7,
    this.weightMinute = 30,
    this.waterEnabled = false,
    this.waterIntervalHours = 2,
    this.waterStartHour = 8,
    this.waterEndHour = 22,
  });

  ReminderPreferences copyWith({
    bool? workoutEnabled,
    int? workoutHour,
    int? workoutMinute,
    bool? weightEnabled,
    int? weightHour,
    int? weightMinute,
    bool? waterEnabled,
    int? waterIntervalHours,
    int? waterStartHour,
    int? waterEndHour,
  }) {
    return ReminderPreferences(
      workoutEnabled: workoutEnabled ?? this.workoutEnabled,
      workoutHour: workoutHour ?? this.workoutHour,
      workoutMinute: workoutMinute ?? this.workoutMinute,
      weightEnabled: weightEnabled ?? this.weightEnabled,
      weightHour: weightHour ?? this.weightHour,
      weightMinute: weightMinute ?? this.weightMinute,
      waterEnabled: waterEnabled ?? this.waterEnabled,
      waterIntervalHours: waterIntervalHours ?? this.waterIntervalHours,
      waterStartHour: waterStartHour ?? this.waterStartHour,
      waterEndHour: waterEndHour ?? this.waterEndHour,
    );
  }
}

abstract class NotificationScheduler {
  Future<bool> initialize();
  Future<bool> requestPermission();
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  });
  Future<void> scheduleRepeating({
    required int id,
    required String title,
    required String body,
    required int intervalHours,
    required int startHour,
    required int endHour,
  });
  Future<void> cancel(int id);
  Future<void> cancelAll();
  bool get isAvailable;
}

class NoOpNotificationScheduler implements NotificationScheduler {
  @override
  Future<bool> initialize() async => false;
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {}
  @override
  Future<void> scheduleRepeating({
    required int id,
    required String title,
    required String body,
    required int intervalHours,
    required int startHour,
    required int endHour,
  }) async {}
  @override
  Future<void> cancel(int id) async {}
  @override
  Future<void> cancelAll() async {}
  @override
  bool get isAvailable => false;
}

class ReminderService {
  static const _keyWorkoutEnabled = 'reminder_workout_enabled';
  static const _keyWorkoutHour = 'reminder_workout_hour';
  static const _keyWorkoutMinute = 'reminder_workout_minute';
  static const _keyWeightEnabled = 'reminder_weight_enabled';
  static const _keyWeightHour = 'reminder_weight_hour';
  static const _keyWeightMinute = 'reminder_weight_minute';
  static const _keyWaterEnabled = 'reminder_water_enabled';
  static const _keyWaterInterval = 'reminder_water_interval_hours';
  static const _keyWaterStart = 'reminder_water_start_hour';
  static const _keyWaterEnd = 'reminder_water_end_hour';

  static const workoutNotificationId = 100;
  static const weightNotificationId = 200;
  static const waterNotificationIdBase = 300;

  final SharedPreferences _prefs;
  final NotificationScheduler _scheduler;

  ReminderService(this._prefs, this._scheduler);

  bool get notificationsAvailable => _scheduler.isAvailable;

  ReminderPreferences loadPreferences() {
    return ReminderPreferences(
      workoutEnabled: _prefs.getBool(_keyWorkoutEnabled) ?? false,
      workoutHour: _prefs.getInt(_keyWorkoutHour) ?? 7,
      workoutMinute: _prefs.getInt(_keyWorkoutMinute) ?? 0,
      weightEnabled: _prefs.getBool(_keyWeightEnabled) ?? false,
      weightHour: _prefs.getInt(_keyWeightHour) ?? 7,
      weightMinute: _prefs.getInt(_keyWeightMinute) ?? 30,
      waterEnabled: _prefs.getBool(_keyWaterEnabled) ?? false,
      waterIntervalHours: _prefs.getInt(_keyWaterInterval) ?? 2,
      waterStartHour: _prefs.getInt(_keyWaterStart) ?? 8,
      waterEndHour: _prefs.getInt(_keyWaterEnd) ?? 22,
    );
  }

  Future<void> savePreferences(ReminderPreferences prefs) async {
    await _prefs.setBool(_keyWorkoutEnabled, prefs.workoutEnabled);
    await _prefs.setInt(_keyWorkoutHour, prefs.workoutHour);
    await _prefs.setInt(_keyWorkoutMinute, prefs.workoutMinute);
    await _prefs.setBool(_keyWeightEnabled, prefs.weightEnabled);
    await _prefs.setInt(_keyWeightHour, prefs.weightHour);
    await _prefs.setInt(_keyWeightMinute, prefs.weightMinute);
    await _prefs.setBool(_keyWaterEnabled, prefs.waterEnabled);
    await _prefs.setInt(_keyWaterInterval, prefs.waterIntervalHours);
    await _prefs.setInt(_keyWaterStart, prefs.waterStartHour);
    await _prefs.setInt(_keyWaterEnd, prefs.waterEndHour);
  }

  Future<void> applySchedule(ReminderPreferences prefs) async {
    if (!_scheduler.isAvailable) return;

    await _scheduler.cancel(workoutNotificationId);
    await _scheduler.cancel(weightNotificationId);
    for (var i = 0; i < 12; i++) {
      await _scheduler.cancel(waterNotificationIdBase + i);
    }

    if (prefs.workoutEnabled) {
      await _scheduler.scheduleDaily(
        id: workoutNotificationId,
        title: 'Workout Reminder',
        body: 'Time to train! Your scheduled workout is waiting.',
        hour: prefs.workoutHour,
        minute: prefs.workoutMinute,
      );
    }

    if (prefs.weightEnabled) {
      await _scheduler.scheduleDaily(
        id: weightNotificationId,
        title: 'Weigh-in Reminder',
        body: 'Time to log your weight for consistent tracking.',
        hour: prefs.weightHour,
        minute: prefs.weightMinute,
      );
    }

    if (prefs.waterEnabled) {
      await _scheduler.scheduleRepeating(
        id: waterNotificationIdBase,
        title: 'Hydration Reminder',
        body: 'Time to drink some water! Stay hydrated.',
        intervalHours: prefs.waterIntervalHours,
        startHour: prefs.waterStartHour,
        endHour: prefs.waterEndHour,
      );
    }
  }

  Future<void> updateAndApply(ReminderPreferences prefs) async {
    await savePreferences(prefs);
    await applySchedule(prefs);
  }

  Future<void> cancelAll() async {
    await _scheduler.cancelAll();
  }
}
