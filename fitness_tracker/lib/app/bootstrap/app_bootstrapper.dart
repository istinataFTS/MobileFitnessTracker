import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/env_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/app_lifecycle_manager.dart';
import '../../core/utils/performance_monitor.dart';
import '../../injection/injection_container.dart' as di;
import 'app_data_seeder.dart';
import 'app_debug_diagnostics_runner.dart';

class AppBootstrapper {
  static const String _startupTimerName = 'app_initialization';
  static const String _dependencyInitTimerName = 'dependency_initialization';
  static const String _supabaseInitTimerName = 'supabase_initialization';
  static const String _dataSeedTimerName = 'default_data_seed';
  static const String _diagnosticsTimerName = 'startup_diagnostics';
  static const String _systemUiTimerName = 'system_ui_configuration';

  const AppBootstrapper();

  Future<void> bootstrap() async {
    AppLogger.info('Bootstrap started', category: 'bootstrap');
    PerformanceMonitor.startTimer(_startupTimerName);

    try {
      _logRuntimeConfig();
      EnvConfig.ensureValidRuntimeConfig();

      _initializeLifecycle();
      await _initializeRemoteBackend();
      await _initializeDependencies();
      await _seedDefaultDataIfNeeded();
      await _runDiagnosticsIfNeeded();
      _configureSystemUi();

      final totalInitTimeMs = PerformanceMonitor.stopTimer(_startupTimerName);
      AppLogger.info(
        'Bootstrap finished in ${totalInitTimeMs}ms',
        category: 'bootstrap',
      );
      PerformanceMonitor.logSummary(
        _startupTimerName,
        category: 'bootstrap',
      );
    } catch (error, stackTrace) {
      final totalInitTimeMs = PerformanceMonitor.stopTimer(_startupTimerName);

      AppLogger.error(
        'Bootstrap failed after ${totalInitTimeMs}ms',
        category: 'bootstrap',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  void _logRuntimeConfig() {
    if (!kDebugMode) {
      return;
    }

    AppLogger.debug('Printing runtime configuration', category: 'bootstrap');
    EnvConfig.printConfig();
  }

  void _initializeLifecycle() {
    AppLogger.debug('Initializing app lifecycle manager', category: 'bootstrap');
    AppLifecycleManager().initialize();
  }

  Future<void> _initializeRemoteBackend() async {
    if (kIsWeb) {
      AppLogger.info(
        'Skipping remote backend initialization on web bootstrap path',
        category: 'bootstrap',
      );
      return;
    }

    if (!EnvConfig.isSupabaseConfigured) {
      AppLogger.info(
        'Supabase is disabled or not configured; continuing without remote backend',
        category: 'bootstrap',
      );
      return;
    }

    AppLogger.info('Initializing Supabase', category: 'bootstrap');

    await PerformanceMonitor.trackAsync<void>(
      _supabaseInitTimerName,
      () => Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
      ),
      slowThresholdMs: 300,
      category: 'bootstrap',
    );

    final summary = PerformanceMonitor.getSummary(_supabaseInitTimerName);
    if (summary != null) {
      AppLogger.info(
        'Supabase initialized in ${summary.latestMs}ms',
        category: 'bootstrap',
      );
    }
  }

  Future<void> _initializeDependencies() async {
    if (kIsWeb) {
      AppLogger.info(
        'Skipping dependency initialization for web-specific bootstrap path',
        category: 'bootstrap',
      );
      return;
    }

    AppLogger.info('Initializing dependencies', category: 'bootstrap');
    await PerformanceMonitor.trackAsync<void>(
      _dependencyInitTimerName,
      () => di.init(),
      slowThresholdMs: 300,
      category: 'bootstrap',
    );

    final summary = PerformanceMonitor.getSummary(_dependencyInitTimerName);
    if (summary != null) {
      AppLogger.info(
        'Dependencies initialized in ${summary.latestMs}ms',
        category: 'bootstrap',
      );
    }
  }

  Future<void> _seedDefaultDataIfNeeded() async {
    if (kIsWeb) {
      AppLogger.info(
        'Skipping default data seeding on web',
        category: 'bootstrap',
      );
      return;
    }

    AppLogger.debug(
      'Running default data seeding check',
      category: 'bootstrap',
    );

    await PerformanceMonitor.trackAsync<void>(
      _dataSeedTimerName,
      () => const AppDataSeeder().seedIfEnabled(),
      slowThresholdMs: 250,
      category: 'bootstrap',
    );

    final summary = PerformanceMonitor.getSummary(_dataSeedTimerName);
    if (summary != null) {
      AppLogger.info(
        'Default data seeding step completed in ${summary.latestMs}ms',
        category: 'bootstrap',
      );
    }
  }

  Future<void> _runDiagnosticsIfNeeded() async {
    if (kIsWeb) {
      AppLogger.info(
        'Skipping startup diagnostics on web',
        category: 'bootstrap',
      );
      return;
    }

    AppLogger.debug('Running startup diagnostics check', category: 'bootstrap');

    await PerformanceMonitor.trackAsync<void>(
      _diagnosticsTimerName,
      () => const AppDebugDiagnosticsRunner().runIfEnabled(),
      slowThresholdMs: 250,
      category: 'bootstrap',
    );

    final summary = PerformanceMonitor.getSummary(_diagnosticsTimerName);
    if (summary != null) {
      AppLogger.info(
        'Startup diagnostics step completed in ${summary.latestMs}ms',
        category: 'bootstrap',
      );
    }
  }

  void _configureSystemUi() {
    if (kIsWeb) {
      AppLogger.info(
        'Skipping system UI configuration on web',
        category: 'bootstrap',
      );
      return;
    }

    PerformanceMonitor.trackSync<void>(
      _systemUiTimerName,
      () {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        );
      },
      slowThresholdMs: 16,
      category: 'bootstrap',
    );

    final summary = PerformanceMonitor.getSummary(_systemUiTimerName);
    if (summary != null) {
      AppLogger.debug(
        'System UI configured in ${summary.latestMs}ms',
        category: 'bootstrap',
      );
    }
  }
}