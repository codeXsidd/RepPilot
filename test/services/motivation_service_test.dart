import 'package:flutter_test/flutter_test.dart';

import 'package:rep_pilot/core/data/motivational_messages.dart';
import 'package:rep_pilot/services/motivation_service.dart';

void main() {
  const service = MotivationService();

  group('getMessageForDate', () {
    test('returns a non-empty string', () {
      final msg = service.getMessageForDate(DateTime(2025, 7, 1));
      expect(msg, isNotEmpty);
    });

    test('returns same message for same date', () {
      final a = service.getMessageForDate(DateTime(2025, 7, 1));
      final b = service.getMessageForDate(DateTime(2025, 7, 1));
      expect(a, b);
    });

    test('returns same message regardless of time of day', () {
      final morning = service.getMessageForDate(DateTime(2025, 7, 1, 6, 0, 0));
      final evening = service.getMessageForDate(
        DateTime(2025, 7, 1, 23, 59, 59),
      );
      expect(morning, evening);
    });

    test('returns different messages for different dates', () {
      final messages = <String>{};
      for (var d = 1; d <= 30; d++) {
        messages.add(service.getMessageForDate(DateTime(2025, 7, d)));
      }
      expect(messages.length, greaterThan(1));
    });

    test('message exists in the pool', () {
      final msg = service.getMessageForDate(DateTime(2025, 7, 15));
      expect(motivationalMessages, contains(msg));
    });

    test('handles year boundaries', () {
      final dec31 = service.getMessageForDate(DateTime(2025, 12, 31));
      final jan1 = service.getMessageForDate(DateTime(2026, 1, 1));
      expect(dec31, isNotEmpty);
      expect(jan1, isNotEmpty);
    });

    test('handles leap year', () {
      final feb29 = service.getMessageForDate(DateTime(2024, 2, 29));
      expect(feb29, isNotEmpty);
      expect(motivationalMessages, contains(feb29));
    });

    test('is stable across calls in a loop', () {
      final date = DateTime(2025, 8, 15);
      final first = service.getMessageForDate(date);
      for (var i = 0; i < 100; i++) {
        expect(service.getMessageForDate(date), first);
      }
    });

    test('cycles through messages over long range', () {
      final seen = <String>{};
      for (var d = 0; d < 365; d++) {
        seen.add(
          service.getMessageForDate(
            DateTime(2025, 1, 1).add(Duration(days: d)),
          ),
        );
      }
      expect(seen.length, motivationalMessages.length);
    });
  });

  group('message pool', () {
    test('contains at least 100 messages', () {
      expect(motivationalMessages.length, greaterThanOrEqualTo(100));
    });

    test('all messages are non-empty', () {
      for (final msg in motivationalMessages) {
        expect(msg, isNotEmpty);
      }
    });

    test('no duplicate messages', () {
      final unique = motivationalMessages.toSet();
      expect(unique.length, motivationalMessages.length);
    });

    test('totalMessages matches pool size', () {
      expect(service.totalMessages, motivationalMessages.length);
    });
  });
}
