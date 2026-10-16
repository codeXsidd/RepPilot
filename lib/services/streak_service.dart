import '../core/constants.dart';
import '../models/workout_session.dart';

class StreakService {
  const StreakService();

  int getCurrentStreak(List<WorkoutSession> sessions, DateTime asOf) {
    final workoutDays = _completedDays(sessions);
    if (workoutDays.isEmpty) return 0;

    var day = stripTime(asOf);
    if (!workoutDays.contains(day)) {
      day = day.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (workoutDays.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int getLongestStreak(List<WorkoutSession> sessions) {
    final workoutDays = _completedDays(sessions);
    if (workoutDays.isEmpty) return 0;

    final sorted = workoutDays.toList()..sort();

    var longest = 1;
    var current = 1;
    for (var i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else if (diff > 1) {
        current = 1;
      }
    }
    return longest;
  }

  int getActiveWeekStreak(List<WorkoutSession> sessions, DateTime asOf) {
    final workoutDays = _completedDays(sessions);
    if (workoutDays.isEmpty) return 0;

    var weekStart = _mondayOf(stripTime(asOf));
    var streak = 0;

    while (true) {
      final weekEnd = weekStart.add(const Duration(days: 6));
      final hasWorkout = workoutDays.any(
        (d) => !d.isBefore(weekStart) && !d.isAfter(weekEnd),
      );
      if (!hasWorkout) break;
      streak++;
      weekStart = weekStart.subtract(const Duration(days: 7));
    }
    return streak;
  }

  int getTotalWorkouts(List<WorkoutSession> sessions) {
    return sessions.where((s) => s.completedAt != null).length;
  }

  List<int> getReachedMilestones(int currentStreak, int totalWorkouts) {
    const streakMilestones = [7, 14, 30, 60, 90, 100, 150, 200, 365];
    const totalMilestones = [10, 25, 50, 100, 200, 500, 1000];

    final reached = <int>[];
    for (final m in streakMilestones) {
      if (currentStreak >= m) reached.add(m);
    }
    for (final m in totalMilestones) {
      if (totalWorkouts >= m) reached.add(m);
    }
    return reached;
  }

  String getMissedDayMessage() {
    return "Rest is part of the journey. Pick up where you left off — "
        "your progress hasn't gone anywhere.";
  }

  String getStreakMessage(int currentStreak) {
    if (currentStreak == 0) {
      return getMissedDayMessage();
    } else if (currentStreak < 7) {
      return 'You are building momentum! $currentStreak day streak.';
    } else if (currentStreak < 30) {
      return 'Great consistency! $currentStreak day streak and counting.';
    } else if (currentStreak < 100) {
      return 'Incredible dedication! $currentStreak day streak.';
    } else {
      return 'Legendary! $currentStreak day streak. Truly committed.';
    }
  }

  Set<DateTime> _completedDays(List<WorkoutSession> sessions) {
    return sessions
        .where((s) => s.completedAt != null)
        .map((s) => stripTime(s.completedAt!))
        .toSet();
  }

  DateTime _mondayOf(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
}
