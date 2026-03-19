import 'package:equatable/equatable.dart';

class HomeNutritionSummaryViewData extends Equatable {
  final String totalCaloriesLabel;
  final List<HomeMacroProgressItemViewData> macroItems;
  final List<HomeNutritionRecentLogItemViewData> recentLogs;
  final bool hasLogs;

  const HomeNutritionSummaryViewData({
    required this.totalCaloriesLabel,
    required this.macroItems,
    required this.recentLogs,
    required this.hasLogs,
  });

  @override
  List<Object?> get props => [
        totalCaloriesLabel,
        macroItems,
        recentLogs,
        hasLogs,
      ];
}

class HomeMacroProgressItemViewData extends Equatable {
  final String label;
  final String progressText;
  final String trailingText;
  final double progressValue;
  final bool isComplete;
  final bool hasTarget;

  const HomeMacroProgressItemViewData({
    required this.label,
    required this.progressText,
    required this.trailingText,
    required this.progressValue,
    required this.isComplete,
    required this.hasTarget,
  });

  @override
  List<Object?> get props => [
        label,
        progressText,
        trailingText,
        progressValue,
        isComplete,
        hasTarget,
      ];
}

class HomeNutritionRecentLogItemViewData extends Equatable {
  final String title;
  final String subtitle;
  final bool isMealLog;

  const HomeNutritionRecentLogItemViewData({
    required this.title,
    required this.subtitle,
    required this.isMealLog,
  });

  @override
  List<Object?> get props => [
        title,
        subtitle,
        isMealLog,
      ];
}