import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/services.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/themes/app_theme.dart';
import 'core/utils/app_lifecycle_manager.dart';
import 'core/utils/performance_monitor.dart';
import 'config/env_config.dart';
import 'presentation/navigation/bottom_navigation.dart';
import 'injection/injection_container.dart' as di;
import 'presentation/pages/targets/bloc/targets_bloc.dart';
import 'presentation/pages/log_set/bloc/log_set_bloc.dart';
import 'presentation/pages/home/bloc/home_bloc.dart';

void main() async {
  // Start initialization timer
  PerformanceMonitor.startTimer('app_initialization');
  
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app lifecycle manager
  AppLifecycleManager().initialize();
  
  // Initialize dependency injection (only for mobile - database doesn't work on web)
  if (!kIsWeb) {
    try {
      await di.init();
      debugPrint('✅ Dependency injection initialized');
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
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.surfaceDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // End initialization timer
  final initDuration = PerformanceMonitor.endTimer('app_initialization');
  if (initDuration != null) {
    debugPrint('App initialization took: ${initDuration.inMilliseconds}ms');
  }
  
  // Error handling for Flutter framework
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // In debug mode, show the error
      FlutterError.presentError(details);
    } else {
      // In release mode, log to crash reporting service
      debugPrint('Flutter error: ${details.exception}');
    }
  };
  
  // Error handling for async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async error: $error');
    // In production, send to crash reporting service
    return true;
  };
  
  // Run app with error boundary
  runApp(
    DevicePreview(
      enabled: kDebugMode && EnvConfig.enableDevicePreview,
      builder: (context) => const FitnessTrackerApp(),
    ),
  );
}

class FitnessTrackerApp extends StatelessWidget {
  const FitnessTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Track app startup
    PerformanceMonitor.startTimer('first_frame');
    
    // On web: Use in-memory managers (TargetsManager, WorkoutSetsManager)
    // On mobile: Use BLoC with database
    if (kIsWeb) {
      return _buildWebApp(context);
    }

    // Mobile: Use BLoC providers with database
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<TargetsBloc>()..add(LoadTargetsEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<LogSetBloc>()..add(LoadLogSetDataEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<HomeBloc>()..add(LoadHomeDataEvent()),
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
      
      // Navigation observer for tracking
      navigatorObservers: kDebugMode 
        ? [NavigationObserver()] 
        : [],
    );
  }
}

/// Custom navigation observer for debugging
class NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final from = previousRoute?.settings.name ?? 'root';
    final to = route.settings.name ?? 'unnamed';
    PerformanceMonitor.trackScreenTransition(from, to);
  }
  
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final from = route.settings.name ?? 'unnamed';
    final to = previousRoute?.settings.name ?? 'root';
    PerformanceMonitor.trackScreenTransition(from, to);
  }
}