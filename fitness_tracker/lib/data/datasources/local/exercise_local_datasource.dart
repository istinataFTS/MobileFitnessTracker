import 'package:sqflite/sqflite.dart';
import '../../../core/constants/database_tables.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/exercise_model.dart';
import 'database_helper.dart';

/// Local data source interface for Exercise operations
abstract class ExerciseLocalDataSource {
  Future<List<ExerciseModel>> getAllExercises();
  Future<ExerciseModel?> getExerciseById(String id);
  Future<ExerciseModel?> getExerciseByName(String name);
  Future<List<ExerciseModel>> getExercisesForMuscle(String muscleGroup);
  Future<void> insertExercise(ExerciseModel exercise);
  Future<void> updateExercise(ExerciseModel exercise);
  Future<void> deleteExercise(String id);
  Future<void> clearAllExercises();
}

/// SQLite implementation of Exercise local data source
class ExerciseLocalDataSourceImpl implements ExerciseLocalDataSource {
  final DatabaseHelper databaseHelper;

  const ExerciseLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<ExerciseModel>> getAllExercises() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.exercises,
        orderBy: '${DatabaseTables.exerciseName} ASC',
      );
      return maps.map((map) => ExerciseModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get exercises: $e');
    }
  }

  @override
  Future<ExerciseModel?> getExerciseById(String id) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.exercises,
        where: '${DatabaseTables.exerciseId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return ExerciseModel.fromMap(maps.first);
    } catch (e) {
      throw CacheDatabaseException('Failed to get exercise: $e');
    }
  }

  @override
  Future<ExerciseModel?> getExerciseByName(String name) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.exercises,
        where: 'LOWER(${DatabaseTables.exerciseName}) = LOWER(?)',
        whereArgs: [name],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return ExerciseModel.fromMap(maps.first);
    } catch (e) {
      throw CacheDatabaseException('Failed to get exercise by name: $e');
    }
  }

  @override
  Future<List<ExerciseModel>> getExercisesForMuscle(String muscleGroup) async {
    try {
      final db = await databaseHelper.database;
      // SQLite doesn't have native JSON querying, so we use LIKE with wildcards
      // This searches for the muscle group within the JSON array
      final maps = await db.query(
        DatabaseTables.exercises,
        where: '${DatabaseTables.exerciseMuscleGroups} LIKE ?',
        whereArgs: ['%"$muscleGroup"%'],
        orderBy: '${DatabaseTables.exerciseName} ASC',
      );
      return maps.map((map) => ExerciseModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get exercises for muscle: $e');
    }
  }

  @override
  Future<void> insertExercise(ExerciseModel exercise) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseTables.exercises,
        exercise.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to insert exercise: $e');
    }
  }

  @override
  Future<void> updateExercise(ExerciseModel exercise) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseTables.exercises,
        exercise.toMap(),
        where: '${DatabaseTables.exerciseId} = ?',
        whereArgs: [exercise.id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to update exercise: $e');
    }
  }

  @override
  Future<void> deleteExercise(String id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        DatabaseTables.exercises,
        where: '${DatabaseTables.exerciseId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to delete exercise: $e');
    }
  }

  @override
  Future<void> clearAllExercises() async {
    try {
      final db = await databaseHelper.database;
      await db.delete(DatabaseTables.exercises);
    } catch (e) {
      throw CacheDatabaseException('Failed to clear exercises: $e');
    }
  }
}
