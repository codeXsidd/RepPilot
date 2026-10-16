import 'package:flutter_test/flutter_test.dart';

import 'package:rep_pilot/core/constants.dart';

void main() {
  group('weight conversion', () {
    test('kgToLb converts correctly', () {
      expect(kgToLb(1.0), closeTo(2.20462, 0.001));
      expect(kgToLb(100.0), closeTo(220.462, 0.01));
    });

    test('lbToKg converts correctly', () {
      expect(lbToKg(220.462), closeTo(100.0, 0.01));
    });

    test('round-trip preserves value', () {
      expect(lbToKg(kgToLb(75.0)), closeTo(75.0, 0.001));
    });

    test('displayWeight selects correct unit', () {
      expect(displayWeight(75.0, 'kg'), 75.0);
      expect(displayWeight(75.0, 'lb'), closeTo(165.35, 0.01));
    });

    test('storageWeight converts to kg', () {
      expect(storageWeight(75.0, 'kg'), 75.0);
      expect(storageWeight(165.35, 'lb'), closeTo(75.0, 0.1));
    });
  });

  group('date formatting', () {
    test('formatDateOnly produces YYYY-MM-DD', () {
      expect(formatDateOnly(DateTime(2025, 1, 5)), '2025-01-05');
      expect(formatDateOnly(DateTime(2025, 12, 31)), '2025-12-31');
    });

    test('parseDateOnly parses correctly', () {
      final dt = parseDateOnly('2025-06-15');
      expect(dt.year, 2025);
      expect(dt.month, 6);
      expect(dt.day, 15);
    });

    test('stripTime removes time component', () {
      final dt = stripTime(DateTime(2025, 6, 15, 14, 30, 45));
      expect(dt.hour, 0);
      expect(dt.minute, 0);
      expect(dt.second, 0);
    });
  });
}
