import 'package:sqflite/sqflite.dart';

import '../../../core/constants/database_tables.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/enums/sync_status.dart';
import '../../../core/sync/local_remote_merge.dart';
import '../../models/meal_model.dart';
import 'database_helper.dart';
import 'meal_local_datasource.dart';

class MealLocalDataSourceImpl implements MealLocalDataSource {
  final DatabaseHelper databaseHelper;

  static final LocalRemoteMerge<MealModel> _merge =
      LocalRemoteMerge<MealModel>(
        getId: (meal) => meal.id,
        getUpdatedAt: (meal) => meal.updatedAt,
        getSyncMetadata: (meal) => meal.syncMetadata,
      );

  const MealLocalDataSourceImpl({
    required this.databaseHelper,
  });

  @override
  Future<List<MealModel>> getAllMeals() async {
    try {
      return await _getVisibleMeals();
    } catch (e) {
      throw CacheDatabaseException('Failed to get all meals: $e');
    }
  }

  @override
  Future<MealModel?> getMealById(String id) async {
    try {
      return await _getVisibleMealById(id);
    } catch (e) {
      throw CacheDatabaseException('Failed to get meal by ID: $e');
    }
  }

  @override
  Future<MealModel?> getMealByName(String name) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.meals,
        where:
            'LOWER(${DatabaseTables.mealName}) = LOWER(?) AND '
            '(${DatabaseTables.mealSyncStatus} IS NULL OR ${DatabaseTables.mealSyncStatus} != ?)',
        whereArgs: [name, SyncStatus.pendingDelete.name],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return MealModel.fromMap(maps.first);
    } catch (e) {
      throw CacheDatabaseException('Failed to get meal by name: $e');
    }
  }

  @override
  Future<List<MealModel>> searchMealsByName(String searchTerm) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.meals,
        where:
            'LOWER(${DatabaseTables.mealName}) LIKE LOWER(?) AND '
            '(${DatabaseTables.mealSyncStatus} IS NULL OR ${DatabaseTables.mealSyncStatus} != ?)',
        whereArgs: ['%$searchTerm%', SyncStatus.pendingDelete.name],
        orderBy: DatabaseTables.mealName,
      );
      return maps.map(MealModel.fromMap).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to search meals: $e');
    }
  }

  @override
  Future<List<MealModel>> getRecentMeals({int limit = 10}) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.meals,
        where:
            '${DatabaseTables.mealSyncStatus} IS NULL OR ${DatabaseTables.mealSyncStatus} != ?',
        whereArgs: [SyncStatus.pendingDelete.name],
        orderBy: '${DatabaseTables.mealCreatedAt} DESC',
        limit: limit,
      );
      return maps.map(MealModel.fromMap).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get recent meals: $e');
    }
  }

  @override
  Future<List<MealModel>> getFrequentMeals({int limit = 10}) async {
    return getRecentMeals(limit: limit);
  }

  @override
  Future<List<MealModel>> getPendingSyncMeals() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.meals,
        where:
            '${DatabaseTables.mealSyncStatus} = ? OR ${DatabaseTables.mealSyncStatus} = ?',
        whereArgs: [
          SyncStatus.pendingUpload.name,
          SyncStatus.pendingUpdate.name,
        ],
        orderBy: '${DatabaseTables.mealUpdatedAt} ASC',
      );
      return maps.map(MealModel.fromMap).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get pending sync meals: $e');
    }
  }

  @override
  Future<void> insertMeal(MealModel meal) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseTables.meals,
        meal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to insert meal: $e');
    }
  }

  @override
  Future<void> updateMeal(MealModel meal) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseTables.meals,
        meal.toMap(),
        where: '${DatabaseTables.mealId} = ?',
        whereArgs: [meal.id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to update meal: $e');
    }
  }

  @override
  Future<void> upsertMeal(MealModel meal) async {
    final existing = await _getStoredMealById(meal.id);
    if (existing == null) {
      await insertMeal(meal);
      return;
    }

    if (existing.syncMetadata.isPendingDelete &&
        !meal.syncMetadata.isPendingDelete) {
      return;
    }

    await updateMeal(meal);
  }

  @override
  Future<void> prepareForInitialCloudMigration({
    required String userId,
  }) async {
    try {
      final storedMeals = await _getStoredMeals();
      final preparedMeals = storedMeals
          .map((meal) => _prepareMealForInitialCloudMigration(meal, userId))
          .toList();

      await _replaceStoredMeals(preparedMeals);
    } catch (e) {
      throw CacheDatabaseException(
        'Failed to prepare meals for initial cloud migration: $e',
      );
    }
  }

  @override
  Future<void> mergeRemoteMeals(List<MealModel> meals) async {
    try {
      final storedLocalMeals = await _getStoredMeals();
      final mergedVisibleMeals = _merge.mergeLists(
        localItems: storedLocalMeals,
        remoteItems: meals,
      );

      final Map<String, MealModel> mergedById = <String, MealModel>{
        for (final meal in mergedVisibleMeals) meal.id: meal,
      };

      for (final localMeal in storedLocalMeals) {
        if (localMeal.syncMetadata.isPendingDelete) {
          mergedById.putIfAbsent(localMeal.id, () => localMeal);
        }
      }

      await _replaceStoredMeals(mergedById.values.toList());
    } catch (e) {
      throw CacheDatabaseException('Failed to merge remote meals: $e');
    }
  }

  @override
  Future<void> markAsSynced({
    required String localId,
    required String serverId,
    required DateTime syncedAt,
  }) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseTables.meals,
        <String, Object?>{
          DatabaseTables.mealServerId: serverId,
          DatabaseTables.mealSyncStatus: SyncStatus.synced.name,
          DatabaseTables.mealLastSyncedAt: syncedAt.toIso8601String(),
          DatabaseTables.mealLastSyncError: null,
        },
        where: '${DatabaseTables.mealId} = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to mark meal as synced: $e');
    }
  }

  @override
  Future<void> markAsPendingUpload(
    String localId, {
    String? errorMessage,
  }) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseTables.meals,
        <String, Object?>{
          DatabaseTables.mealSyncStatus: SyncStatus.pendingUpload.name,
          DatabaseTables.mealLastSyncError: errorMessage,
        },
        where: '${DatabaseTables.mealId} = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to mark meal as pending upload: $e');
    }
  }

  @override
  Future<void> markAsPendingUpdate(
    String localId, {
    String? errorMessage,
  }) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseTables.meals,
        <String, Object?>{
          DatabaseTables.mealSyncStatus: SyncStatus.pendingUpdate.name,
          DatabaseTables.mealLastSyncError: errorMessage,
        },
        where: '${DatabaseTables.mealId} = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to mark meal as pending update: $e');
    }
  }

  @override
  Future<void> markAsPendingDelete(
    String localId, {
    String? errorMessage,
  }) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseTables.meals,
        <String, Object?>{
          DatabaseTables.mealSyncStatus: SyncStatus.pendingDelete.name,
          DatabaseTables.mealLastSyncError: errorMessage,
        },
        where: '${DatabaseTables.mealId} = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to mark meal as pending delete: $e');
    }
  }

  @override
  Future<void> replaceAllMeals(List<MealModel> meals) async {
    try {
      await _replaceStoredMeals(meals);
    } catch (e) {
      throw CacheDatabaseException('Failed to replace all meals: $e');
    }
  }

  @override
  Future<void> deleteMeal(String id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        DatabaseTables.meals,
        where: '${DatabaseTables.mealId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to delete meal: $e');
    }
  }

  @override
  Future<void> clearAllMeals() async {
    try {
      final db = await databaseHelper.database;
      await db.delete(DatabaseTables.meals);
    } catch (e) {
      throw CacheDatabaseException('Failed to clear all meals: $e');
    }
  }

  @override
  Future<int> getMealsCount() async {
    try {
      final db = await databaseHelper.database;
      final result = await db.rawQuery(
        '''
        SELECT COUNT(*)
        FROM ${DatabaseTables.meals}
        WHERE ${DatabaseTables.mealSyncStatus} IS NULL
           OR ${DatabaseTables.mealSyncStatus} != ?
        ''',
        [SyncStatus.pendingDelete.name],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw CacheDatabaseException('Failed to get meals count: $e');
    }
  }

  Future<List<MealModel>> _getVisibleMeals() async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseTables.meals,
      where:
          '${DatabaseTables.mealSyncStatus} IS NULL OR ${DatabaseTables.mealSyncStatus} != ?',
      whereArgs: <Object?>[SyncStatus.pendingDelete.name],
      orderBy: '${DatabaseTables.mealName} ASC',
    );

    return maps.map(MealModel.fromMap).toList();
  }

  Future<MealModel?> _getVisibleMealById(String id) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseTables.meals,
      where:
          '${DatabaseTables.mealId} = ? AND (${DatabaseTables.mealSyncStatus} IS NULL OR ${DatabaseTables.mealSyncStatus} != ?)',
      whereArgs: <Object?>[id, SyncStatus.pendingDelete.name],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return MealModel.fromMap(maps.first);
  }

  Future<List<MealModel>> _getStoredMeals() async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseTables.meals,
      orderBy: '${DatabaseTables.mealName} ASC',
    );

    return maps.map(MealModel.fromMap).toList();
  }

  Future<MealModel?> _getStoredMealById(String id) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseTables.meals,
      where: '${DatabaseTables.mealId} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return MealModel.fromMap(maps.first);
  }

  Future<void> _replaceStoredMeals(List<MealModel> meals) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      await txn.delete(DatabaseTables.meals);

      final batch = txn.batch();
      for (final meal in meals) {
        batch.insert(
          DatabaseTables.meals,
          meal.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  MealModel _prepareMealForInitialCloudMigration(
    MealModel meal,
    String userId,
  ) {
    final ownerUserId = meal.ownerUserId;
    if (ownerUserId != null && ownerUserId.isNotEmpty && ownerUserId != userId) {
      return meal;
    }

    final currentMetadata = meal.syncMetadata;
    final updatedMetadata = switch (currentMetadata.status) {
      SyncStatus.localOnly => currentMetadata.copyWith(
          status: SyncStatus.pendingUpload,
          clearLastSyncError: true,
        ),
      SyncStatus.pendingUpload => currentMetadata.copyWith(
          clearLastSyncError: true,
        ),
      SyncStatus.pendingUpdate ||
      SyncStatus.synced ||
      SyncStatus.pendingDelete => currentMetadata,
    };

    return MealModel.fromEntity(
      meal.copyWith(
        ownerUserId:
            ownerUserId == null || ownerUserId.isEmpty ? userId : null,
        syncMetadata: updatedMetadata,
      ),
    );
  }
}
