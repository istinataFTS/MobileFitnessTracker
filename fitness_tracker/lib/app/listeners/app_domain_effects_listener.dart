import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/history/history.dart';
import '../../features/log/log.dart';
import '../../presentation/pages/home/bloc/home_bloc.dart';
import '../../presentation/pages/home/bloc/muscle_visual_bloc.dart';
import '../../presentation/pages/nutrition_log/bloc/nutrition_log_bloc.dart';

class AppDomainEffectsListener extends StatefulWidget {
  const AppDomainEffectsListener({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<AppDomainEffectsListener> createState() =>
      _AppDomainEffectsListenerState();
}

class _AppDomainEffectsListenerState extends State<AppDomainEffectsListener> {
  StreamSubscription<WorkoutUiEffect>? _workoutEffectsSub;
  StreamSubscription<NutritionLogUiEffect>? _nutritionEffectsSub;

  @override
  void initState() {
    super.initState();

    final WorkoutBloc workoutBloc = context.read<WorkoutBloc>();
    final NutritionLogBloc nutritionLogBloc = context.read<NutritionLogBloc>();

    _workoutEffectsSub = workoutBloc.effects.listen((effect) {
      if (!mounted) {
        return;
      }

      if (effect is WorkoutLoggedEffect) {
        context.read<HomeBloc>().add(RefreshHomeDataEvent());
        context.read<HistoryBloc>().add(const RefreshCurrentMonthEvent());
        context.read<WorkoutBloc>().add(const RefreshWeeklySetsEvent());
        context.read<MuscleVisualBloc>().add(const RefreshVisualsEvent());
      }
    });

    _nutritionEffectsSub = nutritionLogBloc.effects.listen((effect) {
      if (!mounted) {
        return;
      }

      if (effect is NutritionLogSuccessEffect) {
        context.read<HomeBloc>().add(RefreshHomeDataEvent());
        context.read<HistoryBloc>().add(const RefreshCurrentMonthEvent());
      }
    });
  }

  @override
  void dispose() {
    _workoutEffectsSub?.cancel();
    _nutritionEffectsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}