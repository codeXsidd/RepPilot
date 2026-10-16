import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TrainingLevel {
  beginner,
  intermediate,
  advanced;

  String get label => switch (this) {
    beginner => 'Beginner',
    intermediate => 'Intermediate',
    advanced => 'Advanced',
  };

  String get description => switch (this) {
    beginner => 'New to strength training. Simpler exercises, guided rep ranges, conservative progression.',
    intermediate => 'Consistent training for 6+ months. Full exercise library, standard progression.',
    advanced => 'Years of training experience. Advanced techniques, aggressive progression, RPE-based programming.',
  };

  int get defaultSets => switch (this) {
    beginner => 3,
    intermediate => 4,
    advanced => 5,
  };

  int get defaultRepsMin => switch (this) {
    beginner => 10,
    intermediate => 6,
    advanced => 3,
  };

  int get defaultRepsMax => switch (this) {
    beginner => 15,
    intermediate => 12,
    advanced => 8,
  };

  double get defaultIncrementKg => switch (this) {
    beginner => 2.5,
    intermediate => 2.5,
    advanced => 1.25,
  };

  String get suggestedDifficulty => switch (this) {
    beginner => 'beginner',
    intermediate => 'intermediate',
    advanced => 'advanced',
  };
}

class TrainingLevelService extends ChangeNotifier {
  static const String _prefKey = 'training_level';

  TrainingLevel _level;
  final SharedPreferences _prefs;

  TrainingLevelService._(this._prefs, this._level);

  factory TrainingLevelService.withPrefs(SharedPreferences prefs) {
    final stored = prefs.getString(_prefKey);
    final level = _parse(stored);
    return TrainingLevelService._(prefs, level);
  }

  TrainingLevel get level => _level;

  Future<void> setLevel(TrainingLevel level) async {
    if (_level == level) return;
    _level = level;
    await _prefs.setString(_prefKey, level.name);
    notifyListeners();
  }

  static TrainingLevel _parse(String? value) {
    return switch (value) {
      'beginner' => TrainingLevel.beginner,
      'advanced' => TrainingLevel.advanced,
      _ => TrainingLevel.intermediate,
    };
  }
}
