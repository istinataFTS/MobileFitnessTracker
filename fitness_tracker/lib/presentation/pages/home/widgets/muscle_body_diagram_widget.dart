import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../domain/entities/muscle_visual_data.dart';
import '../helpers/body_visualization_mapper.dart';
import '../models/body_region_visual_data.dart';
import '../models/body_view.dart';

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

    if (!BodyVisualizationMapper.hasAnyTraining(muscleData)) {
      return _buildEmptyState(context);
    }

    final bodyView = isFrontView ? BodyView.front : BodyView.back;
    final regions = BodyVisualizationMapper.mapRegions(
      muscleData: muscleData,
      view: bodyView,
    );

    return RepaintBoundary(
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 500,
          maxWidth: 300,
        ),
        child: AspectRatio(
          aspectRatio: 3 / 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBodyOutline(context),
                CustomPaint(
                  painter: _BodyRegionOverlayPainter(regions: regions),
                ),
                _buildViewIndicator(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                const CircularProgressIndicator(
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

  Widget _buildBodyOutline(BuildContext context) {
    final imagePath = isFrontView
        ? 'assets/images/body/FrontLook.png'
        : 'assets/images/body/BackLook.png';

    return Image.asset(
      imagePath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppTheme.surfaceDark,
          child: Center(
            child: Text(
              'Failed to load body image',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMedium,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

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

class _BodyRegionOverlayPainter extends CustomPainter {
  final List<BodyRegionVisualData> regions;

  _BodyRegionOverlayPainter({
    required this.regions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final region in regions) {
      if (!region.hasTrained) {
        continue;
      }

      final rect = Rect.fromLTWH(
        region.normalizedRect.left * size.width,
        region.normalizedRect.top * size.height,
        region.normalizedRect.width * size.width,
        region.normalizedRect.height * size.height,
      );

      final fillPaint = Paint()
        ..color = region.color.withOpacity(0.45)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = region.color.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final rrect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(8),
      );

      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(_BodyRegionOverlayPainter oldDelegate) {
    return oldDelegate.regions != regions;
  }
}