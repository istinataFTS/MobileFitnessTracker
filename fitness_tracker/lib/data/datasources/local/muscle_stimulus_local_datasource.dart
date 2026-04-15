import 'package:sqflite/sqflite.dart';
import '../../../core/constants/database_tables.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/muscle_stimulus_model.dart';
import 'database_helper.dart';

/// Local data source interface for MuscleStimulus operations.
///
/// Every query method that reads or writes user-specific records accepts a
/// [userId] parameter so that data from different profiles never leaks across
/// accounts.  An empty string (`''`) represents the guest / unauthenticated
/// state, matching the `DEFAULT ''` set on the `owner_user_id` column.
abstract class MuscleStimulusLocalDataSource {
  /// Get stimulus for a specific muscle on a specific date.
  Future<MuscleStimulusModel?> getStimulusByMuscleAndDate({
    required String userId,
    required String muscleGroup,
    required DateTime date,
  });

  /// Get all stimulus records for a muscle within a date range.
  Future<List<MuscleStimulusModel>> getStimulusByDateRange({
    required String userId,
    required String muscleGroup,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get today's stimulus for a specific muscle.
  Future<MuscleStimulusModel?> getTodayStimulus(
    String userId,
    String muscleGroup,
  );

  /// Get all stimulus records for all muscles on a specific date.
  Future<List<MuscleStimulusModel>> getAllStimulusForDate(
    String userId,
    DateTime date,
  );

  /// Insert or update a stimulus record.
  /// The [userId] is embedded on the model's [ownerUserId] field.
  Future<void> upsertStimulus(MuscleStimulusModel stimulus);

  /// Update daily stimulus and rolling weekly load for an existing record.
  Future<void> updateStimulusValues({
    required String id,
    required double dailyStimulus,
    required double rollingWeeklyLoad,
    int? lastSetTimestamp,
    double? lastSetStimulus,
  });

  /// Apply daily decay to all muscle records owned by [userId].
  Future<void> applyDailyDecayToAll(String userId);

  /// Get maximum daily stimulus ever recorded for a muscle owned by [userId].
  Future<double> getMaxStimulusForMuscle(String userId, String muscleGroup);

  /// Delete stimulus records older than [date] for [userId].
  Future<void> deleteOlderThan(String userId, DateTime date);

  /// Clear all stimulus records across every user.
  /// Use this only when performing a full per-user rebuild via
  /// [clearStimulusForUser] first, or in tests.
  Future<void> clearAllStimulus();

  /// Remove all stimulus records belonging to [userId].
  /// Called on sign-out to prevent data leaking to the next session.
  Future<void> clearStimulusForUser(String userId);
}

/// SQLite implementation of [MuscleStimulusLocalDataSource].
class MuscleStimulusLocalDataSourceImpl
    implements MuscleStimulusLocalDataSource {
  final DatabaseHelper databaseHelper;

  const MuscleStimulusLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<MuscleStimulusModel?> getStimulusByMuscleAndDate({
    required String userId,
    required String muscleGroup,
    required DateTime date,
  }) async {
    try {
      final db = await databaseHelper.database;
      final dateString = MuscleStimulusModel.formatDateForDb(date);

      final maps = await db.query(
        DatabaseTables.muscleStimulus,
        where: '${DatabaseTables.ownerUserId} = ? '
            'AND ${DatabaseTables.stimulusMuscleGroup} = ? '
            'AND ${DatabaseTables.stimulusDate} = ?',
        whereArgs: [userId, muscleGroup, dateString],
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
    required String userId,
    required String muscleGroup,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await databaseHelper.database;
      final startDateString = MuscleStimulusModel.formatDateForDb(startDate);
      final endDateString = MuscleStimulusModel.formatDateForDb(endDate);

      final maps = await db.query(
        DatabaseTables.muscleStimulus,
        where: '${DatabaseTables.ownerUserId} = ? '
            'AND ${DatabaseTables.stimulusMuscleGroup} = ? '
            'AND ${DatabaseTables.stimulusDate} >= ? '
            'AND ${DatabaseTables.stimulusDate} <= ?',
        whereArgs: [userId, muscleGroup, startDateString, endDateString],
        orderBy: '${DatabaseTables.stimulusDate} DESC',
      );

      return maps.map((map) => MuscleStimulusModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get stimulus by date range: $e');
    }
  }

  @override
  Future<MuscleStimulusModel?> getTodayStimulus(
    String userId,
    String muscleGroup,
  ) {
    return getStimulusByMuscleAndDate(
      userId: userId,
      muscleGroup: muscleGroup,
      date: DateTime.now(),
    );
  }

  @override
  Future<List<MuscleStimulusModel>> getAllStimulusForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final db = await databaseHelper.database;
      final dateString = MuscleStimulusModel.formatDateForDb(date);

      final maps = await db.query(
        DatabaseTables.muscleStimulus,
        where: '${DatabaseTables.ownerUserId} = ? '
            'AND ${DatabaseTables.stimulusDate} = ?',
        whereArgs: [userId, dateString],
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

      final updateMap = <String, Object?>{
        DatabaseTables.stimulusDailyStimulus: dailyStimulus,
        DatabaseTables.stimulusRollingWeeklyLoad: rollingWeeklyLoad,
        DatabaseTables.stimulusUpdatedAt: DateTime.now().toIso8601String(),
      };

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
  Future<void> applyDailyDecayToAll(String userId) async {
    try {
      final db = await databaseHelper.database;

      final maps = await db.query(
        DatabaseTables.muscleStimulus,
        where: '${DatabaseTables.ownerUserId} = ?',
        whereArgs: [userId],
      );
      final stimulusRecords =
          maps.map((map) => MuscleStimulusModel.fromMap(map)).toList();

      final batch = db.batch();
      for (final stimulus in stimulusRecords) {
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
  Future<double> getMaxStimulusForMuscle(
    String userId,
    String muscleGroup,
  ) async {
    try {
      final db = await databaseHelper.database;

      final result = await db.rawQuery(
        'SELECT MAX(${DatabaseTables.stimulusDailyStimulus}) as max_stimulus '
        'FROM ${DatabaseTables.muscleStimulus} '
        'WHERE ${DatabaseTables.ownerUserId} = ? '
        'AND ${DatabaseTables.stimulusMuscleGroup} = ?',
        [userId, muscleGroup],
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
  Future<void> deleteOlderThan(String userId, DateTime date) async {
    try {
      final db = await databaseHelper.database;
      final dateString = MuscleStimulusModel.formatDateForDb(date);

      await db.delete(
        DatabaseTables.muscleStimulus,
        where: '${DatabaseTables.ownerUserId} = ? '
            'AND ${DatabaseTables.stimulusDate} < ?',
        whereArgs: [userId, dateString],
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

  @override
  Future<void> clearStimulusForUser(String userId) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        DatabaseTables.muscleStimulus,
        where: '${DatabaseTables.ownerUserId} = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw CacheDatabaseException(
        'Failed to clear stimulus records for user: $e',
      );
    }
  }
}
