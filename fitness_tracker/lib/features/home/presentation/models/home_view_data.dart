import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../domain/entities/time_period.dart';
import '../../application/muscle_visual_bloc.dart' show MuscleMapMode;

enum HomeTone { muted, primary, warning, success }

class HomePageViewData extends Equatable {
  const HomePageViewData({
    required this.greeting,
    required this.weekRangeLabel,
    required this.nutrition,
    required this.progress,
    required this.muscleGroups,
    required this.showMuscleGroups,
  });

  final String greeting;
  final String weekRangeLabel;
  final HomeNutritionCardViewData nutrition;
  final HomeProgressCardViewData progress;
  final List<HomeMuscleGroupProgressViewData> muscleGroups;
  final bool showMuscleGroups;

  @override
  List<Object?> get props => <Object?>[
    greeting,
    weekRangeLabel,
    nutrition,
    progress,
    muscleGroups,
    showMuscleGroups,
  ];
}

class HomeNutritionCardViewData extends Equatable {
  const HomeNutritionCardViewData({
    required this.totalCaloriesLabel,
    required this.macros,
    required this.recentEntries,
    required this.hasEntries,
  });

  final String totalCaloriesLabel;
  final List<HomeMacroProgressViewData> macros;
  final List<HomeRecentNutritionEntryViewData> recentEntries;
  final bool hasEntries;

  @override
  List<Object?> get props => <Object?>[
    totalCaloriesLabel,
    macros,
    recentEntries,
    hasEntries,
  ];
}

class HomeMacroProgressViewData extends Equatable {
  const HomeMacroProgressViewData({
    required this.label,
    required this.progressLabel,
    required this.trailingLabel,
    required this.progressValue,
    required this.hasTarget,
    required this.isComplete,
  });

  final String label;
  final String progressLabel;
  final String trailingLabel;
  final double progressValue;
  final bool hasTarget;
  final bool isComplete;

  @override
  List<Object?> get props => <Object?>[
    label,
    progressLabel,
    trailingLabel,
    progressValue,
    hasTarget,
    isComplete,
  ];
}

class HomeRecentNutritionEntryViewData extends Equatable {
  const HomeRecentNutritionEntryViewData({
    required this.title,
    required this.subtitle,
    required this.isMealLog,
  });

  final String title;
  final String subtitle;
  final bool isMealLog;

  @override
  List<Object?> get props => <Object?>[title, subtitle, isMealLog];
}

class HomeProgressCardViewData extends Equatable {
  const HomeProgressCardViewData({
    required this.title,
    required this.selectedPeriod,
    required this.selectorEnabled,
    required this.showPeriodSelector,
    required this.muscleMapMode,
    required this.totalSetsLabel,
    required this.remainingTargetLabel,
    required this.trainedMusclesLabel,
    required this.targetTone,
    required this.bodyVisual,
    required this.muscleSummary,
    required this.isLoading,
    required this.errorMessage,
  });

  final String title;
  final TimePeriod selectedPeriod;

  /// Whether the period dropdown is responsive to taps (disabled while loading).
  final bool selectorEnabled;

  /// Whether the period selector is visible at all.
  /// Hidden in fatigue mode because fatigue is always "right now".
  final bool showPeriodSelector;

  /// Which visualisation lens is active.
  final MuscleMapMode muscleMapMode;

  final String totalSetsLabel;
  final String remainingTargetLabel;
  final String trainedMusclesLabel;
  final HomeTone targetTone;
  final HomeBodyVisualViewData bodyVisual;
  final List<HomeMuscleSummaryItemViewData> muscleSummary;
  final bool isLoading;
  final String? errorMessage;

  @override
  List<Object?> get props => <Object?>[
    title,
    selectedPeriod,
    selectorEnabled,
    showPeriodSelector,
    muscleMapMode,
    totalSetsLabel,
    remainingTargetLabel,
    trainedMusclesLabel,
    targetTone,
    bodyVisual,
    muscleSummary,
    isLoading,
    errorMessage,
  ];
}

class HomeBodyVisualViewData extends Equatable {
  const HomeBodyVisualViewData({
    required this.frontLayers,
    required this.backLayers,
    required this.subtitle,
  });

  final List<HomeBodyOverlayViewData> frontLayers;
  final List<HomeBodyOverlayViewData> backLayers;

  /// Descriptive caption shown in the top-right of the muscle map card.
  final String subtitle;

  bool get hasHighlights => frontLayers.isNotEmpty || backLayers.isNotEmpty;

  @override
  List<Object?> get props => <Object?>[frontLayers, backLayers, subtitle];
}

class HomeBodyOverlayViewData extends Equatable {
  const HomeBodyOverlayViewData({
    required this.assetPath,
    required this.color,
    required this.opacity,
    required this.label,
  });

  final String assetPath;
  final Color color;
  final double opacity;
  final String label;

  @override
  List<Object?> get props => <Object?>[assetPath, color, opacity, label];
}

class HomeMuscleSummaryItemViewData extends Equatable {
  const HomeMuscleSummaryItemViewData({
    required this.displayName,
    required this.stimulusLabel,
    required this.intensityLabel,
    required this.color,
  });

  final String displayName;
  final String stimulusLabel;
  final String intensityLabel;
  final Color color;

  @override
  List<Object?> get props => <Object?>[
    displayName,
    stimulusLabel,
    intensityLabel,
    color,
  ];
}

class HomeMuscleGroupProgressViewData extends Equatable {
  const HomeMuscleGroupProgressViewData({
    required this.title,
    required this.progressLabel,
    required this.percentageLabel,
    required this.progressValue,
    required this.isComplete,
    required this.tone,
  });

  final String title;
  final String progressLabel;
  final String percentageLabel;
  final double progressValue;
  final bool isComplete;
  final HomeTone tone;

  @override
  List<Object?> get props => <Object?>[
    title,
    progressLabel,
    percentageLabel,
    progressValue,
    isComplete,
    tone,
  ];
}
