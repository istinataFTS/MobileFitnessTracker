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
                _buildRegionOverlays(regions),
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

  Widget _buildRegionOverlays(List<BodyRegionVisualData> regions) {
    final trainedRegions = regions.where((region) => region.hasTrained).toList();

    return IgnorePointer(
      ignoring: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final region in trainedRegions)
            _TintedOverlayRegion(region: region),
        ],
      ),
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

class _TintedOverlayRegion extends StatelessWidget {
  final BodyRegionVisualData region;

  const _TintedOverlayRegion({
    required this.region,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _overlayOpacityFor(region.visualIntensity),
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          region.color,
          BlendMode.srcIn,
        ),
        child: Image.asset(
          region.overlayAssetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  double _overlayOpacityFor(double intensity) {
    if (intensity <= 0) return 0.0;
    if (intensity < 0.20) return 0.45;
    if (intensity < 0.45) return 0.60;
    if (intensity < 0.70) return 0.72;
    return 0.85;
  }
}