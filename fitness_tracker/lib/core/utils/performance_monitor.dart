import 'package:flutter/foundation.dart';

/// Monitor app performance and log issues
class PerformanceMonitor {
  PerformanceMonitor._();
  
  static final Map<String, DateTime> _timers = {};
  static final Map<String, List<Duration>> _metrics = {};
  
  /// Start timing an operation
  static void startTimer(String operation) {
    _timers[operation] = DateTime.now();
  }
  
  /// End timing and record the duration
  static Duration? endTimer(String operation) {
    final startTime = _timers[operation];
    if (startTime == null) return null;
    
    final duration = DateTime.now().difference(startTime);
    _timers.remove(operation);
    
    // Store metrics
    _metrics[operation] ??= [];
    _metrics[operation]!.add(duration);
    
    // Keep only last 100 metrics per operation
    if (_metrics[operation]!.length > 100) {
      _metrics[operation]!.removeAt(0);
    }
    
    // Log slow operations in debug mode
    if (kDebugMode && duration.inMilliseconds > 500) {
      debugPrint('⚠️ Slow operation: $operation took ${duration.inMilliseconds}ms');
    }
    
    return duration;
  }
  

  static int stopTimer(String operation) {
    final duration = endTimer(operation);
    return duration?.inMilliseconds ?? 0;
  }
  
  /// Get average duration for an operation
  static Duration? getAverageDuration(String operation) {
    final metrics = _metrics[operation];
    if (metrics == null || metrics.isEmpty) return null;
    
    final totalMs = metrics.fold<int>(
      0, 
      (sum, duration) => sum + duration.inMilliseconds,
    );
    
    return Duration(milliseconds: totalMs ~/ metrics.length);
  }
  
  /// Log memory usage
  static void logMemoryUsage() {
    if (!kDebugMode) return;
    
    // This is a placeholder - in production, integrate with proper monitoring
    debugPrint('Memory monitoring active');
  }
  
  /// Track screen transitions
  static void trackScreenTransition(String from, String to) {
    if (!kDebugMode) return;
    
    debugPrint('Navigation: $from → $to');
  }
  
  /// Track database operations
  static Future<T> trackDatabaseOperation<T>(
    String operation,
    Future<T> Function() callback,
  ) async {
    startTimer('db_$operation');
    try {
      final result = await callback();
      final duration = endTimer('db_$operation');
      
      if (kDebugMode && duration != null && duration.inMilliseconds > 100) {
        debugPrint('DB operation "$operation" took ${duration.inMilliseconds}ms');
      }
      
      return result;
    } catch (e) {
      endTimer('db_$operation');
      if (kDebugMode) {
        debugPrint('DB operation "$operation" failed: $e');
      }
      rethrow;
    }
  }
  
  /// Clear all metrics
  static void clearMetrics() {
    _timers.clear();
    _metrics.clear();
  }
  
  /// Get performance report
  static Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};
    
    for (final entry in _metrics.entries) {
      final operation = entry.key;
      final durations = entry.value;
      
      if (durations.isEmpty) continue;
      
      final totalMs = durations.fold<int>(
        0, 
        (sum, d) => sum + d.inMilliseconds,
      );
      
      final maxMs = durations.map((d) => d.inMilliseconds).reduce(
        (max, d) => d > max ? d : max,
      );
      
      final minMs = durations.map((d) => d.inMilliseconds).reduce(
        (min, d) => d < min ? d : min,
      );
      
      report[operation] = {
        'count': durations.length,
        'avgMs': totalMs ~/ durations.length,
        'maxMs': maxMs,
        'minMs': minMs,
      };
    }
    
    return report;
  }
}