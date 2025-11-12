import 'package:flutter/material.dart';
import '../../data/datasources/local/database_helper.dart';
import 'performance_monitor.dart';

/// Manages app lifecycle events and performs appropriate actions
/// 
/// CRITICAL FIX: Database must NOT be closed during pause/inactive states
/// as it causes DatabaseException(error database_closed) when app resumes.
/// SQLite databases should remain open throughout the app lifecycle.
class AppLifecycleManager with WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  DateTime? _lastPauseTime;
  final List<VoidCallback> _resumeCallbacks = [];
  final List<VoidCallback> _pauseCallbacks = [];

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    debugPrint('✅ App lifecycle manager initialized');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resumeCallbacks.clear();
    _pauseCallbacks.clear();
  }

  void addResumeCallback(VoidCallback callback) {
    _resumeCallbacks.add(callback);
  }

  void addPauseCallback(VoidCallback callback) {
    _pauseCallbacks.add(callback);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _handleAppResumed() {
    debugPrint('App resumed');
    
    if (_lastPauseTime != null) {
      final pauseDuration = DateTime.now().difference(_lastPauseTime!);
      debugPrint('App was paused for: ${pauseDuration.inSeconds} seconds');
      _lastPauseTime = null;
    }
    
    // Ensure database connection is ready after resume
    _ensureDatabaseOpen();
    
    for (final callback in _resumeCallbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint('Error in resume callback: $e');
      }
    }
    
    PerformanceMonitor.logMemoryUsage();
  }

  void _handleAppPaused() {
    debugPrint('App paused');
    _lastPauseTime = DateTime.now();
    
    for (final callback in _pauseCallbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint('Error in pause callback: $e');
      }
    }
    
    // CRITICAL: Do NOT close database on pause
    // Closing the database causes DatabaseException(error database_closed) when app resumes
    // SQLite connections should remain open for the app lifetime
    // The OS will handle cleanup when the app is terminated
  }

  void _handleAppInactive() {
    debugPrint('App inactive');
    // No database operations needed during inactive state
  }

  void _handleAppDetached() {
    debugPrint('App detached');
    // Clean up performance metrics but do NOT close database
    // Database closing during detach can cause issues if pages try to save state
    PerformanceMonitor.clearMetrics();
  }

  /// Ensures database is open and ready for use after app resume
  /// 
  /// This method verifies the database connection is active.
  /// DatabaseHelper singleton will automatically reinitialize if needed.
  Future<void> _ensureDatabaseOpen() async {
    try {
      // Access database to trigger initialization if needed
      // This is a no-op if database is already open
      await DatabaseHelper().database;
      debugPrint('✅ Database connection verified');
    } catch (e) {
      debugPrint('❌ Failed to verify database connection: $e');
      // Don't rethrow - allow app to continue and handle errors at usage point
    }
  }

  bool isSessionExpired({Duration maxIdleTime = const Duration(hours: 24)}) {
    if (_lastPauseTime == null) return false;
    
    final idleTime = DateTime.now().difference(_lastPauseTime!);
    return idleTime > maxIdleTime;
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    debugPrint('⚠️ Low memory warning!');
    // Clear performance metrics but NOT database connection
    PerformanceMonitor.clearMetrics();
  }
}
