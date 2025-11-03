import 'package:flutter/material.dart';
import '../datasources/local/database_helper.dart';
import 'performance_monitor.dart';

/// Manages app lifecycle events and performs appropriate actions
class AppLifecycleManager with WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  DateTime? _lastPauseTime;
  final List<VoidCallback> _resumeCallbacks = [];
  final List<VoidCallback> _pauseCallbacks = [];

  /// Initialize the lifecycle manager
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    debugPrint('✅ App lifecycle manager initialized');
  }

  /// Clean up resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resumeCallbacks.clear();
    _pauseCallbacks.clear();
  }

  /// Register a callback to be called when app resumes
  void addResumeCallback(VoidCallback callback) {
    _resumeCallbacks.add(callback);
  }

  /// Register a callback to be called when app pauses
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
        // App is hidden but still running
        break;
    }
  }

  void _handleAppResumed() {
    debugPrint('App resumed');
    
    // Calculate pause duration if available
    if (_lastPauseTime != null) {
      final pauseDuration = DateTime.now().difference(_lastPauseTime!);
      debugPrint('App was paused for: ${pauseDuration.inSeconds} seconds');
      _lastPauseTime = null;
    }
    
    // Execute resume callbacks
    for (final callback in _resumeCallbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint('Error in resume callback: $e');
      }
    }
    
    // Log memory usage after resume
    PerformanceMonitor.logMemoryUsage();
  }

  void _handleAppPaused() {
    debugPrint('App paused');
    _lastPauseTime = DateTime.now();
    
    // Execute pause callbacks
    for (final callback in _pauseCallbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint('Error in pause callback: $e');
      }
    }
    
    // Compact database when app is paused
    _compactDatabase();
  }

  void _handleAppInactive() {
    debugPrint('App inactive');
    // App is transitioning, don't perform heavy operations
  }

  void _handleAppDetached() {
    debugPrint('App detached');
    
    // Clean up resources
    _closeDatabase();
    
    // Clear performance metrics
    PerformanceMonitor.clearMetrics();
  }

  /// Compact database to optimize storage
  Future<void> _compactDatabase() async {
    try {
      debugPrint('Compacting database...');
      // Database compaction would go here
      // For SQLite, this might involve VACUUM command
      // Example: await database.execute('VACUUM');
    } catch (e) {
      debugPrint('Failed to compact database: $e');
    }
  }

  /// Close database connection
  Future<void> _closeDatabase() async {
    try {
      debugPrint('Closing database...');
      await DatabaseHelper().close();
    } catch (e) {
      debugPrint('Failed to close database: $e');
    }
  }

  /// Check if app has been idle for too long
  bool isSessionExpired({Duration maxIdleTime = const Duration(hours: 24)}) {
    if (_lastPauseTime == null) return false;
    
    final idleTime = DateTime.now().difference(_lastPauseTime!);
    return idleTime > maxIdleTime;
  }

  /// Handle low memory warning
  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    debugPrint('⚠️ Low memory warning!');
    
    // Clear caches and non-essential data
    PerformanceMonitor.clearMetrics();
    
    // Force garbage collection
    // Note: This is a suggestion to the system, not guaranteed
  }
}
