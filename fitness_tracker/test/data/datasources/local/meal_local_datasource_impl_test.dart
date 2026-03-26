import 'package:fitness_tracker/core/constants/database_tables.dart';
import 'package:fitness_tracker/core/enums/sync_status.dart';
import 'package:fitness_tracker/data/datasources/local/database_helper.dart';
import 'package:fitness_tracker/data/datasources/local/meal_local_datasource_impl.dart';
import 'package:fitness_tracker/data/models/meal_model.dart';
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
  late MealLocalDataSourceImpl dataSource;

  final DateTime baseDate = DateTime(2026, 3, 22, 10, 0);

  MealModel buildMeal({
    required String id,
    required String name,
    String? ownerUserId = 'user-1',
    DateTime? updatedAt,
    EntitySyncMetadata syncMetadata = const EntitySyncMetadata(),
  }) {
    return MealModel(
      id: id,
      ownerUserId: ownerUserId,
      name: name,
      servingSizeGrams: 100,
      carbsPer100g: 30,
      proteinPer100g: 20,
      fatPer100g: 10,
      caloriesPer100g: 290,
      createdAt: baseDate,
      updatedAt: updatedAt ?? baseDate,
      syncMetadata: syncMetadata,
    );
  }

  Future<void> createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseTables.meals} (
        ${DatabaseTables.mealId} TEXT PRIMARY KEY,
        owner_user_id TEXT,
        ${DatabaseTables.mealName} TEXT NOT NULL UNIQUE,
        ${DatabaseTables.mealServingSize} REAL NOT NULL DEFAULT 100.0,
        ${DatabaseTables.mealCarbsPer100g} REAL NOT NULL,
        ${DatabaseTables.mealProteinPer100g} REAL NOT NULL,
        ${DatabaseTables.mealFatPer100g} REAL NOT NULL,
        ${DatabaseTables.mealCaloriesPer100g} REAL NOT NULL,
        ${DatabaseTables.mealCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.mealUpdatedAt} TEXT NOT NULL,
        ${DatabaseTables.mealServerId} TEXT,
        ${DatabaseTables.mealSyncStatus} TEXT NOT NULL DEFAULT 'localOnly',
        ${DatabaseTables.mealLastSyncedAt} TEXT,
        ${DatabaseTables.mealLastSyncError} TEXT
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

    dataSource = MealLocalDataSourceImpl(databaseHelper: databaseHelper);
  });

  tearDown(() async {
    await database.close();
  });

  group('MealLocalDataSourceImpl reads', () {
    test('getAllMeals hides pendingDelete rows', () async {
      await dataSource.insertMeal(
        buildMeal(
          id: 'meal-1',
          name: 'Visible Meal',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.synced,
          ),
        ),
      );
      await dataSource.insertMeal(
        buildMeal(
          id: 'meal-2',
          name: 'Deleted Meal',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      final meals = await dataSource.getAllMeals();

      expect(meals.map((m) => m.id).toList(), <String>['meal-1']);
    });

    test('getMealById returns null for pendingDelete row', () async {
      await dataSource.insertMeal(
        buildMeal(
          id: 'meal-1',
          name: 'Deleted Meal',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      final meal = await dataSource.getMealById('meal-1');

      expect(meal, isNull);
    });

    test('getMealByName returns null for pendingDelete row', () async {
      await dataSource.insertMeal(
        buildMeal(
          id: 'meal-1',
          name: 'Deleted Meal',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      final meal = await dataSource.getMealByName('Deleted Meal');

      expect(meal, isNull);
    });

    test('getMealsCount excludes pendingDelete rows', () async {
      await dataSource.insertMeal(
        buildMeal(
          id: 'meal-1',
          name: 'Visible Meal',
        ),
      );
      await dataSource.insertMeal(
        buildMeal(
          id: 'meal-2',
          name: 'Deleted Meal',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      final count = await dataSource.getMealsCount();

      expect(count, 1);
    });
  });

  group('MealLocalDataSourceImpl mergeRemoteMeals', () {
    test('preserves pending local update over newer remote row', () async {
      final localPendingMeal = buildMeal(
        id: 'meal-1',
        name: 'Local Edited Meal',
        updatedAt: baseDate.add(const Duration(hours: 1)),
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.pendingUpdate,
        ),
      );

      final remoteMeal = buildMeal(
        id: 'meal-1',
        name: 'Remote Meal',
        updatedAt: baseDate.add(const Duration(hours: 2)),
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.synced,
        ),
      );

      await dataSource.insertMeal(localPendingMeal);

      await dataSource.mergeRemoteMeals(<MealModel>[remoteMeal]);

      final meals = await dataSource.getAllMeals();
      expect(meals, hasLength(1));
      expect(meals.first.name, 'Local Edited Meal');
      expect(meals.first.syncMetadata.status, SyncStatus.pendingUpdate);
    });

    test('adds remote-only rows while preserving local pending changes',
        () async {
      final localPendingMeal = buildMeal(
        id: 'meal-1',
        name: 'Local Pending Meal',
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.pendingUpload,
        ),
      );

      final remoteMeal = buildMeal(
        id: 'meal-2',
        name: 'Remote Meal',
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.synced,
        ),
      );

      await dataSource.insertMeal(localPendingMeal);

      await dataSource.mergeRemoteMeals(<MealModel>[remoteMeal]);

      final meals = await dataSource.getAllMeals();
      expect(meals.map((m) => m.id).toSet(), <String>{'meal-1', 'meal-2'});
      expect(
        meals.firstWhere((m) => m.id == 'meal-1').syncMetadata.status,
        SyncStatus.pendingUpload,
      );
    });

    test('keeps pendingDelete row hidden even if remote still contains entity',
        () async {
      final localPendingDelete = buildMeal(
        id: 'meal-1',
        name: 'Deleted Locally',
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.pendingDelete,
        ),
      );

      final remoteMeal = buildMeal(
        id: 'meal-1',
        name: 'Remote Still Exists',
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.synced,
        ),
      );

      await dataSource.insertMeal(localPendingDelete);

      await dataSource.mergeRemoteMeals(<MealModel>[remoteMeal]);

      final meals = await dataSource.getAllMeals();
      expect(meals, isEmpty);

      final rawRows = await database.query(DatabaseTables.meals);
      expect(rawRows, hasLength(1));
      expect(
        rawRows.first[DatabaseTables.mealSyncStatus],
        SyncStatus.pendingDelete.name,
      );
    });
  });

  group('MealLocalDataSourceImpl state transitions', () {
    test('markAsPendingDelete updates sync status and error', () async {
      await dataSource.insertMeal(
        buildMeal(
          id: 'meal-1',
          name: 'Meal',
        ),
      );

      await dataSource.markAsPendingDelete(
        'meal-1',
        errorMessage: 'delete queued',
      );

      final rawRows = await database.query(
        DatabaseTables.meals,
        where: '${DatabaseTables.mealId} = ?',
        whereArgs: <Object?>['meal-1'],
      );

      expect(
        rawRows.single[DatabaseTables.mealSyncStatus],
        SyncStatus.pendingDelete.name,
      );
      expect(rawRows.single[DatabaseTables.mealLastSyncError], 'delete queued');
    });

    test('upsertMeal inserts when missing and updates when present', () async {
      final inserted = buildMeal(
        id: 'meal-1',
        name: 'Original Meal',
      );

      await dataSource.upsertMeal(inserted);

      final updated = buildMeal(
        id: 'meal-1',
        name: 'Updated Meal',
        updatedAt: baseDate.add(const Duration(hours: 2)),
      );

      await dataSource.upsertMeal(updated);

      final meal = await dataSource.getMealById('meal-1');
      expect(meal, isNotNull);
      expect(meal!.name, 'Updated Meal');
    });

    test('upsertMeal does not revive a pendingDelete row', () async {
      await dataSource.insertMeal(
        buildMeal(
          id: 'meal-1',
          name: 'Deleted Meal',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      await dataSource.upsertMeal(
        buildMeal(
          id: 'meal-1',
          name: 'Remote Meal',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.synced,
          ),
        ),
      );

      final visibleMeal = await dataSource.getMealById('meal-1');
      expect(visibleMeal, isNull);

      final rawRows = await database.query(
        DatabaseTables.meals,
        where: '${DatabaseTables.mealId} = ?',
        whereArgs: <Object?>['meal-1'],
      );
      expect(rawRows, hasLength(1));
      expect(
        rawRows.single[DatabaseTables.mealSyncStatus],
        SyncStatus.pendingDelete.name,
      );
    });
  });

  group('MealLocalDataSourceImpl prepareForInitialCloudMigration', () {
    test('claims guest localOnly meal and queues upload', () async {
      await dataSource.insertMeal(
        buildMeal(
          id: 'meal-1',
          name: 'Guest Meal',
          ownerUserId: null,
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.localOnly,
            lastSyncError: 'offline',
          ),
        ),
      );

      await dataSource.prepareForInitialCloudMigration(userId: 'user-1');

      final meal = await dataSource.getMealById('meal-1');
      expect(meal, isNotNull);
      expect(meal!.ownerUserId, 'user-1');
      expect(meal.syncMetadata.status, SyncStatus.pendingUpload);
      expect(meal.syncMetadata.lastSyncError, isNull);
    });
  });
}
