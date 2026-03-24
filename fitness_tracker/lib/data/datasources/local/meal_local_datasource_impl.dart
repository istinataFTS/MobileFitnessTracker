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
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.meals,
        where:
            '${DatabaseTables.mealSyncStatus} IS NULL OR ${DatabaseTables.mealSyncStatus} != ?',
        whereArgs: const ['pendingDelete'],
        orderBy: '${DatabaseTables.mealName} ASC',
      );
      return maps.map(MealModel.fromMap).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get all meals: $e');
    }
  }

  @override
  Future<MealModel?> getMealById(String id) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.meals,
        where:
            '${DatabaseTables.mealId} = ? AND (${DatabaseTables.mealSyncStatus} IS NULL OR ${DatabaseTables.mealSyncStatus} != ?)',
        whereArgs: [id, 'pendingDelete'],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return MealModel.fromMap(maps.first);
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
            'LOWER(${DatabaseTables.mealName}) = LOWER(?) AND (${DatabaseTables.mealSyncStatus} IS NULL OR ${DatabaseTables.mealSyncStatus} != ?)',
        whereArgs: [name, 'pendingDelete'],
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
            'LOWER(${DatabaseTables.mealName}) LIKE LOWER(?) AND (${DatabaseTables.mealSyncStatus} IS NULL OR ${DatabaseTables.mealSyncStatus} != ?)',
        whereArgs: ['%$searchTerm%', 'pendingDelete'],
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
        whereArgs: const ['pendingDelete'],
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
        whereArgs: const ['pendingUpload', 'pendingUpdate'],
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
    final existing = await getMealById(meal.id);
    if (existing == null) {
      await insertMeal(meal);
      return;
    }

    await updateMeal(meal);
  }

  @override
  Future<void> mergeRemoteMeals(List<MealModel> meals) async {
    try {
      final localMeals = await getAllMeals();
      final merged = _merge.mergeLists(
        localItems: localMeals,
        remoteItems: meals,
      );

      final db = await databaseHelper.database;

      await db.transaction((txn) async {
        await txn.delete(
          DatabaseTables.meals,
          where:
              '${DatabaseTables.mealSyncStatus} IS NULL OR ${DatabaseTables.mealSyncStatus} != ?',
          whereArgs: const ['pendingDelete'],
        );

        final batch = txn.batch();
        for (final meal in merged) {
          batch.insert(
            DatabaseTables.meals,
            meal.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
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
        ['pendingDelete'],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw CacheDatabaseException('Failed to get meals count: $e');
    }
  }
}