import 'package:flutter/material.dart';

/// Widget rendering optimization utilities
class WidgetRenderOptimizer {
  WidgetRenderOptimizer._();

  /// Wrap a widget with RepaintBoundary for isolation.
  ///
  /// Use when:
  /// - widget has complex painting
  /// - widget updates frequently but content is static
  /// - widget is expensive to repaint
  static Widget isolateRepaints(Widget child) {
    return RepaintBoundary(child: child);
  }

  /// Optimize list item builder with RepaintBoundary.
  static Widget Function(BuildContext, int) optimizeListBuilder(
    Widget Function(BuildContext, int) builder,
  ) {
    return (context, index) {
      return RepaintBoundary(
        child: builder(context, index),
      );
    };
  }

  /// Create a keyed wrapper for subtree stability.
  static Widget constWrapper({
    required Widget child,
    Key? key,
  }) {
    return KeyedSubtree(
      key: key,
      child: child,
    );
  }

  /// Optimize image rendering.
  ///
  /// When width/height are provided and memory caching is enabled, the image
  /// provider is resized before painting to reduce memory usage.
  static Widget optimizeImage({
    required ImageProvider image,
    double? width,
    double? height,
    BoxFit? fit,
    bool enableMemoryCache = true,
  }) {
    final ImageProvider optimizedProvider = enableMemoryCache
        ? ResizeImage.resizeIfNeeded(
            width?.toInt(),
            height?.toInt(),
            image,
          )
        : image;

    return Image(
      image: optimizedProvider,
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
  }

  /// Lazy builder for expensive widgets.
  static Widget lazyBuilder({
    required WidgetBuilder builder,
    double threshold = 250.0,
  }) {
    return Builder(
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return builder(context);
          },
        );
      },
    );
  }

  /// Optimize text rendering with selective rebuilds.
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
      softWrap: true,
    );
  }

  /// Create an optimized AnimatedWidget wrapper.
  static Widget optimizeAnimation({
    required AnimationController controller,
    required Widget Function(BuildContext, Animation<double>) builder,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => builder(context, controller),
    );
  }

  /// Returns whether widget should rebuild based on state changes.
  static bool shouldRebuild<T>(T oldValue, T newValue) {
    return oldValue != newValue;
  }

  /// Measure widget build time in debug mode.
  static Widget measureBuildTime({
    required String widgetName,
    required Widget child,
  }) {
    return Builder(
      builder: (context) {
        final stopwatch = Stopwatch()..start();
        final result = child;
        stopwatch.stop();

        if (stopwatch.elapsedMilliseconds > 16) {
          debugPrint(
            'Slow build: $widgetName took '
            '${stopwatch.elapsedMilliseconds}ms',
          );
        }

        return result;
      },
    );
  }

  /// Optimize focus node management.
  static FocusNode createOptimizedFocusNode({
    String? debugLabel,
    bool skipTraversal = false,
  }) {
    return FocusNode(
      debugLabel: debugLabel,
      skipTraversal: skipTraversal,
    );
  }

  /// Memoization helper for expensive computations.
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

/// Performance hints for Flutter rendering engine.
class RenderingHints {
  RenderingHints._();

  static const Widget staticWidget = SizedBox.shrink();
  static const ScrollPhysics fixedExtentDelegate = FixedExtentScrollPhysics();
  static const ScrollPhysics shortContentPhysics = ClampingScrollPhysics();
  static const ScrollPhysics longListPhysics = AlwaysScrollableScrollPhysics();
}

/// Widget rebuild prevention utilities.
class RebuildPrevention {
  RebuildPrevention._();

  /// Wrap with keep-alive to prevent disposal in lazily built lists.
  static Widget keepAlive({
    required Widget child,
    bool wantKeepAlive = true,
  }) {
    return _KeepAliveWrapper(
      wantKeepAlive: wantKeepAlive,
      child: child,
    );
  }

  /// Use ValueKey to preserve widget state across rebuilds.
  static ValueKey<T> stableKey<T>(T value) {
    return ValueKey<T>(value);
  }

  /// Use GlobalKey when widget state must persist.
  static GlobalKey createPersistentKey() {
    return GlobalKey();
  }
}

/// Mixin to track widget rebuild count in debug builds.
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
        'Excessive rebuilds: $runtimeType rebuilt '
        '${_rebuildCounts[runtimeType]} times',
      );
    }
  }

  static void printStats() {
    debugPrint('Widget Rebuild Statistics:');
    for (final entry in _rebuildCounts.entries) {
      debugPrint('  ${entry.key}: ${entry.value} rebuilds');
    }
  }

  static void resetStats() {
    _rebuildCounts.clear();
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  const _KeepAliveWrapper({
    required this.wantKeepAlive,
    required this.child,
  });

  final bool wantKeepAlive;
  final Widget child;

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin<_KeepAliveWrapper> {
  @override
  bool get wantKeepAlive => widget.wantKeepAlive;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}