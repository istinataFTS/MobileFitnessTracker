import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/muscle_factor.dart';

abstract class MuscleFactorRepository {

  Future<Either<Failure, List<MuscleFactor>>> getFactorsByExerciseId(String exerciseId);
  

  Future<Either<Failure, List<MuscleFactor>>> getFactorsByMuscleGroup(String muscleGroup);
  
  /// Get a specific muscle factor by ID
  Future<Either<Failure, MuscleFactor?>> getFactorById(String id);
  
  /// Add a new muscle factor
  Future<Either<Failure, void>> addFactor(MuscleFactor factor);
  
  /// Add multiple muscle factors
  Future<Either<Failure, void>> addFactorsBatch(List<MuscleFactor> factors);
  
  /// Update an existing muscle factor
  Future<Either<Failure, void>> updateFactor(MuscleFactor factor);
  
  /// Delete a muscle factor by ID
  Future<Either<Failure, void>> deleteFactor(String id);
  
  /// Delete all factors for an exercise
  Future<Either<Failure, void>> deleteFactorsByExerciseId(String exerciseId);
  
  /// Clear all muscle factors
  Future<Either<Failure, void>> clearAllFactors();
}