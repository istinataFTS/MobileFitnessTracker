import 'package:sqflite/sqflite.dart';
import '../../../core/constants/database_tables.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/target_model.dart';
import 'database_helper.dart';

abstract class TargetLocalDataSource {
  Future<List<TargetModel>> getAllTargets();
  Future<TargetModel?> getTargetByMuscleGroup(String muscleGroup);
  Future<void> insertTarget(TargetModel target);
  Future<void> updateTarget(TargetModel target);
  Future<void> deleteTarget(String muscleGroup);
  Future<void> clearAllTargets();
}

class TargetLocalDataSourceImpl implements TargetLocalDataSource {
  final DatabaseHelper databaseHelper;

  const TargetLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<TargetModel>> getAllTargets() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.targets,
        orderBy: '${DatabaseTables.targetCreatedAt} DESC',
      );
      return maps.map((map) => TargetModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get targets: $e');
    }
  }

  @override
  Future<TargetModel?> getTargetByMuscleGroup(String muscleGroup) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.targets,
        where: '${DatabaseTables.targetMuscleGroup} = ?',
        whereArgs: [muscleGroup],
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
        where: '${DatabaseTables.targetMuscleGroup} = ?',
        whereArgs: [target.muscleGroup],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to update target: $e');
    }
  }

  @override
  Future<void> deleteTarget(String muscleGroup) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        DatabaseTables.targets,
        where: '${DatabaseTables.targetMuscleGroup} = ?',
        whereArgs: [muscleGroup],
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
}