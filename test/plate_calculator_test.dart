import 'package:flutter_test/flutter_test.dart';

void main() {
  List<double> calculatePlatesPerSide(
    double target,
    double barWeight,
    List<double> availablePlates,
  ) {
    if (target < barWeight) return [];
    final remaining = (target - barWeight) / 2;
    final sorted = List<double>.from(availablePlates)
      ..sort((a, b) => b.compareTo(a));

    final plates = <double>[];
    var left = remaining;
    for (final plate in sorted) {
      while (left >= plate - 0.001) {
        plates.add(plate);
        left -= plate;
      }
    }
    return plates;
  }

  group('Plate calculator', () {
    const allPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

    test('bar only needs no plates', () {
      final result = calculatePlatesPerSide(20, 20, allPlates);
      expect(result, isEmpty);
    });

    test('60 kg with 20 kg bar = 20 kg per side', () {
      final result = calculatePlatesPerSide(60, 20, allPlates);
      expect(result, [20.0]);
    });

    test('100 kg with 20 kg bar = 40 kg per side', () {
      final result = calculatePlatesPerSide(100, 20, allPlates);
      expect(result, [25.0, 15.0]);
    });

    test('target below bar weight returns empty', () {
      final result = calculatePlatesPerSide(10, 20, allPlates);
      expect(result, isEmpty);
    });

    test('odd weight uses smallest plates', () {
      final result = calculatePlatesPerSide(22.5, 20, allPlates);
      expect(result, [1.25]);
    });

    test('handles 15 kg bar', () {
      final result = calculatePlatesPerSide(55, 15, allPlates);
      expect(result, [20.0]);
    });

    test('complex combination', () {
      final result = calculatePlatesPerSide(142.5, 20, allPlates);
      final perSide = 61.25;
      final total = result.fold(0.0, (a, b) => a + b);
      expect(total, closeTo(perSide, 0.01));
    });

    test('limited plates still work', () {
      final result = calculatePlatesPerSide(40, 20, [10.0, 5.0]);
      expect(result, [10.0]);
    });

    test('empty available plates with bar-only target', () {
      final result = calculatePlatesPerSide(20, 20, []);
      expect(result, isEmpty);
    });

    test('multiple same plates needed', () {
      final result = calculatePlatesPerSide(60, 20, [10.0, 5.0]);
      expect(result, [10.0, 10.0]);
    });
  });
}
