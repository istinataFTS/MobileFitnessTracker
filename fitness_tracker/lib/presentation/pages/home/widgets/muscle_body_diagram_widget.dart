import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/svg_muscle_mapping.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../domain/entities/muscle_visual_data.dart';

/// Muscle body diagram widget with colored muscle regions
class MuscleBodyDiagramWidget extends StatelessWidget {
  final Map<String, MuscleVisualData> muscleData;
  final bool isFrontView;
  final bool isLoading;

  const MuscleBodyDiagramWidget({
    super.key,
    required this.muscleData,
    required this.isFrontView,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState(context);
    }

    if (muscleData.isEmpty) {
      return _buildEmptyState(context);
    }

    return RepaintBoundary(
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 500,
          maxWidth: 300,
        ),
        child: AspectRatio(
          aspectRatio: 3 / 5, // Typical human body proportions
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Base body outline (SVG)
                _buildBodyOutline(context),
                
                // Colored muscle overlays
                _buildMuscleOverlays(context),
                
                // View indicator
                _buildViewIndicator(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build loading state indicator
  Widget _buildLoadingState(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 500,
        maxWidth: 300,
      ),
      child: AspectRatio(
        aspectRatio: 3 / 5,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppTheme.primaryOrange,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.loadingVisualization,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build empty state (no workout data)
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 500,
        maxWidth: 300,
      ),
      child: AspectRatio(
        aspectRatio: 3 / 5,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: AppTheme.textDim,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.noWorkoutData,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.noWorkoutDataDesc,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMedium,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build body outline using SVG files
  /// 
  /// Renders FrontLook.svg or BackLook.svg based on current view
  /// SVG files should be placed in assets/images/body/
  Widget _buildBodyOutline(BuildContext context) {
    final svgPath = isFrontView
        ? 'assets/images/body/FrontLook.svg'
        : 'assets/images/body/BackLook.svg';

    return SvgPicture.asset(
      svgPath,
      fit: BoxFit.contain,
      placeholderBuilder: (context) => Container(
        color: AppTheme.surfaceDark,
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryOrange,
          ),
        ),
      ),
      // If SVG fails to load, show error state
      colorFilter: null, // Don't apply color filter to base SVG
    );
  }

  /// Build colored muscle overlays
  /// 
  /// Renders colored shapes over muscle regions based on training data
  /// Uses CustomPainter to draw color overlays on SVG paths
  Widget _buildMuscleOverlays(BuildContext context) {
    final visibleMuscles = isFrontView
        ? SvgMuscleMapping.frontViewMuscles
        : SvgMuscleMapping.backViewMuscles;

    return CustomPaint(
      painter: _MuscleOverlayPainter(
        muscleData: muscleData,
        visibleMuscles: visibleMuscles,
        isFrontView: isFrontView,
      ),
    );
  }

  /// Build view indicator badge
  Widget _buildViewIndicator(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Text(
          isFrontView ? AppStrings.frontView : AppStrings.backView,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

/// Custom painter for muscle color overlays
/// 
/// Draws colored regions for each muscle based on training intensity
/// 
/// NOTE: This is a simplified implementation that draws colored rectangles
/// as placeholders. To properly color SVG paths, you'll need to:
/// 
/// 1. Parse the SVG files to get path coordinates
/// 2. Use the SvgMuscleMapping.svgPathIds to identify muscle regions
/// 3. Apply colors to specific SVG paths using flutter_svg's color filters
/// 
/// ADVANCED IMPLEMENTATION OPTIONS:
/// 
/// Option A: Modify SVG at runtime
/// - Load SVG as string
/// - Find path elements by ID
/// - Inject fill="color" attributes
/// - Render modified SVG
/// 
/// Option B: Layer multiple SVG renders
/// - Render base SVG (grayscale)
/// - For each trained muscle:
///   - Render SVG with ColorFilter on specific paths
///   - Use clipPath to show only that muscle
/// 
/// Option C: Use CustomPainter with SVG path data
/// - Extract path data from SVG
/// - Store as Path objects
/// - Paint each path with appropriate color
/// 
/// For now, this draws placeholder rectangles to demonstrate the concept.
class _MuscleOverlayPainter extends CustomPainter {
  final Map<String, MuscleVisualData> muscleData;
  final List<String> visibleMuscles;
  final bool isFrontView;

  _MuscleOverlayPainter({
    required this.muscleData,
    required this.visibleMuscles,
    required this.isFrontView,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: Replace with actual SVG path coloring
    // This is a placeholder that demonstrates the concept
    // See class documentation for implementation options
    
    _drawPlaceholderMuscleRegions(canvas, size);
  }

  /// Placeholder muscle region visualization
  /// 
  /// Shows concept of colored muscle regions using simple shapes
  /// Replace this with actual SVG path coloring once SVG files are available
  void _drawPlaceholderMuscleRegions(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    
    // Only draw muscles visible on current view
    for (final muscleGroup in visibleMuscles) {
      if (!muscleData.containsKey(muscleGroup)) continue;
      
      final data = muscleData[muscleGroup]!;
      if (!data.hasTrained) continue; // Skip untrained muscles
      
      // Get approximate position for this muscle (placeholder logic)
      final position = _getMusclePosition(muscleGroup, centerX, size.height);
      if (position == null) continue;
      
      final paint = Paint()
        ..color = data.color
        ..style = PaintingStyle.fill;

      // Draw colored region (placeholder - replace with actual SVG path)
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: position,
          width: size.width * 0.15,
          height: size.height * 0.1,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  /// Get approximate position for muscle group (placeholder)
  /// 
  /// Returns null if muscle should not be drawn on current view
  /// Replace with actual SVG path coordinates
  Offset? _getMusclePosition(String muscleGroup, double centerX, double height) {
    // This is placeholder logic - replace with actual SVG coordinates
    // based on SvgMuscleMapping.svgPathIds
    
    if (isFrontView) {
      switch (muscleGroup) {
        case 'front-delts':
          return Offset(centerX, height * 0.25);
        case 'mid-chest':
          return Offset(centerX, height * 0.3);
        case 'biceps':
          return Offset(centerX, height * 0.35);
        case 'abs':
          return Offset(centerX, height * 0.45);
        case 'quads':
          return Offset(centerX, height * 0.65);
        default:
          return null;
      }
    } else {
      switch (muscleGroup) {
        case 'upper-traps':
          return Offset(centerX, height * 0.2);
        case 'lats':
          return Offset(centerX, height * 0.35);
        case 'lower-back':
          return Offset(centerX, height * 0.45);
        case 'glutes':
          return Offset(centerX, height * 0.55);
        case 'hamstrings':
          return Offset(centerX, height * 0.65);
        default:
          return null;
      }
    }
  }

  @override
  bool shouldRepaint(_MuscleOverlayPainter oldDelegate) {
    return oldDelegate.muscleData != muscleData ||
        oldDelegate.isFrontView != isFrontView;
  }
}