import 'dart:ui';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/env_config.dart';
import '../core/constants/app_strings.dart';
import '../core/themes/app_theme.dart';
import '../features/history/history.dart';
import '../injection/injection_container.dart' as di;
import '../presentation/navigation/bottom_navigation.dart';
import '../presentation/pages/exercises/bloc/exercise_bloc.dart';
import '../presentation/pages/home/bloc/home_bloc.dart';
import '../presentation/pages/home/bloc/muscle_visual_bloc.dart';
import '../presentation/pages/log/bloc/workout_bloc.dart';
import '../presentation/pages/meals/bloc/meal_bloc.dart';
import '../presentation/pages/nutrition_log/bloc/nutrition_log_bloc.dart';
import '../presentation/pages/targets/bloc/targets_bloc.dart';
import 'startup/app_startup_listener.dart';

class AppHost extends StatelessWidget {
  const AppHost({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !EnvConfig.enableDevicePreview) {
      return const FitnessTrackerApp();
    }

    return DevicePreview(
      enabled: EnvConfig.enableDevicePreview,
      builder: (_) => const FitnessTrackerApp(),
    );
  }
}

class FitnessTrackerApp extends StatelessWidget {
  const FitnessTrackerApp({super.key});

  Widget _buildWebHome() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.web,
              size: 100,
              color: AppTheme.primaryOrange,
            ),
            SizedBox(height: 20),
            Text(
              AppStrings.webMobileOnlyTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                AppStrings.webMobileOnlyDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textMedium,
                ),
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                AppStrings.webMobileOnlyInstruction,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDim,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return AppShell(
        home: _buildWebHome(),
      );
    }

    return MultiBlocProvider(
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
      child: AppShell(
        builder: DevicePreview.appBuilder,
        locale: DevicePreview.locale(context),
        home: const AppStartupListener(
          child: BottomNavigation(),
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
        dragDevices: const {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
    );
  }
}