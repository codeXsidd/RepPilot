import 'package:flutter_test/flutter_test.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/workout_session.dart';
import 'package:rep_pilot/services/streak_service.dart';

void main() {
  const service = StreakService();

  final now = DateTime(2025, 7, 10, 15, 0, 0);

  WorkoutSession makeSession({
    required DateTime completedAt,
    DateTime? startedAt,
  }) {
    return WorkoutSession(
      id: generateId(),
      startedAt: startedAt ?? completedAt.subtract(const Duration(hours: 1)),
      completedAt: completedAt,
      createdAt: completedAt,
      updatedAt: completedAt,
    );
  }

  group('getCurrentStreak', () {
    test('returns 0 for no sessions', () {
      expect(service.getCurrentStreak([], now), 0);
    });

    test('returns 1 when only today has a workout', () {
      final sessions = [makeSession(completedAt: now)];
      expect(service.getCurrentStreak(sessions, now), 1);
    });

    test('returns consecutive days ending today', () {
      final sessions = [
        makeSession(completedAt: DateTime(2025, 7, 8, 10)),
        makeSession(completedAt: DateTime(2025, 7, 9, 10)),
        makeSession(completedAt: DateTime(2025, 7, 10, 10)),
      ];
      expect(service.getCurrentStreak(sessions, now), 3);
    });

    test('counts yesterday if no workout today', () {
      final sessions = [
        makeSession(completedAt: DateTime(2025, 7, 8, 10)),
        makeSession(completedAt: DateTime(2025, 7, 9, 10)),
      ];
      expect(service.getCurrentStreak(sessions, now), 2);
    });

    test('breaks on gap day', () {
      final sessions = [
        makeSession(completedAt: DateTime(2025, 7, 7, 10)),
        makeSession(completedAt: DateTime(2025, 7, 9, 10)),
        makeSession(completedAt: DateTime(2025, 7, 10, 10)),
      ];
      expect(service.getCurrentStreak(sessions, now), 2);
    });

    test('ignores incomplete sessions', () {
      final sessions = [
        WorkoutSession(
          id: generateId(),
          startedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      expect(service.getCurrentStreak(sessions, now), 0);
    });

    test('multiple sessions on same day count as one day', () {
      final sessions = [
        makeSession(completedAt: DateTime(2025, 7, 10, 8)),
        makeSession(completedAt: DateTime(2025, 7, 10, 18)),
      ];
      expect(service.getCurrentStreak(sessions, now), 1);
    });

    test('returns 0 when last workout was 2+ days ago', () {
      final sessions = [makeSession(completedAt: DateTime(2025, 7, 5, 10))];
      expect(service.getCurrentStreak(sessions, now), 0);
    });

    test('handles long streak', () {
      final sessions = <WorkoutSession>[];
      for (var i = 0; i < 30; i++) {
        sessions.add(
          makeSession(
            completedAt: DateTime(2025, 7, 10).subtract(Duration(days: i)),
          ),
        );
      }
      expect(service.getCurrentStreak(sessions, now), 30);
    });
  });

  group('getLongestStreak', () {
    test('returns 0 for no sessions', () {
      expect(service.getLongestStreak([]), 0);
    });

    test('returns 1 for single session', () {
      final sessions = [makeSession(completedAt: DateTime(2025, 1, 1))];
      expect(service.getLongestStreak(sessions), 1);
    });

    test('finds longest streak in history', () {
      final sessions = [
        makeSession(completedAt: DateTime(2025, 1, 1)),
        makeSession(completedAt: DateTime(2025, 1, 2)),
        makeSession(completedAt: DateTime(2025, 1, 3)),
        makeSession(completedAt: DateTime(2025, 1, 10)),
        makeSession(completedAt: DateTime(2025, 1, 11)),
      ];
      expect(service.getLongestStreak(sessions), 3);
    });

    test('handles multiple equal streaks', () {
      final sessions = [
        makeSession(completedAt: DateTime(2025, 1, 1)),
        makeSession(completedAt: DateTime(2025, 1, 2)),
        makeSession(completedAt: DateTime(2025, 1, 10)),
        makeSession(completedAt: DateTime(2025, 1, 11)),
      ];
      expect(service.getLongestStreak(sessions), 2);
    });

    test('deduplicates same-day sessions', () {
      final sessions = [
        makeSession(completedAt: DateTime(2025, 1, 1, 8)),
        makeSession(completedAt: DateTime(2025, 1, 1, 18)),
        makeSession(completedAt: DateTime(2025, 1, 2, 10)),
      ];
      expect(service.getLongestStreak(sessions), 2);
    });
  });

  group('getActiveWeekStreak', () {
    test('returns 0 for no sessions', () {
      expect(service.getActiveWeekStreak([], now), 0);
    });

    test('returns 1 for workout this week only', () {
      final sessions = [makeSession(completedAt: DateTime(2025, 7, 7, 10))];
      expect(service.getActiveWeekStreak(sessions, now), 1);
    });

    test('counts consecutive active weeks', () {
      final sessions = [
        makeSession(completedAt: DateTime(2025, 7, 10, 10)),
        makeSession(completedAt: DateTime(2025, 7, 3, 10)),
        makeSession(completedAt: DateTime(2025, 6, 26, 10)),
      ];
      expect(service.getActiveWeekStreak(sessions, now), 3);
    });

    test('breaks on inactive week', () {
      final sessions = [
        makeSession(completedAt: DateTime(2025, 7, 10, 10)),
        makeSession(completedAt: DateTime(2025, 6, 26, 10)),
      ];
      expect(service.getActiveWeekStreak(sessions, now), 1);
    });
  });

  group('getTotalWorkouts', () {
    test('returns 0 for empty', () {
      expect(service.getTotalWorkouts([]), 0);
    });

    test('counts only completed sessions', () {
      final sessions = [
        makeSession(completedAt: DateTime(2025, 1, 1)),
        WorkoutSession(
          id: generateId(),
          startedAt: DateTime(2025, 1, 2),
          createdAt: DateTime(2025, 1, 2),
          updatedAt: DateTime(2025, 1, 2),
        ),
        makeSession(completedAt: DateTime(2025, 1, 3)),
      ];
      expect(service.getTotalWorkouts(sessions), 2);
    });
  });

  group('getReachedMilestones', () {
    test('returns empty for low values', () {
      expect(service.getReachedMilestones(3, 5), isEmpty);
    });

    test('returns streak milestones', () {
      final milestones = service.getReachedMilestones(30, 5);
      expect(milestones, contains(7));
      expect(milestones, contains(14));
      expect(milestones, contains(30));
      expect(milestones, isNot(contains(60)));
    });

    test('returns total workout milestones', () {
      final milestones = service.getReachedMilestones(0, 50);
      expect(milestones, contains(10));
      expect(milestones, contains(25));
      expect(milestones, contains(50));
      expect(milestones, isNot(contains(100)));
    });

    test('returns both streak and total milestones', () {
      final milestones = service.getReachedMilestones(100, 200);
      expect(milestones, contains(7));
      expect(milestones, contains(100));
      expect(milestones, contains(200));
    });
  });

  group('streak messages', () {
    test('getMissedDayMessage is supportive', () {
      final msg = service.getMissedDayMessage();
      expect(msg, isNotEmpty);
      expect(msg.toLowerCase(), isNot(contains('shame')));
      expect(msg.toLowerCase(), isNot(contains('lazy')));
      expect(msg.toLowerCase(), isNot(contains('fail')));
    });

    test('getStreakMessage for zero returns supportive message', () {
      final msg = service.getStreakMessage(0);
      expect(msg, isNotEmpty);
      expect(msg.toLowerCase(), isNot(contains('shame')));
    });

    test('getStreakMessage for short streak shows encouragement', () {
      final msg = service.getStreakMessage(3);
      expect(msg, contains('3'));
    });

    test('getStreakMessage for long streak shows recognition', () {
      final msg = service.getStreakMessage(100);
      expect(msg, contains('100'));
    });
  });

  group('date handling', () {
    test('streak handles timezone midnight correctly', () {
      final sessions = [
        makeSession(completedAt: DateTime(2025, 7, 9, 23, 59, 59)),
        makeSession(completedAt: DateTime(2025, 7, 10, 0, 0, 1)),
      ];
      expect(service.getCurrentStreak(sessions, now), 2);
    });

    test('streak handles month boundary', () {
      final sessions = [
        makeSession(completedAt: DateTime(2025, 6, 30, 10)),
        makeSession(completedAt: DateTime(2025, 7, 1, 10)),
      ];
      final asOf = DateTime(2025, 7, 1, 12);
      expect(service.getCurrentStreak(sessions, asOf), 2);
    });

    test('streak handles year boundary', () {
      final sessions = [
        makeSession(completedAt: DateTime(2024, 12, 31, 10)),
        makeSession(completedAt: DateTime(2025, 1, 1, 10)),
      ];
      final asOf = DateTime(2025, 1, 1, 12);
      expect(service.getCurrentStreak(sessions, asOf), 2);
    });
  });
}
