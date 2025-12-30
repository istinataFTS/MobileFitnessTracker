import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Enhanced performance monitoring with detailed metrics
class EnhancedPerformanceMonitor {
  EnhancedPerformanceMonitor._();

  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<int>> _metricHistory = {};
  static final Queue<PerformanceEvent> _eventLog = Queue();
  
  static const int _maxHistorySize = 100;
  static const int _maxEventLogSize = 500;

  /// Start a named timer
  static void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
  }

  /// Stop a timer and return elapsed time in milliseconds
  static int stopTimer(String name) {
    final timer = _timers[name];
    if (timer == null) {
      debugPrint('⚠️ Timer not found: $name');
      return 0;
    }

    timer.stop();
    final elapsed = timer.elapsedMilliseconds;
    
    // Store in history
    _addToHistory(name, elapsed);
    
    // Log event
    _logEvent(PerformanceEvent(
      name: name,
      duration: elapsed,
      timestamp: DateTime.now(),
      type: PerformanceEventType.timer,
    ));
    
    _timers.remove(name);
    return elapsed;
  }

  /// Record a metric value
  static void recordMetric(String name, int value) {
    _addToHistory(name, value);
    
    _logEvent(PerformanceEvent(
      name: name,
      value: value,
      timestamp: DateTime.now(),
      type: PerformanceEventType.metric,
    ));
  }

  /// Get average value for a metric
  static double getAverage(String name) {
    final history = _metricHistory[name];
    if (history == null || history.isEmpty) return 0.0;
    
    final sum = history.reduce((a, b) => a + b);
    return sum / history.length;
  }

  /// Get min/max/avg stats for a metric
  static MetricStats getStats(String name) {
    final history = _metricHistory[name];
    if (history == null || history.isEmpty) {
      return MetricStats(min: 0, max: 0, average: 0.0, count: 0);
    }
    
    return MetricStats(
      min: history.reduce((a, b) => a < b ? a : b),
      max: history.reduce((a, b) => a > b ? a : b),
      average: getAverage(name),
      count: history.length,
    );
  }

  /// Profile a function and record execution time
  static Future<T> profile<T>(
    String name,
    Future<T> Function() fn, {
    int slowThreshold = 100,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      return await fn();
    } finally {
      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;
      
      recordMetric(name, elapsed);
      
      if (elapsed > slowThreshold) {
        debugPrint('⚠️ Slow operation: $name took ${elapsed}ms');
      }
    }
  }

  /// Profile a synchronous function
  static T profileSync<T>(
    String name,
    T Function() fn, {
    int slowThreshold = 16,
  }) {
    final stopwatch = Stopwatch()..start();
    
    try {
      return fn();
    } finally {
      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;
      
      recordMetric(name, elapsed);
      
      if (elapsed > slowThreshold) {
        debugPrint('⚠️ Slow sync operation: $name took ${elapsed}ms');
      }
    }
  }

  /// Log memory usage
  static void logMemoryUsage() {
    // Note: Actual memory tracking requires platform channels
    // This is a placeholder for the pattern
    debugPrint('📊 Memory monitoring (requires platform implementation)');
  }

  /// Get recent performance events
  static List<PerformanceEvent> getRecentEvents({int limit = 50}) {
    return _eventLog.take(limit).toList();
  }

  /// Print performance summary
  static void printSummary() {
    debugPrint('📊 Performance Summary:');
    debugPrint('─' * 60);
    
    _metricHistory.forEach((name, history) {
      final stats = getStats(name);
      debugPrint(
        '  $name: avg=${stats.average.toStringAsFixed(1)}ms, '
        'min=${stats.min}ms, max=${stats.max}ms, count=${stats.count}',
      );
    });
    
    debugPrint('─' * 60);
  }

  /// Export metrics as JSON
  static Map<String, dynamic> exportMetrics() {
    return {
      'metrics': _metricHistory.map((name, history) {
        final stats = getStats(name);
        return MapEntry(name, {
          'min': stats.min,
          'max': stats.max,
          'average': stats.average,
          'count': stats.count,
          'history': history,
        });
      }),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Clear all metrics
  static void clearMetrics() {
    _timers.clear();
    _metricHistory.clear();
    _eventLog.clear();
  }

  /// Check if any timers are still running (memory leak detection)
  static void checkForLeaks() {
    if (_timers.isNotEmpty) {
      debugPrint('⚠️ Memory leak: ${_timers.length} timers still running:');
      _timers.keys.forEach((name) {
        debugPrint('  - $name');
      });
    }
  }

  // Internal helpers

  static void _addToHistory(String name, int value) {
    _metricHistory.putIfAbsent(name, () => []);
    _metricHistory[name]!.add(value);
    
    // Keep history size manageable
    if (_metricHistory[name]!.length > _maxHistorySize) {
      _metricHistory[name]!.removeAt(0);
    }
  }

  static void _logEvent(PerformanceEvent event) {
    _eventLog.addFirst(event);
    
    // Keep log size manageable
    if (_eventLog.length > _maxEventLogSize) {
      _eventLog.removeLast();
    }
  }
}

/// Performance metric statistics
class MetricStats {
  final int min;
  final int max;
  final double average;
  final int count;

  const MetricStats({
    required this.min,
    required this.max,
    required this.average,
    required this.count,
  });

  @override
  String toString() {
    return 'MetricStats(min: $min, max: $max, avg: ${average.toStringAsFixed(1)}, count: $count)';
  }
}

/// Performance event types
enum PerformanceEventType {
  timer,
  metric,
  memory,
  network,
  build,
  query,
}

/// Performance event record
class PerformanceEvent {
  final String name;
  final DateTime timestamp;
  final PerformanceEventType type;
  final int? duration;
  final int? value;
  final String? details;

  const PerformanceEvent({
    required this.name,
    required this.timestamp,
    required this.type,
    this.duration,
    this.value,
    this.details,
  });

  @override
  String toString() {
    final valueStr = duration != null ? '${duration}ms' : value?.toString() ?? '';
    return '[$type] $name: $valueStr @ ${timestamp.toIso8601String()}';
  }
}

/// Frame rate monitor (simplified)
class FrameRateMonitor {
  static DateTime? _lastFrameTime;
  static final List<int> _frameTimes = [];
  static const int _maxFrames = 60;

  static void recordFrame() {
    final now = DateTime.now();
    
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!).inMilliseconds;
      _frameTimes.add(frameTime);
      
      if (_frameTimes.length > _maxFrames) {
        _frameTimes.removeAt(0);
      }
    }
    
    _lastFrameTime = now;
  }

  static double getAverageFrameTime() {
    if (_frameTimes.isEmpty) return 0.0;
    
    final sum = _frameTimes.reduce((a, b) => a + b);
    return sum / _frameTimes.length;
  }

  static double getEstimatedFPS() {
    final avgFrameTime = getAverageFrameTime();
    if (avgFrameTime == 0) return 0.0;
    
    return 1000.0 / avgFrameTime;
  }

  static void reset() {
    _lastFrameTime = null;
    _frameTimes.clear();
  }
}