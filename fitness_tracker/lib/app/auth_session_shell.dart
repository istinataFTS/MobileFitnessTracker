import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/history/history.dart';
import '../features/home/application/home_bloc.dart';
import '../features/home/application/muscle_visual_bloc.dart';
import '../features/library/application/exercise_bloc.dart';
import '../features/library/application/meal_bloc.dart';
import '../features/log/application/nutrition_log_bloc.dart';
import '../features/log/log.dart';
import '../features/profile/application/profile_cubit.dart';
import '../features/targets/application/targets_bloc.dart';
import '../injection/injection_container.dart' as di;
import '../presentation/navigation/bottom_navigation.dart';
import 'listeners/app_domain_effects_listener.dart';
import 'startup/app_startup_listener.dart';

/// Establishes the authentication boundary in the widget tree.
///
/// Listens to [ProfileCubit] and derives a stable *session key* from the
/// current user id (`'guest'` when unauthenticated). A [KeyedSubtree] keyed
/// on that value wraps the entire user-scoped sub-tree.
///
/// **Why this matters:** when the session key changes (sign-out → `'guest'`,
/// or `'guest'` → a new authenticated user id), Flutter disposes the entire
/// old sub-tree in full before building the new one. Every user-data BLoC
/// underneath is closed and recreated, so no stale state from a previous
/// session can ever leak into the next. The one-shot guard flags inside
/// [AppStartupListener] and [BottomNavigation] reset naturally because their
/// owning [State] objects are destroyed along with the old tree.
///
/// Blocs that are *not* user-scoped ([AppSettingsCubit], [ProfileCubit]) live
/// above this widget and are unaffected by the key change.
class AuthSessionShell extends StatelessWidget {
  const AuthSessionShell({super.key});

  // Sentinel key used when no authenticated user is present.
  static const String _guestKey = 'guest';

  @override
  Widget build(BuildContext context) {
    // BlocSelector rebuilds only when the selected value changes, so the
    // keyed sub-tree is only torn down and rebuilt on a genuine user switch —
    // not on every ProfileState update (e.g. loading flags, profile edits).
    return BlocSelector<ProfileCubit, ProfileState, String>(
      selector: (ProfileState state) => state.session.user?.id ?? _guestKey,
      builder: (BuildContext context, String sessionKey) {
        return KeyedSubtree(
          key: ValueKey<String>(sessionKey),
          child: MultiBlocProvider(
            providers: <BlocProvider<dynamic>>[
              BlocProvider<TargetsBloc>(
                create: (_) => di.sl<TargetsBloc>(),
              ),
              BlocProvider<WorkoutBloc>(
                create: (_) => di.sl<WorkoutBloc>(),
              ),
              BlocProvider<HomeBloc>(
                create: (_) => di.sl<HomeBloc>(),
              ),
              BlocProvider<MuscleVisualBloc>(
                create: (_) => di.sl<MuscleVisualBloc>(),
              ),
              BlocProvider<ExerciseBloc>(
                create: (_) => di.sl<ExerciseBloc>(),
              ),
              BlocProvider<HistoryBloc>(
                create: (_) => di.sl<HistoryBloc>(),
              ),
              BlocProvider<MealBloc>(
                create: (_) => di.sl<MealBloc>(),
              ),
              BlocProvider<NutritionLogBloc>(
                create: (_) => di.sl<NutritionLogBloc>(),
              ),
            ],
            // AppStartupListener and AppDomainEffectsListener are intentionally
            // placed *inside* the keyed sub-tree so they re-subscribe to streams
            // and re-dispatch initial loads for every new session.
            child: const AppStartupListener(
              child: AppDomainEffectsListener(
                child: BottomNavigation(),
              ),
            ),
          ),
        );
      },
    );
  }
}
