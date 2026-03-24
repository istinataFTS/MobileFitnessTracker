import 'package:fitness_tracker/core/constants/database_tables.dart';
import 'package:fitness_tracker/core/enums/sync_status.dart';
import 'package:fitness_tracker/data/datasources/local/database_helper.dart';
import 'package:fitness_tracker/data/datasources/local/nutrition_log_local_datasource_impl.dart';
import 'package:fitness_tracker/data/models/nutrition_log_model.dart';
import 'package:fitness_tracker/domain/entities/entity_sync_metadata.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database database;
  late MockDatabaseHelper databaseHelper;
  late NutritionLogLocalDataSourceImpl dataSource;

  final DateTime baseDate = DateTime(2026, 3, 22, 10, 0);

  NutritionLogModel buildLog({
    required String id,
    required DateTime loggedAt,
    String? mealId = 'meal-1',
    String mealName = 'Chicken Bowl',
    double? gramsConsumed = 100,
    double protein = 25,
    double carbs = 30,
    double fat = 10,
    double calories = 310,
    DateTime? updatedAt,
    EntitySyncMetadata syncMetadata = const EntitySyncMetadata(),
  }) {
    return NutritionLogModel(
      id: id,
      mealId: mealId,
      mealName: mealName,
      gramsConsumed: gramsConsumed,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      calories: calories,
      loggedAt: loggedAt,
      createdAt: loggedAt,
      updatedAt: updatedAt ?? loggedAt,
      syncMetadata: syncMetadata,
    );
  }

  Future<void> createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseTables.nutritionLogs} (
        ${DatabaseTables.nutritionLogId} TEXT PRIMARY KEY,
        owner_user_id TEXT,
        ${DatabaseTables.nutritionLogMealId} TEXT,
        ${DatabaseTables.nutritionLogMealName} TEXT NOT NULL DEFAULT '',
        ${DatabaseTables.nutritionLogGrams} REAL,
        ${DatabaseTables.nutritionLogCarbs} REAL NOT NULL,
        ${DatabaseTables.nutritionLogProtein} REAL NOT NULL,
        ${DatabaseTables.nutritionLogFat} REAL NOT NULL,
        ${DatabaseTables.nutritionLogCalories} REAL NOT NULL,
        ${DatabaseTables.nutritionLogDate} TEXT NOT NULL,
        ${DatabaseTables.nutritionLogCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.nutritionLogUpdatedAt} TEXT NOT NULL,
        ${DatabaseTables.nutritionLogServerId} TEXT,
        ${DatabaseTables.nutritionLogSyncStatus} TEXT NOT NULL DEFAULT 'localOnly',
        ${DatabaseTables.nutritionLogLastSyncedAt} TEXT,
        ${DatabaseTables.nutritionLogLastSyncError} TEXT
      )
    ''');
  }

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async => createSchema(db),
      ),
    );

    databaseHelper = MockDatabaseHelper();
    when(() => databaseHelper.database).thenAnswer((_) async => database);

    dataSource = NutritionLogLocalDataSourceImpl(databaseHelper: databaseHelper);
  });

  tearDown(() async {
    await database.close();
  });

  group('NutritionLogLocalDataSourceImpl reads', () {
    test('getAllLogs hides pendingDelete rows', () async {
      await dataSource.insertLog(
        buildLog(
          id: 'log-1',
          loggedAt: baseDate,
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.synced,
          ),
        ),
      );
      await dataSource.insertLog(
        buildLog(
          id: 'log-2',
          loggedAt: baseDate.add(const Duration(hours: 1)),
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      final logs = await dataSource.getAllLogs();

      expect(logs.map((l) => l.id).toList(), <String>['log-1']);
    });

    test('getLogById returns null for pendingDelete row', () async {
      await dataSource.insertLog(
        buildLog(
          id: 'log-1',
          loggedAt: baseDate,
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      final log = await dataSource.getLogById('log-1');

      expect(log, isNull);
    });

    test('getLogsByDate excludes pendingDelete rows', () async {
      await dataSource.insertLog(
        buildLog(
          id: 'log-1',
          loggedAt: baseDate,
        ),
      );
      await dataSource.insertLog(
        buildLog(
          id: 'log-2',
          loggedAt: baseDate.add(const Duration(hours: 1)),
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      final logs = await dataSource.getLogsByDate(baseDate);

      expect(logs.map((l) => l.id).toList(), <String>['log-1']);
    });

    test('getMealLogs excludes pendingDelete rows', () async {
      await dataSource.insertLog(
        buildLog(
          id: 'log-1',
          loggedAt: baseDate,
          mealId: 'meal-1',
        ),
      );
      await dataSource.insertLog(
        buildLog(
          id: 'log-2',
          loggedAt: baseDate.add(const Duration(hours: 1)),
          mealId: 'meal-2',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      final logs = await dataSource.getMealLogs();

      expect(logs.map((l) => l.id).toList(), <String>['log-1']);
    });

    test('getDailyMacros excludes pendingDelete rows', () async {
      await dataSource.insertLog(
        buildLog(
          id: 'log-1',
          loggedAt: baseDate,
          protein: 25,
          carbs: 30,
          fat: 10,
          calories: 310,
        ),
      );
      await dataSource.insertLog(
        buildLog(
          id: 'log-2',
          loggedAt: baseDate.add(const Duration(hours: 1)),
          protein: 50,
          carbs: 60,
          fat: 20,
          calories: 620,
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      final macros = await dataSource.getDailyMacros(baseDate);

      expect(macros['totalProtein'], 25);
      expect(macros['totalCarbs'], 30);
      expect(macros['totalFat'], 10);
      expect(macros['totalCalories'], 310);
      expect(macros['logsCount'], 1);
    });
  });

  group('NutritionLogLocalDataSourceImpl mergeRemoteLogs', () {
    test('preserves pending local update over remote row', () async {
      final localPendingLog = buildLog(
        id: 'log-1',
        loggedAt: baseDate,
        calories: 330,
        updatedAt: baseDate.add(const Duration(minutes: 30)),
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.pendingUpdate,
        ),
      );

      final remoteLog = buildLog(
        id: 'log-1',
        loggedAt: baseDate,
        calories: 500,
        updatedAt: baseDate.add(const Duration(hours: 1)),
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.synced,
        ),
      );

      await dataSource.insertLog(localPendingLog);

      await dataSource.mergeRemoteLogs(<NutritionLogModel>[remoteLog]);

      final logs = await dataSource.getAllLogs();
      expect(logs, hasLength(1));
      expect(logs.first.calories, 330);
      expect(logs.first.syncMetadata.status, SyncStatus.pendingUpdate);
    });

    test('adds remote-only rows while keeping local pending upload', () async {
      final localPendingLog = buildLog(
        id: 'log-1',
        loggedAt: baseDate,
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.pendingUpload,
        ),
      );

      final remoteLog = buildLog(
        id: 'log-2',
        loggedAt: baseDate.add(const Duration(hours: 1)),
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.synced,
        ),
      );

      await dataSource.insertLog(localPendingLog);

      await dataSource.mergeRemoteLogs(<NutritionLogModel>[remoteLog]);

      final logs = await dataSource.getAllLogs();
      expect(logs.map((l) => l.id).toSet(), <String>{'log-1', 'log-2'});
      expect(
        logs.firstWhere((l) => l.id == 'log-1').syncMetadata.status,
        SyncStatus.pendingUpload,
      );
    });

    test('keeps pendingDelete row hidden even if remote still has it', () async {
      final localPendingDelete = buildLog(
        id: 'log-1',
        loggedAt: baseDate,
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.pendingDelete,
        ),
      );

      final remoteLog = buildLog(
        id: 'log-1',
        loggedAt: baseDate,
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.synced,
        ),
      );

      await dataSource.insertLog(localPendingDelete);

      await dataSource.mergeRemoteLogs(<NutritionLogModel>[remoteLog]);

      final visibleLogs = await dataSource.getAllLogs();
      expect(visibleLogs, isEmpty);

      final rawRows = await database.query(DatabaseTables.nutritionLogs);
      expect(rawRows, hasLength(1));
      expect(
        rawRows.first[DatabaseTables.nutritionLogSyncStatus],
        SyncStatus.pendingDelete.name,
      );
    });
  });

  group('NutritionLogLocalDataSourceImpl state transitions', () {
    test('markAsPendingDelete updates sync status and error', () async {
      await dataSource.insertLog(
        buildLog(
          id: 'log-1',
          loggedAt: baseDate,
        ),
      );

      await dataSource.markAsPendingDelete(
        'log-1',
        errorMessage: 'delete queued',
      );

      final rawRows = await database.query(
        DatabaseTables.nutritionLogs,
        where: '${DatabaseTables.nutritionLogId} = ?',
        whereArgs: <Object?>['log-1'],
      );

      expect(rawRows.single[DatabaseTables.nutritionLogSyncStatus],
          SyncStatus.pendingDelete.name);
      expect(rawRows.single[DatabaseTables.nutritionLogLastSyncError],
          'delete queued');
    });

    test('upsertLog inserts when missing and updates when present', () async {
      final inserted = buildLog(
        id: 'log-1',
        loggedAt: baseDate,
        calories: 310,
      );

      await dataSource.upsertLog(inserted);

      final updated = buildLog(
        id: 'log-1',
        loggedAt: baseDate,
        calories: 420,
        updatedAt: baseDate.add(const Duration(hours: 1)),
      );

      await dataSource.upsertLog(updated);

      final log = await dataSource.getLogById('log-1');
      expect(log, isNotNull);
      expect(log!.calories, 420);
    });
  });
}