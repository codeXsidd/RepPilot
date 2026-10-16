import 'package:flutter_test/flutter_test.dart';

import 'package:rep_pilot/services/rest_timer_service.dart';

void main() {
  late RestTimerService timer;

  setUp(() {
    timer = RestTimerService();
  });

  tearDown(() {
    timer.dispose();
  });

  group('initial state', () {
    test('starts idle', () {
      expect(timer.isRunning, false);
      expect(timer.isPaused, false);
      expect(timer.isComplete, false);
      expect(timer.remainingSeconds, 0);
      expect(timer.totalSeconds, 0);
      expect(timer.progress, 0.0);
    });
  });

  group('start', () {
    test('sets running state', () {
      timer.start(60);
      expect(timer.isRunning, true);
      expect(timer.isPaused, false);
      expect(timer.totalSeconds, 60);
      expect(timer.remainingSeconds, 60);
    });

    test('ignores zero or negative durations', () {
      timer.start(0);
      expect(timer.isRunning, false);

      timer.start(-5);
      expect(timer.isRunning, false);
    });

    test('restart replaces existing timer', () {
      timer.start(60);
      timer.start(30);
      expect(timer.totalSeconds, 30);
      expect(timer.remainingSeconds, 30);
    });
  });

  group('pause and resume', () {
    test('pauses a running timer', () {
      timer.start(60);
      timer.pause();
      expect(timer.isPaused, true);
      expect(timer.isRunning, true);
    });

    test('resumes a paused timer', () {
      timer.start(60);
      timer.pause();
      timer.resume();
      expect(timer.isPaused, false);
      expect(timer.isRunning, true);
    });

    test('pause is no-op when not running', () {
      timer.pause();
      expect(timer.isPaused, false);
    });

    test('pause is no-op when already paused', () {
      timer.start(60);
      timer.pause();
      timer.pause();
      expect(timer.isPaused, true);
    });

    test('resume is no-op when not paused', () {
      timer.start(60);
      timer.resume();
      expect(timer.isPaused, false);
      expect(timer.isRunning, true);
    });

    test('resume is no-op when not running', () {
      timer.resume();
      expect(timer.isRunning, false);
    });
  });

  group('reset', () {
    test('resets all state', () {
      timer.start(60);
      timer.reset();
      expect(timer.isRunning, false);
      expect(timer.isPaused, false);
      expect(timer.remainingSeconds, 0);
      expect(timer.totalSeconds, 0);
    });

    test('reset from paused state', () {
      timer.start(60);
      timer.pause();
      timer.reset();
      expect(timer.isRunning, false);
      expect(timer.isPaused, false);
    });
  });

  group('progress', () {
    test('progress is 0 at start', () {
      timer.start(60);
      expect(timer.progress, 0.0);
    });

    test('progress is 0 when totalSeconds is 0', () {
      expect(timer.progress, 0.0);
    });
  });

  group('countdown', () {
    testWidgets('counts down by 1 each second', (tester) async {
      timer.start(3);
      expect(timer.remainingSeconds, 3);

      await tester.pump(const Duration(seconds: 1));
      expect(timer.remainingSeconds, 2);

      await tester.pump(const Duration(seconds: 1));
      expect(timer.remainingSeconds, 1);

      await tester.pump(const Duration(seconds: 1));
      expect(timer.remainingSeconds, 0);
      expect(timer.isRunning, false);
      expect(timer.isComplete, true);
    });

    testWidgets('pause freezes countdown', (tester) async {
      timer.start(5);

      await tester.pump(const Duration(seconds: 1));
      expect(timer.remainingSeconds, 4);

      timer.pause();
      await tester.pump(const Duration(seconds: 2));
      expect(timer.remainingSeconds, 4);

      timer.resume();
      await tester.pump(const Duration(seconds: 1));
      expect(timer.remainingSeconds, 3);

      timer.reset();
    });

    testWidgets('isComplete is true only after full countdown', (tester) async {
      timer.start(2);

      await tester.pump(const Duration(seconds: 1));
      expect(timer.isComplete, false);

      await tester.pump(const Duration(seconds: 1));
      expect(timer.isComplete, true);
    });

    testWidgets('reset during countdown stops it', (tester) async {
      timer.start(5);

      await tester.pump(const Duration(seconds: 2));
      timer.reset();

      await tester.pump(const Duration(seconds: 2));
      expect(timer.remainingSeconds, 0);
      expect(timer.isRunning, false);
      expect(timer.isComplete, false);
    });
  });

  group('notifications', () {
    test('notifies listeners on start', () {
      var notified = false;
      timer.addListener(() => notified = true);
      timer.start(60);
      expect(notified, true);
    });

    test('notifies listeners on pause', () {
      timer.start(60);
      var notified = false;
      timer.addListener(() => notified = true);
      timer.pause();
      expect(notified, true);
    });

    test('notifies listeners on resume', () {
      timer.start(60);
      timer.pause();
      var notified = false;
      timer.addListener(() => notified = true);
      timer.resume();
      expect(notified, true);
    });

    test('notifies listeners on reset', () {
      timer.start(60);
      var notified = false;
      timer.addListener(() => notified = true);
      timer.reset();
      expect(notified, true);
    });
  });
}
