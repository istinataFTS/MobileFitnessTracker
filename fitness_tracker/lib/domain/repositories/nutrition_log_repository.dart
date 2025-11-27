import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/nutrition_log.dart';

/// Repository interface for NutritionLog operations
/// 
/// Handles both meal-based logs and direct macro logs through
/// a unified interface. Follows Clean Architecture principles.
abstract class NutritionLogRepository {
  /// Get all nutrition logs from storage
  /// Typically sorted by date (most recent first)
  Future<Either<Failure, List<NutritionLog>>> getAllLogs();

  /// Get a specific log by ID
  /// Returns null wrapped in Right if log doesn't exist
  Future<Either<Failure, NutritionLog?>> getLogById(String id);

  /// Get all logs for a specific date
  /// Useful for daily nutrition summary
  Future<Either<Failure, List<NutritionLog>>> getLogsByDate(DateTime date);

  /// Get logs within a date range (inclusive)
  /// Used for weekly/monthly summaries and history views
  Future<Either<Failure, List<NutritionLog>>> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get all logs for a specific meal ID
  /// Useful for analytics: "When did I last eat this meal?"
  Future<Either<Failure, List<NutritionLog>>> getLogsByMealId(String mealId);

  /// Get today's logs
  /// Convenience method for daily tracking
  Future<Either<Failure, List<NutritionLog>>> getTodayLogs();

  /// Get logs for current week
  /// Convenience method for weekly summaries
  Future<Either<Failure, List<NutritionLog>>> getWeeklyLogs();

  /// Get only meal-based logs (excludes direct macro logs)
  /// Useful for meal frequency analysis
  Future<Either<Failure, List<NutritionLog>>> getMealLogs();

  /// Get only direct macro logs (excludes meal-based logs)
  /// Useful for tracking manual entries
  Future<Either<Failure, List<NutritionLog>>> getDirectMacroLogs();

  /// Add a new nutrition log
  Future<Either<Failure, void>> addLog(NutritionLog log);

  /// Update an existing nutrition log
  /// Returns error if log doesn't exist
  Future<Either<Failure, void>> updateLog(NutritionLog log);

  /// Delete a log by ID
  Future<Either<Failure, void>> deleteLog(String id);

  /// Delete all logs for a specific date
  /// Useful for "clear today's entries" functionality
  Future<Either<Failure, void>> deleteLogsByDate(DateTime date);

  /// Delete all logs for a specific meal ID
  /// Used when a meal is deleted (cascade deletion)
  Future<Either<Failure, void>> deleteLogsByMealId(String mealId);

  /// Clear all nutrition logs
  /// WARNING: Use with caution - typically for testing or reset functionality
  Future<Either<Failure, void>> clearAllLogs();

  /// Get total count of logs
  /// Useful for analytics or UI display
  Future<Either<Failure, int>> getLogsCount();

  /// Get daily macro totals for a specific date
  /// Returns aggregated carbs, protein, fat, and calories
  Future<Either<Failure, DailyMacros>> getDailyMacros(DateTime date);
}

/// Helper class for aggregated daily macros
class DailyMacros {
  final double totalCarbs;
  final double totalProtein;
  final double totalFat;
  final double totalCalories;
  final DateTime date;
  final int logsCount;

  const DailyMacros({
    required this.totalCarbs,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCalories,
    required this.date,
    required this.logsCount,
  });

  /// Check if any nutrition was logged
  bool get hasLogs => logsCount > 0;

  /// Calculate calories from macros (for validation)
  double get calculatedCalories {
    return (totalCarbs * 4.0) + (totalProtein * 4.0) + (totalFat * 9.0);
  }
}