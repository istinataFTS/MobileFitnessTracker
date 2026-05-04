import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/history/history.dart';
import '../../features/home/application/home_bloc.dart';
import '../../features/home/application/muscle_visual_bloc.dart';
import '../../features/log/log.dart';

class AppDomainEffectsListener extends StatefulWidget {
  const AppDomainEffectsListener({required this.child, super.key});

  final Widget child;

  @override
  State<AppDomainEffectsListener> createState() =>
      _AppDomainEffectsListenerState();
}

class _AppDomainEffectsListenerState extends State<AppDomainEffectsListener> {
  StreamSubscription<WorkoutUiEffect>? _workoutEffectsSub;
  StreamSubscription<NutritionLogUiEffect>? _nutritionEffectsSub;
  StreamSubscription<HistoryUiEffect>? _historyEffectsSub;

  @override
  void initState() {
    super.initState();

    final WorkoutBloc workoutBloc = context.read<WorkoutBloc>();
    final NutritionLogBloc nutritionLogBloc = context.read<NutritionLogBloc>();
    final HistoryBloc historyBloc = context.read<HistoryBloc>();

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

    _historyEffectsSub = historyBloc.effects.listen((effect) {
      if (!mounted) {
        return;
      }

      if (effect is HistorySuccessEffect) {
        context.read<HomeBloc>().add(const RefreshHomeDataEvent());
        context.read<WorkoutBloc>().add(const RefreshWeeklySetsEvent());
        context.read<MuscleVisualBloc>().add(const RefreshVisualsEvent());
      }
    });
  }

  @override
  void dispose() {
    _workoutEffectsSub?.cancel();
    _nutritionEffectsSub?.cancel();
    _historyEffectsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
