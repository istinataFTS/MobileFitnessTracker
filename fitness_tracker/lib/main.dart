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
import 'presentation/pages/log_set/bloc/log_set_bloc.dart';
import 'presentation/pages/home/bloc/home_bloc.dart';
import 'presentation/pages/exercises/bloc/exercise_bloc.dart';
import 'presentation/pages/history/bloc/history_bloc.dart';
import 'presentation/pages/meals/bloc/meal_bloc.dart';
import 'presentation/pages/nutrition_log/bloc/nutrition_log_bloc.dart';
import 'domain/usecases/exercises/seed_exercises.dart';

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
        
        final seedExercises = di.sl<SeedExercises>();
        final result = await seedExercises();
        
        result.fold(
          (failure) => debugPrint('❌ Seeding failed: ${failure.message}'),
          (count) {
            final seedDuration = DateTime.now().difference(seedStart);
            debugPrint('✅ Seeded $count exercises in: ${seedDuration.inMilliseconds}ms');
          },
        );
      }
      
      if (kDebugMode) {
        await AppDiagnostics.runDiagnostics();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  final initDuration = PerformanceMonitor.endTimer('app_initialization');
  if (initDuration != null) {
    debugPrint('App initialization completed in: ${initDuration.inMilliseconds}ms');
  }
  
  PerformanceMonitor.startTimer('first_frame');
  
  runApp(
    DevicePreview(
      enabled: kDebugMode && !kIsWeb,
      builder: (context) => const FitnessTrackerApp(),
    ),
  );
}

class FitnessTrackerApp extends StatelessWidget {
  const FitnessTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebApp(context);
    }

    // ⭐ UPDATED: Added MealBloc and NutritionLogBloc providers
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<TargetsBloc>()..add(LoadTargetsEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<LogSetBloc>(),
        ),
        BlocProvider(
          create: (_) => di.sl<HomeBloc>()..add(LoadHomeDataEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<ExerciseBloc>()..add(LoadExercisesEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<HistoryBloc>()..add(LoadAllSetsEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<MealBloc>()..add(LoadMealsEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<NutritionLogBloc>(),
        ),
      ],
      child: _buildMaterialApp(context),
    );
  }

  Widget _buildMaterialApp(BuildContext context) {
    return MaterialApp(
      title: EnvConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      home: const BottomNavigation(),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
    );
  }

  /// Web build without database dependencies
  Widget _buildWebApp(BuildContext context) {
    return MaterialApp(
      title: EnvConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.web_outlined,
                size: 64,
                color: AppTheme.primaryOrange,
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Web version coming soon!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textMedium,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please use the mobile app for now.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textDim,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}