import 'package:sqflite/sqflite.dart';

import '../../../core/constants/database_tables.dart';
import '../../../core/errors/exceptions.dart';
import '../../../domain/entities/target.dart';
import '../../models/target_model.dart';
import 'database_helper.dart';

abstract class TargetLocalDataSource {
  Future<List<TargetModel>> getAllTargets();
  Future<TargetModel?> getTargetById(String id);
  Future<TargetModel?> getTargetByTypeAndCategory(
    TargetType type,
    String categoryKey,
    TargetPeriod period,
  );
  Future<void> insertTarget(TargetModel target);
  Future<void> updateTarget(TargetModel target);
  Future<void> deleteTarget(String id);
  Future<void> clearAllTargets();
}

class TargetLocalDataSourceImpl implements TargetLocalDataSource {
  final DatabaseHelper databaseHelper;

  const TargetLocalDataSourceImpl({
    required this.databaseHelper,
  });

  @override
  Future<List<TargetModel>> getAllTargets() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.targets,
        orderBy: '''
          ${DatabaseTables.targetType} ASC,
          ${DatabaseTables.targetPeriod} ASC,
          ${DatabaseTables.targetCreatedAt} DESC
        ''',
      );

      return maps.map(TargetModel.fromMap).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get targets: $e');
    }
  }

  @override
  Future<TargetModel?> getTargetById(String id) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.targets,
        where: '${DatabaseTables.targetId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return TargetModel.fromMap(maps.first);
    } catch (e) {
      throw CacheDatabaseException('Failed to get target by id: $e');
    }
  }

  @override
  Future<TargetModel?> getTargetByTypeAndCategory(
    TargetType type,
    String categoryKey,
    TargetPeriod period,
  ) async {
    try {
      final db = await databaseHelper.database;
      final typeValue = _targetTypeToString(type);
      final periodValue = _targetPeriodToString(period);

      final maps = await db.query(
        DatabaseTables.targets,
        where: '''
          ${DatabaseTables.targetType} = ? AND
          ${DatabaseTables.targetCategoryKey} = ? AND
          ${DatabaseTables.targetPeriod} = ?
        ''',
        whereArgs: [typeValue, categoryKey, periodValue],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return TargetModel.fromMap(maps.first);
    } catch (e) {
      throw CacheDatabaseException('Failed to get target: $e');
    }
  }

  @override
  Future<void> insertTarget(TargetModel target) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseTables.targets,
        target.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to insert target: $e');
    }
  }

  @override
  Future<void> updateTarget(TargetModel target) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseTables.targets,
        target.toMap(),
        where: '${DatabaseTables.targetId} = ?',
        whereArgs: [target.id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to update target: $e');
    }
  }

  @override
  Future<void> deleteTarget(String id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        DatabaseTables.targets,
        where: '${DatabaseTables.targetId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to delete target: $e');
    }
  }

  @override
  Future<void> clearAllTargets() async {
    try {
      final db = await databaseHelper.database;
      await db.delete(DatabaseTables.targets);
    } catch (e) {
      throw CacheDatabaseException('Failed to clear targets: $e');
    }
  }

  String _targetTypeToString(TargetType type) {
    switch (type) {
      case TargetType.muscleSets:
        return 'muscle_sets';
      case TargetType.macro:
        return 'macro';
    }
  }

  String _targetPeriodToString(TargetPeriod period) {
    switch (period) {
      case TargetPeriod.daily:
        return 'daily';
      case TargetPeriod.weekly:
        return 'weekly';
    }
  }
}