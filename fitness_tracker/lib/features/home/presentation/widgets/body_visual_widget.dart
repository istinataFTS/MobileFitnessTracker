import 'package:flutter/material.dart';

import '../../../../core/themes/app_theme.dart';
import '../home_page_keys.dart';
import '../models/home_view_data.dart';

class BodyVisualWidget extends StatelessWidget {
  const BodyVisualWidget({super.key, required this.viewData});

  final HomeBodyVisualViewData viewData;

  static const String _frontBaseAsset = 'assets/images/body/FrontLook.png';
  static const String _backBaseAsset = 'assets/images/body/BackLook.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      key: HomePageKeys.bodyVisualKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Muscle map',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                viewData.subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textMedium),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _BodyFigure(
                  label: 'Front',
                  baseAssetPath: _frontBaseAsset,
                  layers: viewData.frontLayers,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BodyFigure(
                  label: 'Back',
                  baseAssetPath: _backBaseAsset,
                  layers: viewData.backLayers,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyFigure extends StatelessWidget {
  const _BodyFigure({
    required this.label,
    required this.baseAssetPath,
    required this.layers,
  });

  final String label;
  final String baseAssetPath;
  final List<HomeBodyOverlayViewData> layers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 0.62,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(baseAssetPath, fit: BoxFit.contain),
              for (final HomeBodyOverlayViewData layer in layers)
                Opacity(
                  opacity: layer.opacity,
                  child: Image.asset(
                    layer.assetPath,
                    fit: BoxFit.contain,
                    color: layer.color,
                    colorBlendMode: BlendMode.srcATop,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
