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
    required this.exercises,
  });

  final List<Target> targets;
  final List<WorkoutSet> weeklySets;
  final List<NutritionLog> todaysLogs;
  final Map<String, double> dailyMacros;
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
        exercises,
      ];
}