import 'package:sqflite/sqflite.dart';
import '../../../core/constants/database_tables.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/muscle_factor_model.dart';
import 'database_helper.dart';

/// Local data source interface for MuscleFactor operations
abstract class MuscleFactorLocalDataSource {
  /// Get all muscle factors for a specific exercise
  Future<List<MuscleFactorModel>> getFactorsByExerciseId(String exerciseId);
  
  /// Get all muscle factors for a specific muscle group
  Future<List<MuscleFactorModel>> getFactorsByMuscleGroup(String muscleGroup);
  
  /// Get a specific muscle factor
  Future<MuscleFactorModel?> getFactorById(String id);
  
  /// Insert a single muscle factor
  Future<void> insertFactor(MuscleFactorModel factor);
  
  /// Insert multiple muscle factors (for seeding)
  Future<void> insertFactorsBatch(List<MuscleFactorModel> factors);
  
  /// Update a muscle factor
  Future<void> updateFactor(MuscleFactorModel factor);
  
  /// Delete muscle factor by ID
  Future<void> deleteFactor(String id);
  
  /// Delete all factors for an exercise
  Future<void> deleteFactorsByExerciseId(String exerciseId);
  
  /// Clear all muscle factors (for reseeding)
  Future<void> clearAllFactors();
}

/// SQLite implementation of MuscleFactor local data source
class MuscleFactorLocalDataSourceImpl implements MuscleFactorLocalDataSource {
  final DatabaseHelper databaseHelper;

  const MuscleFactorLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<MuscleFactorModel>> getFactorsByExerciseId(String exerciseId) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.exerciseMuscleFactors,
        where: '${DatabaseTables.factorExerciseId} = ?',
        whereArgs: [exerciseId],
        orderBy: '${DatabaseTables.factorValue} DESC', // Primary muscles first
      );
      return maps.map((map) => MuscleFactorModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get muscle factors for exercise: $e');
    }
  }

  @override
  Future<List<MuscleFactorModel>> getFactorsByMuscleGroup(String muscleGroup) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.exerciseMuscleFactors,
        where: '${DatabaseTables.factorMuscleGroup} = ?',
        whereArgs: [muscleGroup],
        orderBy: '${DatabaseTables.factorValue} DESC',
      );
      return maps.map((map) => MuscleFactorModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get muscle factors for muscle group: $e');
    }
  }

  @override
  Future<MuscleFactorModel?> getFactorById(String id) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.exerciseMuscleFactors,
        where: '${DatabaseTables.factorId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return MuscleFactorModel.fromMap(maps.first);
    } catch (e) {
      throw CacheDatabaseException('Failed to get muscle factor: $e');
    }
  }

  @override
  Future<void> insertFactor(MuscleFactorModel factor) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseTables.exerciseMuscleFactors,
        factor.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to insert muscle factor: $e');
    }
  }

  @override
  Future<void> insertFactorsBatch(List<MuscleFactorModel> factors) async {
    try {
      final db = await databaseHelper.database;
      final batch = db.batch();
      
      for (final factor in factors) {
        batch.insert(
          DatabaseTables.exerciseMuscleFactors,
          factor.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit(noResult: true);
    } catch (e) {
      throw CacheDatabaseException('Failed to insert muscle factors batch: $e');
    }
  }

  @override
  Future<void> updateFactor(MuscleFactorModel factor) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseTables.exerciseMuscleFactors,
        factor.toMap(),
        where: '${DatabaseTables.factorId} = ?',
        whereArgs: [factor.id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to update muscle factor: $e');
    }
  }

  @override
  Future<void> deleteFactor(String id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        DatabaseTables.exerciseMuscleFactors,
        where: '${DatabaseTables.factorId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to delete muscle factor: $e');
    }
  }

  @override
  Future<void> deleteFactorsByExerciseId(String exerciseId) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        DatabaseTables.exerciseMuscleFactors,
        where: '${DatabaseTables.factorExerciseId} = ?',
        whereArgs: [exerciseId],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to delete factors for exercise: $e');
    }
  }

  @override
  Future<void> clearAllFactors() async {
    try {
      final db = await databaseHelper.database;
      await db.delete(DatabaseTables.exerciseMuscleFactors);
    } catch (e) {
      throw CacheDatabaseException('Failed to clear muscle factors: $e');
    }
  }
}