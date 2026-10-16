import 'package:sqflite/sqflite.dart';

import '../models/user_profile.dart';

class UserProfileRepository {
  final Database _db;

  UserProfileRepository(this._db);

  Future<UserProfile> create(UserProfile profile) async {
    await _db.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return profile;
  }

  Future<UserProfile?> get() async {
    final maps = await _db.query('user_profile', limit: 1);
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  Future<UserProfile> getOrCreate(UserProfile defaultProfile) async {
    final existing = await get();
    if (existing != null) return existing;
    return create(defaultProfile);
  }

  Future<int> update(UserProfile profile) async {
    return _db.update(
      'user_profile',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }
}
