import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/services.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/env_config.dart';
import 'core/constants/app_strings.dart';
import 'core/themes/app_theme.dart';
import 'core/utils/app_lifecycle_manager.dart';
import 'core/utils/performance_monitor.dart';
import 'core/utils/app_diagnostics.dart';
import 'presentation/navigation/bottom_navigation.dart';
import 'injection/injection_container.dart' as di;
import 'presentation/pages/targets/bloc/targets_bloc.dart';
import 'presentation/pages/log/bloc/workout_bloc.dart';
import 'presentation/pages/home/bloc/home_bloc.dart';
import 'presentation/pages/home/bloc/muscle_visual_bloc.dart'; // NEW: Phase 6
import 'presentation/pages/exercises/bloc/exercise_bloc.dart';
import 'presentation/pages/history/bloc/history_bloc.dart';
import 'presentation/pages/meals/bloc/meal_bloc.dart';
import 'presentation/pages/nutrition_log/bloc/nutrition_log_bloc.dart';
import 'domain/usecases/exercises/seed_exercises.dart';
import 'domain/usecases/muscle_factors/seed_exercise_factors.dart';
import 'domain/entities/time_period.dart'; // NEW: For MuscleVisualBloc

void main() async {
  PerformanceMonitor.startTimer('app_initialization');
  
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kDebugMode) {
    EnvConfig.printConfig();
  }
  
  EnvConfig.validateProductionConfig();
  AppLifecycleManager().initialize();
  
  if (!kIsWeb) {
    try {
      debugPrint('Initializing dependencies...');
      final initStart = DateTime.now();
      await di.init();
      final initDuration = DateTime.now().difference(initStart);
      debugPrint('✅ Dependencies initialized in: ${initDuration.inMilliseconds}ms');
      
      if (EnvConfig.seedDefaultData) {
        debugPrint('Seeding database...');
        final seedStart = DateTime.now();
        
        // Seed exercises
        final seedExercises = di.sl<SeedExercises>();
        final exercisesResult = await seedExercises();
        
        await exercisesResult.fold(
          (failure) async {
            debugPrint('⚠️  Exercise seeding failed: ${failure.message}');
          },
          (exerciseCount) async {
            final exerciseDuration = DateTime.now().difference(seedStart);
            debugPrint('✅ Seeded $exerciseCount exercises in: ${exerciseDuration.inMilliseconds}ms');
            
            // ⭐ NEW: Seed muscle factors (Phase 4)
            final factorSeedStart = DateTime.now();
            final seedFactors = di.sl<SeedExerciseFactors>();
            final factorsResult = await seedFactors();
            
            factorsResult.fold(
              (failure) {
                debugPrint('⚠️  Muscle factor seeding failed: ${failure.message}');
              },
              (factorCount) {
                final factorDuration = DateTime.now().difference(factorSeedStart);
                debugPrint('✅ Seeded $factorCount muscle factors in: ${factorDuration.inMilliseconds}ms');
              },
            );
          },
        );
        
        final totalSeedDuration = DateTime.now().difference(seedStart);
        debugPrint('✅ Database seeding completed in: ${totalSeedDuration.inMilliseconds}ms');
      }
      
      if (kDebugMode) {
        await AppDiagnostics.runDiagnostics();
      }
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
      rethrow;
    }
  }

  final totalInitTime = PerformanceMonitor.stopTimer('app_initialization');
  debugPrint('🚀 App initialization complete in: ${totalInitTime}ms');

  runApp(
    kDebugMode && !kIsWeb
        ? DevicePreview(
            enabled: false, // Set to true to enable DevicePreview
            builder: (context) => const FitnessTrackerApp(),
          )
        : const FitnessTrackerApp(),
  );
}

class FitnessTrackerApp extends StatelessWidget {
  const FitnessTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebApp();
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<TargetsBloc>(
          create: (context) => di.sl<TargetsBloc>()..add(LoadTargetsEvent()),
        ),
        BlocProvider<WorkoutBloc>(
          create: (context) => di.sl<WorkoutBloc>()..add(const LoadWeeklySetsEvent()),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => di.sl<HomeBloc>()..add(LoadHomeDataEvent()),
        ),
        // ⭐ NEW: MuscleVisualBloc (Phase 6)
        BlocProvider<MuscleVisualBloc>(
          create: (context) => di.sl<MuscleVisualBloc>()
            ..add(const LoadMuscleVisualsEvent(TimePeriod.week)),
        ),
        BlocProvider<ExerciseBloc>(
          create: (context) => di.sl<ExerciseBloc>()..add(LoadExercisesEvent()),
        ),
        BlocProvider<HistoryBloc>(
          create: (context) => di.sl<HistoryBloc>(),
        ),
        BlocProvider<MealBloc>(
          create: (context) => di.sl<MealBloc>()..add(LoadMealsEvent()),
        ),
        BlocProvider<NutritionLogBloc>(
          create: (context) => di.sl<NutritionLogBloc>()
            ..add(LoadDailyLogsEvent(DateTime.now())),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const BottomNavigation(),
        builder: DevicePreview.appBuilder,
        locale: DevicePreview.locale(context),
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.unknown,
          },
        ),
      ),
    );
  }

  Widget _buildWebApp() {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.web,
                size: 100,
                color: AppTheme.primaryOrange,
              ),
              SizedBox(height: 20),
              Text(
                'Web Version Coming Soon',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Please use the mobile app',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}