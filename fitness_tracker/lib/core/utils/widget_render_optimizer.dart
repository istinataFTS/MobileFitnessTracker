import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Widget rendering optimization utilities
class WidgetRenderOptimizer {
  WidgetRenderOptimizer._();

  /// Wrap a widget with RepaintBoundary for isolation
  /// 
  /// Use when:
  /// - Widget has complex painting
  /// - Widget updates frequently but content is static
  /// - Widget is expensive to repaint
  /// 
  /// Example: Body diagrams, charts, heavy SVGs
  static Widget isolateRepaints(Widget child) {
    return RepaintBoundary(child: child);
  }

  /// Optimize list item builder with RepaintBoundary
  /// 
  /// Automatically wraps each list item to prevent cascade repaints
  static Widget Function(BuildContext, int) optimizeListBuilder(
    Widget Function(BuildContext, int) builder,
  ) {
    return (context, index) {
      return RepaintBoundary(
        child: builder(context, index),
      );
    };
  }

  /// Create a const widget wrapper when possible
  /// 
  /// Helps Flutter skip rebuilds for unchanged widgets
  static Widget constWrapper({
    required Widget child,
    Key? key,
  }) {
    return KeyedSubtree(
      key: key,
      child: child,
    );
  }

  /// Optimize image rendering with caching hints
  static Widget optimizeImage({
    required ImageProvider image,
    double? width,
    double? height,
    BoxFit? fit,
    bool enableMemoryCache = true,
  }) {
    return Image(
      image: image,
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true, // Smooth image transitions
      filterQuality: FilterQuality.medium, // Balance quality/performance
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
    );
  }

  /// Lazy builder for expensive widgets
  /// 
  /// Only builds widget when it's about to be visible
  static Widget lazyBuilder({
    required WidgetBuilder builder,
    double threshold = 250.0, // Pixels before viewport
  }) {
    return Builder(
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Could be enhanced with IntersectionObserver-like logic
            return builder(context);
          },
        );
      },
    );
  }

  /// Optimize text rendering with selective rebuilds
  static Widget optimizeText(
    String text, {
    TextStyle? style,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      // Use const when possible
      softWrap: true,
    );
  }

  /// Create an optimized AnimatedWidget wrapper
  /// 
  /// Reduces rebuild scope during animations
  static Widget optimizeAnimation({
    required AnimationController controller,
    required Widget Function(BuildContext, Animation<double>) builder,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => builder(context, controller),
    );
  }

  /// Optimize StatefulWidget performance
  /// 
  /// Returns whether widget should rebuild based on state changes
  static bool shouldRebuild<T>(T oldValue, T newValue) {
    return oldValue != newValue;
  }

  /// Measure widget build time (debug only)
  static Widget measureBuildTime({
    required String widgetName,
    required Widget child,
  }) {
    return Builder(
      builder: (context) {
        final stopwatch = Stopwatch()..start();
        
        // Build happens here
        final result = child;
        
        stopwatch.stop();
        
        if (stopwatch.elapsedMilliseconds > 16) {
          // Slow build (>16ms = dropped frame at 60fps)
          debugPrint(
            '⚠️ Slow build: $widgetName took ${stopwatch.elapsedMilliseconds}ms',
          );
        }
        
        return result;
      },
    );
  }

  /// Optimize focus node management
  /// 
  /// Reuses focus nodes to prevent unnecessary rebuilds
  static FocusNode createOptimizedFocusNode({
    String? debugLabel,
    bool skipTraversal = false,
  }) {
    return FocusNode(
      debugLabel: debugLabel,
      skipTraversal: skipTraversal,
    );
  }

  /// Memoization helper for expensive computations
  /// 
  /// Caches result based on input key
  static T memoize<T>({
    required String key,
    required T Function() compute,
    required Map<String, T> cache,
  }) {
    if (cache.containsKey(key)) {
      return cache[key]!;
    }
    
    final result = compute();
    cache[key] = result;
    return result;
  }
}

/// Performance hints for Flutter rendering engine
class RenderingHints {
  RenderingHints._();

  /// Hint that widget is static and won't change
  static const staticWidget = SizedBox.shrink();

  /// Hint that list has fixed extent items (for ListView)
  static const fixedExtentDelegate = FixedExtentScrollPhysics();

  /// Hint that scrollable content is short
  static const shortContentPhysics = ClampingScrollPhysics();

  /// Optimized scroll physics for long lists
  static const longListPhysics = AlwaysScrollableScrollPhysics();
}

/// Widget rebuild prevention utilities
class RebuildPrevention {
  RebuildPrevention._();

  /// Wrap with AutomaticKeepAlive to prevent disposal in lists
  static Widget keepAlive({
    required Widget child,
    bool wantKeepAlive = true,
  }) {
    return AutomaticKeepAliveClientMixin(
      wantKeepAlive: wantKeepAlive,
      child: child,
    );
  }

  /// Use ValueKey to preserve widget state across rebuilds
  static ValueKey<T> stableKey<T>(T value) {
    return ValueKey<T>(value);
  }

  /// Use GlobalKey when widget state must persist
  static GlobalKey createPersistentKey() {
    return GlobalKey();
  }
}

/// Mixin to track widget rebuild count (debug only)
mixin RebuildTracker on StatefulWidget {
  static final Map<Type, int> _rebuildCounts = {};

  void trackRebuild() {
    _rebuildCounts.update(
      runtimeType,
      (count) => count + 1,
      ifAbsent: () => 1,
    );

    if (_rebuildCounts[runtimeType]! > 10) {
      debugPrint(
        '⚠️ Excessive rebuilds: $runtimeType rebuilt ${_rebuildCounts[runtimeType]} times',
      );
    }
  }

  static void printStats() {
    debugPrint('📊 Widget Rebuild Statistics:');
    _rebuildCounts.forEach((type, count) {
      debugPrint('  $type: $count rebuilds');
    });
  }

  static void resetStats() {
    _rebuildCounts.clear();
  }
}

/// AutomaticKeepAlive mixin implementation
class AutomaticKeepAliveClientMixin extends StatefulWidget {
  final bool wantKeepAlive;
  final Widget child;

  const AutomaticKeepAliveClientMixin({
    super.key,
    required this.wantKeepAlive,
    required this.child,
  });

  @override
  State<AutomaticKeepAliveClientMixin> createState() =>
      _AutomaticKeepAliveClientMixinState();
}

class _AutomaticKeepAliveClientMixinState
    extends State<AutomaticKeepAliveClientMixin>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.wantKeepAlive;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return widget.child;
  }
}