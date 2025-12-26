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
import 'presentation/pages/exercises/bloc/exercise_bloc.dart';
import 'presentation/pages/history/bloc/history_bloc.dart';
import 'presentation/pages/meals/bloc/meal_bloc.dart';
import 'presentation/pages/nutrition_log/bloc/nutrition_log_bloc.dart';
import 'domain/usecases/exercises/seed_exercises.dart';
import 'domain/usecases/muscle_factors/seed_exercise_factors.dart';

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
        // ==================== SEED EXERCISES ====================
        debugPrint('Seeding database with default exercises...');
        final seedStart = DateTime.now();
        
        final seedExercises = di.sl<SeedExercises>();
        final result = await seedExercises();
        
        final seedDuration = DateTime.now().difference(seedStart);
        
        result.fold(
          (failure) {
            debugPrint('❌ Exercise seeding failed: ${failure.message}');
          },
          (count) {
            debugPrint('✅ Exercise seeding completed in: ${seedDuration.inMilliseconds}ms');
            debugPrint('   Exercises seeded: $count');
          },
        );
        
        // ==================== SEED EXERCISE MUSCLE FACTORS ====================
        debugPrint('Seeding database with exercise muscle factors...');
        final factorSeedStart = DateTime.now();
        
        final seedFactors = di.sl<SeedExerciseFactors>();
        final factorResult = await seedFactors();
        
        final factorSeedDuration = DateTime.now().difference(factorSeedStart);
        
        factorResult.fold(
          (failure) {
            debugPrint('❌ Muscle factor seeding failed: ${failure.message}');
          },
          (count) {
            debugPrint('✅ Muscle factor seeding completed in: ${factorSeedDuration.inMilliseconds}ms');
            debugPrint('   Muscle factors seeded: $count');
          },
        );
      }
      
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
      rethrow;
    }
  }
  
  PerformanceMonitor.endTimer('app_initialization');
  
  if (EnvConfig.enableDebugLogs) {
    AppDiagnostics.logSystemInfo();
  }
  
  runApp(
    DevicePreview(
      enabled: EnvConfig.enableDevicePreview,
      builder: (context) => const FitnessTrackerApp(),
    ),
  );
}

class FitnessTrackerApp extends StatelessWidget {
  const FitnessTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.sl<TargetsBloc>()..add(LoadTargets())),
        BlocProvider(create: (context) => di.sl<WorkoutBloc>()),
        BlocProvider(create: (context) => di.sl<HomeBloc>()..add(LoadHomeData())),
        BlocProvider(create: (context) => di.sl<ExerciseBloc>()..add(LoadExercises())),
        BlocProvider(create: (context) => di.sl<HistoryBloc>()),
        BlocProvider(create: (context) => di.sl<MealBloc>()..add(LoadMeals())),
        BlocProvider(create: (context) => di.sl<NutritionLogBloc>()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const BottomNavigation(),
        builder: DevicePreview.appBuilder,
      ),
    );
  }
}