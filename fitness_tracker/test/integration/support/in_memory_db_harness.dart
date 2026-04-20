import 'dart:io';

import 'package:fitness_tracker/data/datasources/local/database_helper.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_env.dart';

/// Mock facade exposing a real in-memory sqflite database as a
/// [DatabaseHelper] so the production DI graph can wire up unmodified.
class _InMemoryDatabaseHelper extends Mock implements DatabaseHelper {}

/// Spins up a sqflite-ffi database populated with the full production
/// schema (via [DatabaseHelper.createSchema]) and exposes it behind a
/// [DatabaseHelper] stand-in that the production DI graph can wire to
/// unchanged.
///
/// Defaults to an in-memory database for speed + isolation; set
/// `INTEGRATION_DB_MODE=file` (via `--dart-define`) to materialise the
/// DB on disk for ad-hoc inspection with the `sqlite3` CLI.
///
/// Usage:
///
/// ```dart
/// late InMemoryDbHarness db;
/// setUp(() async { db = await InMemoryDbHarness.open(); });
/// tearDown(() async { await db.close(); });
/// ```
///
/// The `DatabaseHelper` facade is a [Mock] — it intentionally does NOT
/// extend the real helper because the real helper is a hard singleton
/// keyed off `EnvConfig.databaseName`; reusing it would leak state
/// between tests.
class InMemoryDbHarness {
  InMemoryDbHarness._(this.database, this.helper);

  final Database database;
  final DatabaseHelper helper;

  /// Opens a fresh database, initialises the ffi binding, and creates
  /// every production table. Each call yields an independent database.
  static Future<InMemoryDbHarness> open() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final String path = _resolvePath();

    final Database db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (database, _) => DatabaseHelper.createSchema(database),
        // Without this, sqflite caches by path and every in-memory
        // harness in the suite would share one database — which would
        // silently leak rows across tests.
        singleInstance: false,
      ),
    );

    final DatabaseHelper helper = _InMemoryDatabaseHelper();
    when(() => helper.database).thenAnswer((_) async => db);

    return InMemoryDbHarness._(db, helper);
  }

  /// Closes the underlying database. Tests MUST call this in `tearDown`
  /// to release ffi handles; leaking them slows the suite and can cause
  /// locking errors on Windows.
  Future<void> close() async {
    if (database.isOpen) {
      await database.close();
    }
  }

  static String _resolvePath() {
    if (TestEnv.dbMode == 'file') {
      final String tempDir = Directory.systemTemp.path;
      return p.join(tempDir, 'fitness_tracker_integration.sqlite');
    }
    return inMemoryDatabasePath;
  }
}
