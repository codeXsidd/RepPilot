import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:rep_pilot/models/user_profile.dart';
import 'package:rep_pilot/repositories/user_profile_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late UserProfileRepository repo;
  final now = DateTime(2025, 6, 15, 10, 0);

  setUp(() async {
    db = await openTestDatabase();
    repo = UserProfileRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  UserProfile makeProfile() => UserProfile(
    id: 'profile-1',
    displayName: 'User',
    createdAt: now,
    updatedAt: now,
  );

  test('get returns null on fresh DB', () async {
    final profile = await repo.get();
    expect(profile, isNull);
  });

  test('create and get', () async {
    await repo.create(makeProfile());
    final profile = await repo.get();
    expect(profile, isNotNull);
    expect(profile!.displayName, 'User');
    expect(profile.weightUnit, 'kg');
  });

  test('getOrCreate creates on first call', () async {
    final profile = await repo.getOrCreate(makeProfile());
    expect(profile.id, 'profile-1');

    final second = await repo.getOrCreate(
      UserProfile(id: 'other-id', createdAt: now, updatedAt: now),
    );
    expect(second.id, 'profile-1');
  });

  test('update modifies profile', () async {
    await repo.create(makeProfile());
    await repo.update(
      makeProfile().copyWith(weightUnit: 'lb', themeMode: 'dark'),
    );
    final profile = await repo.get();
    expect(profile!.weightUnit, 'lb');
    expect(profile.themeMode, 'dark');
  });
}
