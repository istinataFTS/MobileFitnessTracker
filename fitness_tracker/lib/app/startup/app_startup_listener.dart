import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/time_period.dart';
import '../../presentation/pages/exercises/bloc/exercise_bloc.dart';
import '../../presentation/pages/home/bloc/home_bloc.dart';
import '../../presentation/pages/home/bloc/muscle_visual_bloc.dart';
import '../../presentation/pages/log/bloc/workout_bloc.dart';
import '../../presentation/pages/meals/bloc/meal_bloc.dart';
import '../../presentation/pages/nutrition_log/bloc/nutrition_log_bloc.dart';
import '../../presentation/pages/targets/bloc/targets_bloc.dart';

class AppStartupListener extends StatefulWidget {
  const AppStartupListener({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<AppStartupListener> createState() => _AppStartupListenerState();
}

class _AppStartupListenerState extends State<AppStartupListener> {
  bool _didDispatchInitialLoads = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dispatchInitialLoads();
    });
  }

  void _dispatchInitialLoads() {
    if (!mounted || _didDispatchInitialLoads) {
      return;
    }

    _didDispatchInitialLoads = true;

    context.read<TargetsBloc>().add(LoadTargetsEvent());
    context.read<WorkoutBloc>().add(const LoadWeeklySetsEvent());
    context.read<HomeBloc>().add(LoadHomeDataEvent());
    context.read<MuscleVisualBloc>().add(
          const LoadMuscleVisualsEvent(TimePeriod.week),
        );
    context.read<ExerciseBloc>().add(LoadExercisesEvent());
    context.read<MealBloc>().add(LoadMealsEvent());
    context.read<NutritionLogBloc>().add(
          LoadDailyLogsEvent(DateTime.now()),
        );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}