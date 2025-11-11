import 'package:flutter/material.dart';
import '../../data/datasources/local/database_helper.dart';
import 'performance_monitor.dart';

/// Manages app lifecycle events and performs appropriate actions
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
    
    _compactDatabase();
  }

  void _handleAppInactive() {
    debugPrint('App inactive');
  }

  void _handleAppDetached() {
    debugPrint('App detached');
    _closeDatabase();
    PerformanceMonitor.clearMetrics();
  }

  Future<void> _compactDatabase() async {
    try {
      debugPrint('Compacting database...');
    } catch (e) {
      debugPrint('Failed to compact database: $e');
    }
  }

  Future<void> _closeDatabase() async {
    try {
      debugPrint('Closing database...');
      await DatabaseHelper().close();
    } catch (e) {
      debugPrint('Failed to close database: $e');
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
    PerformanceMonitor.clearMetrics();
  }
}


