import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../data/datasources/local/database_helper.dart';
import 'performance_monitor.dart';

/// Manages app lifecycle events and resources
class AppLifecycleManager with WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  bool _isInitialized = false;
  DateTime? _lastPauseTime;
  final List<VoidCallback> _resumeCallbacks = [];
  final List<VoidCallback> _pauseCallbacks = [];

  /// Initialize lifecycle management
  void initialize() {
    if (_isInitialized) return;
    
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    debugPrint('AppLifecycleManager initialized');
  }

  /// Clean up resources
  void dispose() {
    if (!_isInitialized) return;
    
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
    _resumeCallbacks.clear();
    _pauseCallbacks.clear();
  }

  /// Register callback for app resume
  void onResume(VoidCallback callback) {
    _resumeCallbacks.add(callback);
  }

  /// Register callback for app pause
  void onPause(VoidCallback callback) {
    _pauseCallbacks.add(callback);
  }

  /// Remove resume callback
  void removeResumeCallback(VoidCallback callback) {
    _resumeCallbacks.remove(callback);
  }

  /// Remove pause callback
  void removePauseCallback(VoidCallback callback) {
    _pauseCallbacks.remove(callback);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App lifecycle state: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state (newer Flutter versions)
        break;
    }
  }

  void _handleAppResumed() {
    debugPrint('App resumed');
    
    // Log resume time if app was paused
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
    
    // Compact database on mobile when app is paused
    if (!kIsWeb) {
      _compactDatabase();
    }
  }

  void _handleAppInactive() {
    debugPrint('App inactive');
    // App is transitioning, don't perform heavy operations
  }

  void _handleAppDetached() {
    debugPrint('App detached');
    
    // Clean up resources
    if (!kIsWeb) {
      _closeDatabase();
    }
    
    // Clear performance metrics
    PerformanceMonitor.clearMetrics();
  }

  /// Compact database to optimize storage
  Future<void> _compactDatabase() async {
    if (kIsWeb) return;
    
    try {
      debugPrint('Compacting database...');
      // Database compaction would go here
      // For SQLite, this might involve VACUUM command
    } catch (e) {
      debugPrint('Failed to compact database: $e');
    }
  }

  /// Close database connection
  Future<void> _closeDatabase() async {
    if (kIsWeb) return;
    
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