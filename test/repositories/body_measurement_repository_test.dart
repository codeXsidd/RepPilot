import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/body_measurement.dart';
import 'package:rep_pilot/repositories/body_measurement_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late BodyMeasurementRepository repo;

  final now = DateTime(2025, 7, 1, 10, 0, 0);

  BodyMeasurement makeMeasurement({
    String? id,
    DateTime? date,
    double? waistCm,
    double? chestCm,
    double? leftArmCm,
    double? rightArmCm,
    double? hipsCm,
    String notes = '',
  }) {
    return BodyMeasurement(
      id: id ?? generateId(),
      date: stripTime(date ?? now),
      waistCm: waistCm,
      chestCm: chestCm,
      leftArmCm: leftArmCm,
      rightArmCm: rightArmCm,
      hipsCm: hipsCm,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() async {
    db = await openTestDatabase();
    repo = BodyMeasurementRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CRUD operations', () {
    test('create and getById', () async {
      final m = makeMeasurement(waistCm: 80.0, chestCm: 95.0);
      await repo.create(m);

      final fetched = await repo.getById(m.id);
      expect(fetched, isNotNull);
      expect(fetched!.waistCm, 80.0);
      expect(fetched.chestCm, 95.0);
    });

    test('getById returns null for non-existent id', () async {
      final result = await repo.getById('non-existent');
      expect(result, isNull);
    });

    test('update modifies existing entry', () async {
      final m = makeMeasurement(waistCm: 80.0);
      await repo.create(m);

      final updated = m.copyWith(waistCm: 78.0, updatedAt: now);
      await repo.update(updated);

      final fetched = await repo.getById(m.id);
      expect(fetched!.waistCm, 78.0);
    });

    test('delete removes entry', () async {
      final m = makeMeasurement(waistCm: 80.0);
      await repo.create(m);
      await repo.delete(m.id);

      final fetched = await repo.getById(m.id);
      expect(fetched, isNull);
    });

    test('getAll returns entries ordered by date DESC', () async {
      await repo.create(
        makeMeasurement(date: DateTime(2025, 6, 28), waistCm: 80.0),
      );
      await repo.create(
        makeMeasurement(date: DateTime(2025, 7, 1), waistCm: 79.0),
      );
      await repo.create(
        makeMeasurement(date: DateTime(2025, 6, 30), waistCm: 79.5),
      );

      final all = await repo.getAll();
      expect(all.length, 3);
      expect(all[0].date, DateTime(2025, 7, 1));
      expect(all[1].date, DateTime(2025, 6, 30));
      expect(all[2].date, DateTime(2025, 6, 28));
    });

    test('getAll returns empty list when no entries', () async {
      final all = await repo.getAll();
      expect(all, isEmpty);
    });
  });

  group('getByDate', () {
    test('returns entry for exact date', () async {
      final m = makeMeasurement(date: DateTime(2025, 7, 1), waistCm: 80.0);
      await repo.create(m);

      final fetched = await repo.getByDate(DateTime(2025, 7, 1));
      expect(fetched, isNotNull);
      expect(fetched!.waistCm, 80.0);
    });

    test('returns null when no entry for date', () async {
      final result = await repo.getByDate(DateTime(2025, 7, 1));
      expect(result, isNull);
    });

    test('strips time component for lookup', () async {
      final m = makeMeasurement(date: DateTime(2025, 7, 1), waistCm: 80.0);
      await repo.create(m);

      final fetched = await repo.getByDate(DateTime(2025, 7, 1, 15, 30));
      expect(fetched, isNotNull);
      expect(fetched!.waistCm, 80.0);
    });
  });

  group('getByDateRange', () {
    test('returns entries within range sorted ASC', () async {
      await repo.create(
        makeMeasurement(date: DateTime(2025, 6, 25), waistCm: 82.0),
      );
      await repo.create(
        makeMeasurement(date: DateTime(2025, 6, 28), waistCm: 81.0),
      );
      await repo.create(
        makeMeasurement(date: DateTime(2025, 7, 1), waistCm: 80.0),
      );
      await repo.create(
        makeMeasurement(date: DateTime(2025, 7, 5), waistCm: 79.0),
      );

      final range = await repo.getByDateRange(
        DateTime(2025, 6, 27),
        DateTime(2025, 7, 2),
      );
      expect(range.length, 2);
      expect(range[0].date, DateTime(2025, 6, 28));
      expect(range[1].date, DateTime(2025, 7, 1));
    });

    test('returns empty list when no entries in range', () async {
      await repo.create(
        makeMeasurement(date: DateTime(2025, 7, 1), waistCm: 80.0),
      );

      final range = await repo.getByDateRange(
        DateTime(2025, 8, 1),
        DateTime(2025, 8, 31),
      );
      expect(range, isEmpty);
    });
  });

  group('getLatest', () {
    test('returns most recent entry', () async {
      await repo.create(
        makeMeasurement(date: DateTime(2025, 6, 28), waistCm: 81.0),
      );
      await repo.create(
        makeMeasurement(date: DateTime(2025, 7, 1), waistCm: 80.0),
      );
      await repo.create(
        makeMeasurement(date: DateTime(2025, 6, 30), waistCm: 80.5),
      );

      final latest = await repo.getLatest();
      expect(latest, isNotNull);
      expect(latest!.date, DateTime(2025, 7, 1));
      expect(latest.waistCm, 80.0);
    });

    test('returns null when no entries', () async {
      final latest = await repo.getLatest();
      expect(latest, isNull);
    });
  });

  group('upsertByDate', () {
    test('creates new entry when no entry exists for date', () async {
      final m = makeMeasurement(date: DateTime(2025, 7, 1), waistCm: 80.0);
      final result = await repo.upsertByDate(m);

      expect(result.waistCm, 80.0);
      final all = await repo.getAll();
      expect(all.length, 1);
    });

    test('updates existing entry for same date', () async {
      final original = makeMeasurement(
        date: DateTime(2025, 7, 1),
        waistCm: 80.0,
      );
      await repo.create(original);

      final replacement = makeMeasurement(
        date: DateTime(2025, 7, 1),
        waistCm: 78.5,
        chestCm: 96.0,
      );
      final result = await repo.upsertByDate(replacement);

      expect(result.id, original.id);
      expect(result.waistCm, 78.5);
      expect(result.chestCm, 96.0);

      final all = await repo.getAll();
      expect(all.length, 1);
    });

    test('does not affect entries on other dates', () async {
      await repo.create(
        makeMeasurement(date: DateTime(2025, 6, 30), waistCm: 81.0),
      );

      final m = makeMeasurement(date: DateTime(2025, 7, 1), waistCm: 80.0);
      await repo.upsertByDate(m);

      final all = await repo.getAll();
      expect(all.length, 2);
    });
  });

  group('nullable fields', () {
    test('all measurement fields can be null', () async {
      final m = makeMeasurement(notes: 'just a note');
      await repo.create(m);

      final fetched = await repo.getById(m.id);
      expect(fetched!.waistCm, isNull);
      expect(fetched.chestCm, isNull);
      expect(fetched.leftArmCm, isNull);
      expect(fetched.rightArmCm, isNull);
      expect(fetched.hipsCm, isNull);
      expect(fetched.notes, 'just a note');
    });

    test('partial measurements persist correctly', () async {
      final m = makeMeasurement(
        waistCm: 80.0,
        leftArmCm: 35.5,
        notes: 'arms and waist only',
      );
      await repo.create(m);

      final fetched = await repo.getById(m.id);
      expect(fetched!.waistCm, 80.0);
      expect(fetched.chestCm, isNull);
      expect(fetched.leftArmCm, 35.5);
      expect(fetched.rightArmCm, isNull);
      expect(fetched.hipsCm, isNull);
    });
  });
}
