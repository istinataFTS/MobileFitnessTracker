import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../domain/entities/time_period.dart';

enum HomeTone {
  muted,
  primary,
  warning,
  success,
}

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
    required this.totalSetsLabel,
    required this.remainingTargetLabel,
    required this.trainedMusclesLabel,
    required this.targetTone,
    required this.muscleSummary,
    required this.isLoading,
    required this.errorMessage,
  });

  final String title;
  final TimePeriod selectedPeriod;
  final bool selectorEnabled;
  final String totalSetsLabel;
  final String remainingTargetLabel;
  final String trainedMusclesLabel;
  final HomeTone targetTone;
  final List<HomeMuscleSummaryItemViewData> muscleSummary;
  final bool isLoading;
  final String? errorMessage;

  @override
  List<Object?> get props => <Object?>[
        title,
        selectedPeriod,
        selectorEnabled,
        totalSetsLabel,
        remainingTargetLabel,
        trainedMusclesLabel,
        targetTone,
        muscleSummary,
        isLoading,
        errorMessage,
      ];
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