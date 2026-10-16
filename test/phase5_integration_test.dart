import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/body_measurement.dart';
import 'package:rep_pilot/models/body_weight_entry.dart';
import 'package:rep_pilot/repositories/body_measurement_repository.dart';
import 'package:rep_pilot/repositories/body_weight_repository.dart';
import 'package:rep_pilot/services/weight_analytics_service.dart';

import 'helpers/test_database.dart';

void main() {
  late Database db;
  late BodyWeightRepository bwRepo;
  late BodyMeasurementRepository bmRepo;
  const analytics = WeightAnalyticsService();

  final now = DateTime(2025, 7, 1, 10, 0, 0);

  setUp(() async {
    db = await openTestDatabase();
    bwRepo = BodyWeightRepository(db);
    bmRepo = BodyMeasurementRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('body weight entry lifecycle', () {
    test('create, read, update, delete weight entry', () async {
      final entry = BodyWeightEntry(
        id: generateId(),
        date: stripTime(DateTime(2025, 7, 1)),
        weightKg: 75.0,
        notes: 'morning',
        createdAt: now,
        updatedAt: now,
      );

      await bwRepo.create(entry);
      var fetched = await bwRepo.getById(entry.id);
      expect(fetched!.weightKg, 75.0);
      expect(fetched.notes, 'morning');

      final updated = entry.copyWith(weightKg: 74.5, notes: 'adjusted');
      await bwRepo.update(updated);
      fetched = await bwRepo.getById(entry.id);
      expect(fetched!.weightKg, 74.5);
      expect(fetched.notes, 'adjusted');

      await bwRepo.delete(entry.id);
      fetched = await bwRepo.getById(entry.id);
      expect(fetched, isNull);
    });

    test('upsertByDate creates and then updates', () async {
      final entry = BodyWeightEntry(
        id: generateId(),
        date: stripTime(DateTime(2025, 7, 1)),
        weightKg: 75.0,
        createdAt: now,
        updatedAt: now,
      );

      await bwRepo.upsertByDate(entry);
      var all = await bwRepo.getAll();
      expect(all.length, 1);

      final replacement = BodyWeightEntry(
        id: generateId(),
        date: stripTime(DateTime(2025, 7, 1)),
        weightKg: 74.0,
        createdAt: now,
        updatedAt: now,
      );
      await bwRepo.upsertByDate(replacement);
      all = await bwRepo.getAll();
      expect(all.length, 1);
      expect(all.first.weightKg, 74.0);
    });

    test('getLatest returns most recent', () async {
      await bwRepo.create(
        BodyWeightEntry(
          id: generateId(),
          date: stripTime(DateTime(2025, 6, 28)),
          weightKg: 76.0,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await bwRepo.create(
        BodyWeightEntry(
          id: generateId(),
          date: stripTime(DateTime(2025, 7, 1)),
          weightKg: 75.0,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final latest = await bwRepo.getLatest();
      expect(latest, isNotNull);
      expect(latest!.date, DateTime(2025, 7, 1));
    });
  });

  group('body measurement lifecycle', () {
    test('create, read, update, delete measurement', () async {
      final m = BodyMeasurement(
        id: generateId(),
        date: stripTime(DateTime(2025, 7, 1)),
        waistCm: 80.0,
        chestCm: 95.0,
        leftArmCm: 35.0,
        rightArmCm: 35.5,
        hipsCm: 90.0,
        notes: 'morning',
        createdAt: now,
        updatedAt: now,
      );

      await bmRepo.create(m);
      var fetched = await bmRepo.getById(m.id);
      expect(fetched!.waistCm, 80.0);
      expect(fetched.chestCm, 95.0);
      expect(fetched.leftArmCm, 35.0);
      expect(fetched.rightArmCm, 35.5);
      expect(fetched.hipsCm, 90.0);

      final updated = m.copyWith(waistCm: 79.0, updatedAt: now);
      await bmRepo.update(updated);
      fetched = await bmRepo.getById(m.id);
      expect(fetched!.waistCm, 79.0);

      await bmRepo.delete(m.id);
      fetched = await bmRepo.getById(m.id);
      expect(fetched, isNull);
    });

    test('upsertByDate creates and then updates measurement', () async {
      final m = BodyMeasurement(
        id: generateId(),
        date: stripTime(DateTime(2025, 7, 1)),
        waistCm: 80.0,
        createdAt: now,
        updatedAt: now,
      );
      await bmRepo.upsertByDate(m);
      var all = await bmRepo.getAll();
      expect(all.length, 1);

      final replacement = BodyMeasurement(
        id: generateId(),
        date: stripTime(DateTime(2025, 7, 1)),
        waistCm: 78.0,
        chestCm: 96.0,
        createdAt: now,
        updatedAt: now,
      );
      await bmRepo.upsertByDate(replacement);
      all = await bmRepo.getAll();
      expect(all.length, 1);
      expect(all.first.waistCm, 78.0);
      expect(all.first.chestCm, 96.0);
    });

    test('getLatest returns most recent measurement', () async {
      await bmRepo.create(
        BodyMeasurement(
          id: generateId(),
          date: stripTime(DateTime(2025, 6, 28)),
          waistCm: 81.0,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await bmRepo.create(
        BodyMeasurement(
          id: generateId(),
          date: stripTime(DateTime(2025, 7, 1)),
          waistCm: 80.0,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final latest = await bmRepo.getLatest();
      expect(latest, isNotNull);
      expect(latest!.date, DateTime(2025, 7, 1));
    });

    test('partial measurements round-trip correctly', () async {
      final m = BodyMeasurement(
        id: generateId(),
        date: stripTime(now),
        waistCm: 80.0,
        createdAt: now,
        updatedAt: now,
      );
      await bmRepo.create(m);

      final fetched = await bmRepo.getById(m.id);
      expect(fetched!.waistCm, 80.0);
      expect(fetched.chestCm, isNull);
      expect(fetched.leftArmCm, isNull);
      expect(fetched.rightArmCm, isNull);
      expect(fetched.hipsCm, isNull);
    });
  });

  group('weight analytics integration', () {
    test('7-day average computed from real DB entries', () async {
      for (var i = 0; i < 7; i++) {
        await bwRepo.create(
          BodyWeightEntry(
            id: generateId(),
            date: stripTime(DateTime(2025, 6, 25 + i)),
            weightKg: 70.0 + i,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final entries = await bwRepo.getAll();
      final avg = analytics.getSevenDayAverage(entries, DateTime(2025, 7, 1));
      expect(avg, isNotNull);
      expect(avg, closeTo(73.0, 0.01));
    });

    test('weight change computed from real DB entries', () async {
      await bwRepo.create(
        BodyWeightEntry(
          id: generateId(),
          date: stripTime(DateTime(2025, 6, 1)),
          weightKg: 75.0,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await bwRepo.create(
        BodyWeightEntry(
          id: generateId(),
          date: stripTime(DateTime(2025, 7, 1)),
          weightKg: 73.0,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final entries = await bwRepo.getAll();
      final change = analytics.getWeightChange(entries);
      expect(change, isNotNull);
      expect(change!.change, closeTo(-2.0, 0.01));
      expect(change.days, 30);
    });

    test('chart data preparation with lb conversion', () async {
      await bwRepo.create(
        BodyWeightEntry(
          id: generateId(),
          date: stripTime(DateTime(2025, 7, 1)),
          weightKg: 70.0,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final entries = await bwRepo.getAll();
      final chartData = analytics.prepareChartData(entries, 'lb');
      expect(chartData.length, 1);
      expect(chartData[0].value, closeTo(kgToLb(70.0), 0.01));
    });

    test('moving average from date-ranged entries', () async {
      for (var i = 0; i < 10; i++) {
        await bwRepo.create(
          BodyWeightEntry(
            id: generateId(),
            date: stripTime(DateTime(2025, 6, 22 + i)),
            weightKg: 70.0 + i * 0.5,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final range = await bwRepo.getByDateRange(
        DateTime(2025, 6, 25),
        DateTime(2025, 7, 1),
      );
      expect(range.length, 7);

      final movingAvg = analytics.calculateMovingAverage(range, 3);
      expect(movingAvg.length, 7);
      expect(movingAvg.last.average, isNotNull);
    });
  });

  group('date filtering', () {
    test('getByDateRange for body weight entries', () async {
      for (var i = 0; i < 10; i++) {
        await bwRepo.create(
          BodyWeightEntry(
            id: generateId(),
            date: stripTime(DateTime(2025, 6, 22 + i)),
            weightKg: 70.0 + i,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final range = await bwRepo.getByDateRange(
        DateTime(2025, 6, 25),
        DateTime(2025, 6, 28),
      );
      expect(range.length, 4);
      expect(range.first.date, DateTime(2025, 6, 25));
      expect(range.last.date, DateTime(2025, 6, 28));
    });

    test('getByDateRange for body measurements', () async {
      for (var i = 0; i < 5; i++) {
        await bmRepo.create(
          BodyMeasurement(
            id: generateId(),
            date: stripTime(DateTime(2025, 6, 25 + i)),
            waistCm: 80.0 - i,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final range = await bmRepo.getByDateRange(
        DateTime(2025, 6, 26),
        DateTime(2025, 6, 28),
      );
      expect(range.length, 3);
      expect(range.first.date, DateTime(2025, 6, 26));
    });
  });

  group('empty state handling', () {
    test('analytics handle empty weight entries gracefully', () {
      expect(analytics.getSevenDayAverage([], now), isNull);
      expect(analytics.getWeightChange([]), isNull);
      expect(analytics.calculateMovingAverage([], 7), isEmpty);
      expect(analytics.prepareChartData([], 'kg'), isEmpty);
    });

    test('getLatest returns null for empty tables', () async {
      expect(await bwRepo.getLatest(), isNull);
      expect(await bmRepo.getLatest(), isNull);
    });

    test('getAll returns empty for empty tables', () async {
      expect(await bwRepo.getAll(), isEmpty);
      expect(await bmRepo.getAll(), isEmpty);
    });
  });

  group('unit conversion', () {
    test('displayWeight converts kg to lb correctly', () {
      expect(displayWeight(70.0, 'kg'), 70.0);
      expect(displayWeight(70.0, 'lb'), closeTo(154.32, 0.1));
    });

    test('storageWeight converts lb to kg correctly', () {
      expect(storageWeight(70.0, 'kg'), 70.0);
      expect(storageWeight(154.32, 'lb'), closeTo(70.0, 0.1));
    });

    test('round-trip conversion preserves value', () {
      const original = 75.0;
      final lb = displayWeight(original, 'lb');
      final backToKg = storageWeight(lb, 'lb');
      expect(backToKg, closeTo(original, 0.01));
    });
  });
}
