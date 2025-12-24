import 'package:sqflite/sqflite.dart';
import '../../../core/constants/database_tables.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/muscle_stimulus_model.dart';
import 'database_helper.dart';

/// Local data source interface for MuscleStimulus operations
abstract class MuscleStimulusLocalDataSource {
  /// Get stimulus for a specific muscle on a specific date
  Future<MuscleStimulusModel?> getStimulusByMuscleAndDate({
    required String muscleGroup,
    required DateTime date,
  });
  
  /// Get all stimulus records for a muscle within a date range
  Future<List<MuscleStimulusModel>> getStimulusByDateRange({
    required String muscleGroup,
    required DateTime startDate,
    required DateTime endDate,
  });
  
  /// Get today's stimulus for a specific muscle
  Future<MuscleStimulusModel?> getTodayStimulus(String muscleGroup);
  
  /// Get all stimulus records for all muscles on a specific date
  Future<List<MuscleStimulusModel>> getAllStimulusForDate(DateTime date);
  
  /// Insert or update stimulus record
  Future<void> upsertStimulus(MuscleStimulusModel stimulus);
  
  /// Update daily stimulus and rolling weekly load
  Future<void> updateStimulusValues({
    required String id,
    required double dailyStimulus,
    required double rollingWeeklyLoad,
    int? lastSetTimestamp,
    double? lastSetStimulus,
  });
  
  /// Apply daily decay to all muscles (for new day transition)
  Future<void> applyDailyDecayToAll();
  
  /// Get maximum daily stimulus ever recorded for a muscle
  Future<double> getMaxStimulusForMuscle(String muscleGroup);
  
  /// Delete stimulus records older than a certain date (cleanup)
  Future<void> deleteOlderThan(DateTime date);
  
  /// Clear all stimulus records
  Future<void> clearAllStimulus();
}

/// SQLite implementation of MuscleStimulus local data source
class MuscleStimulusLocalDataSourceImpl implements MuscleStimulusLocalDataSource {
  final DatabaseHelper databaseHelper;

  const MuscleStimulusLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<MuscleStimulusModel?> getStimulusByMuscleAndDate({
    required String muscleGroup,
    required DateTime date,
  }) async {
    try {
      final db = await databaseHelper.database;
      final dateString = MuscleStimulusModel._formatDateForDb(date);
      
      final maps = await db.query(
        DatabaseTables.muscleStimulus,
        where: '${DatabaseTables.stimulusMuscleGroup} = ? AND ${DatabaseTables.stimulusDate} = ?',
        whereArgs: [muscleGroup, dateString],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return MuscleStimulusModel.fromMap(maps.first);
    } catch (e) {
      throw CacheDatabaseException('Failed to get stimulus: $e');
    }
  }

  @override
  Future<List<MuscleStimulusModel>> getStimulusByDateRange({
    required String muscleGroup,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await databaseHelper.database;
      final startDateString = MuscleStimulusModel._formatDateForDb(startDate);
      final endDateString = MuscleStimulusModel._formatDateForDb(endDate);
      
      final maps = await db.query(
        DatabaseTables.muscleStimulus,
        where: '${DatabaseTables.stimulusMuscleGroup} = ? AND ${DatabaseTables.stimulusDate} >= ? AND ${DatabaseTables.stimulusDate} <= ?',
        whereArgs: [muscleGroup, startDateString, endDateString],
        orderBy: '${DatabaseTables.stimulusDate} DESC',
      );

      return maps.map((map) => MuscleStimulusModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get stimulus by date range: $e');
    }
  }

  @override
  Future<MuscleStimulusModel?> getTodayStimulus(String muscleGroup) async {
    return getStimulusByMuscleAndDate(
      muscleGroup: muscleGroup,
      date: DateTime.now(),
    );
  }

  @override
  Future<List<MuscleStimulusModel>> getAllStimulusForDate(DateTime date) async {
    try {
      final db = await databaseHelper.database;
      final dateString = MuscleStimulusModel._formatDateForDb(date);
      
      final maps = await db.query(
        DatabaseTables.muscleStimulus,
        where: '${DatabaseTables.stimulusDate} = ?',
        whereArgs: [dateString],
      );

      return maps.map((map) => MuscleStimulusModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get all stimulus for date: $e');
    }
  }

  @override
  Future<void> upsertStimulus(MuscleStimulusModel stimulus) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseTables.muscleStimulus,
        stimulus.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to upsert stimulus: $e');
    }
  }

  @override
  Future<void> updateStimulusValues({
    required String id,
    required double dailyStimulus,
    required double rollingWeeklyLoad,
    int? lastSetTimestamp,
    double? lastSetStimulus,
  }) async {
    try {
      final db = await databaseHelper.database;
      
      final updateMap = {
        DatabaseTables.stimulusDailyStimulus: dailyStimulus,
        DatabaseTables.stimulusRollingWeeklyLoad: rollingWeeklyLoad,
        DatabaseTables.stimulusUpdatedAt: DateTime.now().toIso8601String(),
      };
      
      // Only update timestamp fields if provided
      if (lastSetTimestamp != null) {
        updateMap[DatabaseTables.stimulusLastSetTimestamp] = lastSetTimestamp;
      }
      if (lastSetStimulus != null) {
        updateMap[DatabaseTables.stimulusLastSetStimulus] = lastSetStimulus;
      }
      
      await db.update(
        DatabaseTables.muscleStimulus,
        updateMap,
        where: '${DatabaseTables.stimulusId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to update stimulus values: $e');
    }
  }

  @override
  Future<void> applyDailyDecayToAll() async {
    try {
      final db = await databaseHelper.database;
      
      // Get all stimulus records
      final maps = await db.query(DatabaseTables.muscleStimulus);
      final stimulusRecords = maps.map((map) => MuscleStimulusModel.fromMap(map)).toList();
      
      // Apply decay to each record
      final batch = db.batch();
      for (final stimulus in stimulusRecords) {
        // Decay factor from constants (0.6)
        final decayedLoad = stimulus.rollingWeeklyLoad * 0.6;
        
        batch.update(
          DatabaseTables.muscleStimulus,
          {
            DatabaseTables.stimulusRollingWeeklyLoad: decayedLoad,
            DatabaseTables.stimulusUpdatedAt: DateTime.now().toIso8601String(),
          },
          where: '${DatabaseTables.stimulusId} = ?',
          whereArgs: [stimulus.id],
        );
      }
      
      await batch.commit(noResult: true);
    } catch (e) {
      throw CacheDatabaseException('Failed to apply daily decay: $e');
    }
  }

  @override
  Future<double> getMaxStimulusForMuscle(String muscleGroup) async {
    try {
      final db = await databaseHelper.database;
      
      final result = await db.rawQuery(
        'SELECT MAX(${DatabaseTables.stimulusDailyStimulus}) as max_stimulus '
        'FROM ${DatabaseTables.muscleStimulus} '
        'WHERE ${DatabaseTables.stimulusMuscleGroup} = ?',
        [muscleGroup],
      );

      if (result.isEmpty || result.first['max_stimulus'] == null) {
        return 0.0;
      }

      return (result.first['max_stimulus'] as num).toDouble();
    } catch (e) {
      throw CacheDatabaseException('Failed to get max stimulus: $e');
    }
  }

  @override
  Future<void> deleteOlderThan(DateTime date) async {
    try {
      final db = await databaseHelper.database;
      final dateString = MuscleStimulusModel._formatDateForDb(date);
      
      await db.delete(
        DatabaseTables.muscleStimulus,
        where: '${DatabaseTables.stimulusDate} < ?',
        whereArgs: [dateString],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to delete old stimulus records: $e');
    }
  }

  @override
  Future<void> clearAllStimulus() async {
    try {
      final db = await databaseHelper.database;
      await db.delete(DatabaseTables.muscleStimulus);
    } catch (e) {
      throw CacheDatabaseException('Failed to clear stimulus records: $e');
    }
  }
}