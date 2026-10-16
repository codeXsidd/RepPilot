import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:rep_pilot/core/database/database_helper.dart';
import 'package:rep_pilot/core/database/schema.dart';

Future<Database> openTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: currentSchemaVersion,
      onConfigure: DatabaseHelper.onConfigure,
      onCreate: DatabaseHelper.onCreate,
    ),
  );
  return db;
}
