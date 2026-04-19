import 'package:equatable/equatable.dart';

import '../../../../domain/entities/exercise.dart';
import '../../../../domain/entities/nutrition_log.dart';
import '../../../../domain/entities/target.dart';
import '../../../../domain/entities/workout_set.dart';

class HomeDashboardData extends Equatable {
  const HomeDashboardData({
    required this.targets,
    required this.weeklySets,
    required this.todaysLogs,
    required this.dailyMacros,
    this.muscleSetCounts = const <String, int>{},
    this.exercises = const <Exercise>[],
  });

  final List<Target> targets;
  final List<WorkoutSet> weeklySets;
  final List<NutritionLog> todaysLogs;
  final Map<String, double> dailyMacros;

  /// Weekly set counts per muscle group, resolved via [MuscleLoadResolver].
  ///
  /// Keyed by normalised muscle-group slug (lowercase, trimmed).  Empty when
  /// the user is a guest or when the resolver is unavailable.
  final Map<String, int> muscleSetCounts;

  /// Kept for legacy test compatibility — not consumed by the presentation
  /// layer after Phase 4.  Will be removed in a later cleanup phase.
  final List<Exercise> exercises;

  static const Map<String, double> emptyDailyMacros = <String, double>{
    'protein': 0.0,
    'carbs': 0.0,
    'fats': 0.0,
    'calories': 0.0,
  };

  @override
  List<Object?> get props => <Object?>[
        targets,
        weeklySets,
        todaysLogs,
        dailyMacros,
        muscleSetCounts,
        exercises,
      ];
}