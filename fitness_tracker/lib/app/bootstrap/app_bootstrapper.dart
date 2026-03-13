import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../config/env_config.dart';
import '../../core/utils/app_lifecycle_manager.dart';
import '../../core/utils/performance_monitor.dart';
import '../../injection/injection_container.dart' as di;
import 'app_data_seeder.dart';
import 'app_debug_diagnostics_runner.dart';

class AppBootstrapper {
  const AppBootstrapper();

  Future<void> bootstrap() async {
    PerformanceMonitor.startTimer(_startupTimerName);

    try {
      _logRuntimeConfig();
      EnvConfig.ensureValidRuntimeConfig();

      _initializeLifecycle();
      await _initializeDependencies();
      await _seedDefaultDataIfNeeded();
      await _runDiagnosticsIfNeeded();
      _configureSystemUi();
    } catch (error, stackTrace) {
      debugPrint('❌ App bootstrap failed: $error');
      debugPrint('$stackTrace');
      rethrow;
    } finally {
      final totalInitTime = PerformanceMonitor.stopTimer(_startupTimerName);
      debugPrint('🚀 App initialization complete in: ${totalInitTime}ms');
    }
  }

  static const String _startupTimerName = 'app_initialization';

  void _logRuntimeConfig() {
    if (kDebugMode) {
      EnvConfig.printConfig();
    }
  }

  void _initializeLifecycle() {
    AppLifecycleManager().initialize();
  }

  Future<void> _initializeDependencies() async {
    if (kIsWeb) {
      return;
    }

    debugPrint('Initializing dependencies...');
    final initStart = DateTime.now();

    await di.init();

    final initDuration = DateTime.now().difference(initStart);
    debugPrint(
      '✅ Dependencies initialized in: ${initDuration.inMilliseconds}ms',
    );
  }

  Future<void> _seedDefaultDataIfNeeded() async {
    if (kIsWeb) {
      return;
    }

    await const AppDataSeeder().seedIfEnabled();
  }

  Future<void> _runDiagnosticsIfNeeded() async {
    if (kIsWeb) {
      return;
    }

    await const AppDebugDiagnosticsRunner().runIfEnabled();
  }

  void _configureSystemUi() {
    if (kIsWeb) {
      return;
    }

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
}