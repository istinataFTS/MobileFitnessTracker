import '../../../../core/time/clock.dart';
import '../../../../domain/entities/nutrition_log.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../../../domain/usecases/nutrition_logs/get_logs_for_date.dart';
import '../../../../domain/usecases/workout_sets/get_sets_by_date_range.dart';

/// Provides "most recent entity" lookups needed by the offline edit/delete
/// matchers.
///
/// Uses the same use cases as the online VoiceBloc path so offline edit/delete
/// resolve against the same data visible to the LLM in the online flow.
class RecentEntityLookup {
  RecentEntityLookup({
    required GetSetsByDateRange getSetsByDateRange,
    required GetLogsForDate getLogsForDate,
    required Clock clock,
  }) : _getSetsByDateRange = getSetsByDateRange,
       _getLogsForDate = getLogsForDate,
       _clock = clock;

  final GetSetsByDateRange _getSetsByDateRange;
  final GetLogsForDate _getLogsForDate;
  final Clock _clock;

  /// Returns the most recently created [WorkoutSet] within [within] of now,
  /// or null if no sets exist in that window.
  ///
  /// The underlying datasource orders results newest-first
  /// (`set_date DESC, set_created_at DESC`), so the most recent set is
  /// `sets.first`. This must stay aligned with the VoiceBloc recent-set
  /// cache (`take(5)` of the same query) so offline edit/delete can resolve
  /// the resulting id back to a full entity.
  Future<WorkoutSet?> mostRecentSet({
    Duration within = const Duration(hours: 24),
  }) async {
    final now = _clock.now();
    final result = await _getSetsByDateRange(
      startDate: now.subtract(within),
      endDate: now,
    );
    return result.fold((_) => null, (sets) => sets.isEmpty ? null : sets.first);
  }

  /// Returns the most recently logged [NutritionLog] for today,
  /// or null if nothing was logged today.
  ///
  /// The datasource orders logs `created_at DESC`, so the most recent log
  /// is `logs.first`.
  Future<NutritionLog?> mostRecentLog() async {
    final result = await _getLogsForDate(_clock.now());
    return result.fold((_) => null, (logs) => logs.isEmpty ? null : logs.first);
  }
}
