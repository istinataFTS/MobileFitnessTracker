import 'dart:ui';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/env_config.dart';
import '../core/constants/app_strings.dart';
import '../core/themes/app_theme.dart';
import '../features/history/history.dart';
import '../features/home/application/home_bloc.dart';
import '../features/home/application/muscle_visual_bloc.dart';
import '../features/log/log.dart';
import '../features/settings/application/app_settings_cubit.dart';
import '../injection/injection_container.dart' as di;
import '../presentation/navigation/bottom_navigation.dart';
import '../presentation/pages/exercises/bloc/exercise_bloc.dart';
import '../presentation/pages/meals/bloc/meal_bloc.dart';
import '../presentation/pages/nutrition_log/bloc/nutrition_log_bloc.dart';
import '../presentation/pages/targets/bloc/targets_bloc.dart';
import 'listeners/app_domain_effects_listener.dart';
import 'startup/app_startup_listener.dart';

class AppHost extends StatelessWidget {
  const AppHost({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !EnvConfig.enableDevicePreview) {
      return const FitnessTrackerApp(
        useDevicePreviewAdapters: false,
      );
    }

    return DevicePreview(
      enabled: true,
      builder: (_) => const FitnessTrackerApp(
        useDevicePreviewAdapters: true,
      ),
    );
  }
}

class FitnessTrackerApp extends StatelessWidget {
  const FitnessTrackerApp({
    super.key,
    this.useDevicePreviewAdapters = false,
  });

  final bool useDevicePreviewAdapters;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<AppSettingsCubit>(
          create: (_) => AppSettingsCubit(
            repository: di.sl(),
          )..loadSettings(),
        ),
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
      child: AppShell(
        builder: useDevicePreviewAdapters ? DevicePreview.appBuilder : null,
        locale: useDevicePreviewAdapters ? DevicePreview.locale(context) : null,
        home: const AppStartupListener(
          child: AppDomainEffectsListener(
            child: BottomNavigation(),
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({
    required this.home,
    super.key,
    this.builder,
    this.locale,
  });

  final Widget home;
  final TransitionBuilder? builder;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: locale,
      builder: builder,
      home: home,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: const <PointerDeviceKind>{
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
    );
  }
}