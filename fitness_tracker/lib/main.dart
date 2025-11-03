import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/services.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/themes/app_theme.dart';
import 'core/utils/app_lifecycle_manager.dart';
import 'core/utils/performance_monitor.dart';
import 'core/utils/database_seeder.dart';
import 'config/env_config.dart';
import 'presentation/navigation/bottom_navigation.dart';
import 'injection/injection_container.dart' as di;
import 'presentation/pages/targets/bloc/targets_bloc.dart';
import 'presentation/pages/log_set/bloc/log_set_bloc.dart';
import 'presentation/pages/home/bloc/home_bloc.dart';
import 'presentation/pages/exercises/bloc/exercise_bloc.dart';
import 'domain/repositories/exercise_repository.dart';

void main() async {
  // Start initialization timer
  PerformanceMonitor.startTimer('app_initialization');
  
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app lifecycle manager
  AppLifecycleManager().initialize();
  
  // Initialize dependency injection (only for mobile - database doesn't work on web)
  if (!kIsWeb) {
    try {
      // Initialize DI container
      await di.init();
      debugPrint('✅ Dependency injection initialized');
      
      // Seed database with default exercises
      try {
        final seeder = DatabaseSeeder(di.sl<ExerciseRepository>());
        await seeder.seedDefaultExercises();
        debugPrint('✅ Database seeded with default exercises');
      } catch (e) {
        debugPrint('⚠️ Failed to seed database: $e');
        // Continue anyway - seeding is not critical
      }
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
        
        // Exercise BLoC (NEW!)
        BlocProvider(
          create: (_) => di.sl<ExerciseBloc>()..add(LoadExercisesEvent()),
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
        ? [NavigationObserver()] 
        : [],
      
      // Scroll behavior configuration
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
    );
  }
}

/// Custom navigation observer for debugging and performance tracking
class NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final from = previousRoute?.settings.name ?? 'root';
    final to = route.settings.name ?? 'unnamed';
    PerformanceMonitor.trackScreenTransition(from, to);
    debugPrint('📍 Navigation: $from → $to');
  }
  
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final from = route.settings.name ?? 'unnamed';
    final to = previousRoute?.settings.name ?? 'root';
    PerformanceMonitor.trackScreenTransition(from, to);
    debugPrint('📍 Navigation: $from ← $to');
  }
  
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final from = oldRoute?.settings.name ?? 'unknown';
    final to = newRoute?.settings.name ?? 'unknown';
    debugPrint('📍 Navigation replaced: $from → $to');
  }
  
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    debugPrint('📍 Route removed: ${route.settings.name ?? "unknown"}');
  }
}