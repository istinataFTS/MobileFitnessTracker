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
import 'presentation/navigation/bottom_navigation.dart';
import 'injection/injection_container.dart' as di;
import 'presentation/pages/targets/bloc/targets_bloc.dart';
import 'presentation/pages/log_set/bloc/log_set_bloc.dart';
import 'presentation/pages/home/bloc/home_bloc.dart';
import 'presentation/pages/exercises/bloc/exercise_bloc.dart';
import 'presentation/pages/history/bloc/history_bloc.dart';
import 'domain/usecases/exercises/seed_exercises.dart'; 

void main() async {
  // Start initialization timer
  PerformanceMonitor.startTimer('app_initialization');
  
  WidgetsFlutterBinding.ensureInitialized();
  
  // 
  if (kDebugMode) {
    EnvConfig.printConfig();
  }
  
  EnvConfig.validateProductionConfig();
  
  // Initialize app lifecycle manager
  AppLifecycleManager().initialize();
  
  // Initialize dependency injection (only for mobile - database doesn't work on web)
  if (!kIsWeb) {
    try {
      // Initialize DI container
      debugPrint('Initializing dependencies...');
      final initStart = DateTime.now();
      await di.init();
      final initDuration = DateTime.now().difference(initStart);
      debugPrint('✅ Dependencies initialized in: ${initDuration.inMilliseconds}ms');
      
      // ==================== ⭐ NEW: DATABASE SEEDING ====================
      // Seed default exercises if configured to do so
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
          // Don't prevent app from starting if seeding fails
        }
      } else {
        debugPrint('ℹ️  Database seeding disabled in environment config');
      }
      // ================================================================
      
    } catch (e) {
      debugPrint('❌ Failed to initialize DI: $e');
      // Continue anyway for web or if database fails
    }
  }
  
  // Set preferred orientations (mobile only)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // End initialization timer
  final initDuration = PerformanceMonitor.endTimer('app_initialization');
  if (initDuration != null) {
    debugPrint('App initialization completed in: ${initDuration.inMilliseconds}ms');
  }
  
  // Start first frame timer
  PerformanceMonitor.startTimer('first_frame');
  
  // Run app with or without device preview based on debug mode
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
    // Web: Simple MaterialApp without BLoC providers (uses in-memory managers)
    if (kIsWeb) {
      return _buildWebApp(context);
    }

    // Mobile: Use BLoC providers with database
    return MultiBlocProvider(
      providers: [
        // Targets BLoC
        BlocProvider(
          create: (_) => di.sl<TargetsBloc>()..add(LoadTargetsEvent()),
        ),
        
        // Log Set BLoC
        BlocProvider(
          create: (_) => di.sl<LogSetBloc>()..add(LoadLogSetDataEvent()),
        ),
        
        // Home BLoC
        BlocProvider(
          create: (_) => di.sl<HomeBloc>()..add(LoadHomeDataEvent()),
        ),
        
        // Exercise BLoC
        BlocProvider(
          create: (_) => di.sl<ExerciseBloc>()..add(LoadExercisesEvent()),
        ),
        
        // History BLoC
        BlocProvider(
          create: (_) => di.sl<HistoryBloc>()..add(LoadAllSetsEvent()),
        ),
      ],
      child: _buildMobileApp(context),
    );
  }

  Widget _buildWebApp(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: EnvConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const BottomNavigation(),
      onGenerateTitle: (context) => EnvConfig.appName,
    );
  }

  Widget _buildMobileApp(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: (context, child) {
        // Track first frame rendered
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final duration = PerformanceMonitor.endTimer('first_frame');
          if (duration != null) {
            debugPrint('First frame rendered in: ${duration.inMilliseconds}ms');
          }
        });
        
        // Wrap with DevicePreview if enabled
        if (DevicePreview.isEnabled(context)) {
          return DevicePreview.appBuilder(context, child);
        }
        return child!;
      },
      title: EnvConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const BottomNavigation(),
      onGenerateTitle: (context) => EnvConfig.appName,
      
      // Navigation observer for tracking (debug mode only)
      navigatorObservers: kDebugMode 
        ? [_NavigationObserver()]
        : [],
    );
  }
}

/// Custom navigation observer for performance tracking
class _NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null && previousRoute?.settings.name != null) {
      PerformanceMonitor.trackScreenTransition(
        previousRoute!.settings.name!,
        route.settings.name!,
      );
    }
  }
}