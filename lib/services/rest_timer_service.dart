import 'dart:async';

import 'package:flutter/foundation.dart';

class RestTimerService extends ChangeNotifier {
  int _totalSeconds = 0;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  Timer? _timer;

  int get totalSeconds => _totalSeconds;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  bool get isComplete =>
      !_isRunning && !_isPaused && _totalSeconds > 0 && _remainingSeconds == 0;

  double get progress {
    if (_totalSeconds == 0) return 0;
    return 1.0 - (_remainingSeconds / _totalSeconds);
  }

  void start(int seconds) {
    if (seconds <= 0) return;
    _timer?.cancel();
    _totalSeconds = seconds;
    _remainingSeconds = seconds;
    _isRunning = true;
    _isPaused = false;
    _startTicking();
    notifyListeners();
  }

  void pause() {
    if (!_isRunning || _isPaused) return;
    _timer?.cancel();
    _isPaused = true;
    notifyListeners();
  }

  void resume() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;
    _startTicking();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _totalSeconds = 0;
    _remainingSeconds = 0;
    _isRunning = false;
    _isPaused = false;
    notifyListeners();
  }

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
        if (_remainingSeconds == 0) {
          _timer?.cancel();
          _isRunning = false;
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
