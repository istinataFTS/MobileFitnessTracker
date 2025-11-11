import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/services.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/env_config.dart'; 
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
        debugPrint('Seeding database with default data...');
        final seedStart = DateTime.now();
        
        try {
          final seedExercises = di.sl<SeedExercises>();
          final result = await seedExercises();
          
          result.fold(
            (failure) {
              debugPrint('❌ Seeding failed: ${failure.message}');
            },
            (count) {
              if (count > 0) {
                final seedDuration = DateTime.now().difference(seedStart);
                debugPrint('✅ Seeded $count exercises in ${seedDuration.inMilliseconds}ms');
              } else {
                debugPrint('ℹ️  No seeding performed (data already exists)');
              }
            },
          );
        } catch (e) {
          debugPrint('❌ Unexpected error during seeding: $e');
        }
      } else {
        debugPrint('ℹ️  Database seeding disabled in environment config');
      }
      
      if (kDebugMode) {
        debugPrint('\n');
        debugPrint('═══════════════════════════════════════');
        debugPrint('🔍 RUNNING APP DIAGNOSTICS');
        debugPrint('═══════════════════════════════════════');
        
        await AppDiagnostics.fullReport();
        
        debugPrint('═══════════════════════════════════════');
        debugPrint('✅ DIAGNOSTICS COMPLETE');
        debugPrint('═══════════════════════════════════════\n');
      }
      
    } catch (e) {
      debugPrint('❌ Failed to initialize DI: $e');
    }
  }
  
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
      ],
      child: _buildMaterialApp(context),
    );
  }

  Widget _buildMaterialApp(BuildContext context) {
    return MaterialApp(
      title: EnvConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      home: const BottomNavigation(),
    );
  }

  Widget _buildWebApp(BuildContext context) {
    return MaterialApp(
      title: EnvConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_android,
                  size: 64,
                  color: AppTheme.primaryOrange,
                ),
                SizedBox(height: 24),
                Text(
                  'Mobile Only App',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'This fitness tracker is designed for mobile devices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Please install the app on your Android or iOS device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}