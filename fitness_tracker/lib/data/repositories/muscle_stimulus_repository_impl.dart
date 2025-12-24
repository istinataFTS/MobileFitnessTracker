import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/muscle_stimulus.dart';
import '../../domain/repositories/muscle_stimulus_repository.dart';
import '../datasources/local/muscle_stimulus_local_datasource.dart';
import '../models/muscle_stimulus_model.dart';

/// Repository implementation for MuscleStimulus operations
/// 
/// Converts between domain entities and data models
/// Handles error conversion (exceptions → failures)
class MuscleStimulusRepositoryImpl implements MuscleStimulusRepository {
  final MuscleStimulusLocalDataSource localDataSource;

  const MuscleStimulusRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, MuscleStimulus?>> getStimulusByMuscleAndDate({
    required String muscleGroup,
    required DateTime date,
  }) async {
    try {
      final stimulus = await localDataSource.getStimulusByMuscleAndDate(
        muscleGroup: muscleGroup,
        date: date,
      );
      return Right(stimulus);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MuscleStimulus>>> getStimulusByDateRange({
    required String muscleGroup,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final stimulusList = await localDataSource.getStimulusByDateRange(
        muscleGroup: muscleGroup,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(stimulusList);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, MuscleStimulus?>> getTodayStimulus(
    String muscleGroup,
  ) async {
    try {
      final stimulus = await localDataSource.getTodayStimulus(muscleGroup);
      return Right(stimulus);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MuscleStimulus>>> getAllStimulusForDate(
    DateTime date,
  ) async {
    try {
      final stimulusList = await localDataSource.getAllStimulusForDate(date);
      return Right(stimulusList);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> upsertStimulus(MuscleStimulus stimulus) async {
    try {
      final model = MuscleStimulusModel.fromEntity(stimulus);
      await localDataSource.upsertStimulus(model);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateStimulusValues({
    required String id,
    required double dailyStimulus,
    required double rollingWeeklyLoad,
    int? lastSetTimestamp,
    double? lastSetStimulus,
  }) async {
    try {
      await localDataSource.updateStimulusValues(
        id: id,
        dailyStimulus: dailyStimulus,
        rollingWeeklyLoad: rollingWeeklyLoad,
        lastSetTimestamp: lastSetTimestamp,
        lastSetStimulus: lastSetStimulus,
      );
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> applyDailyDecayToAll() async {
    try {
      await localDataSource.applyDailyDecayToAll();
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getMaxStimulusForMuscle(
    String muscleGroup,
  ) async {
    try {
      final maxStimulus = await localDataSource.getMaxStimulusForMuscle(muscleGroup);
      return Right(maxStimulus);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOlderThan(DateTime date) async {
    try {
      await localDataSource.deleteOlderThan(date);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllStimulus() async {
    try {
      await localDataSource.clearAllStimulus();
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }
}