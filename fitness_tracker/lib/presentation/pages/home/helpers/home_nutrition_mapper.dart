import '../../../../domain/entities/nutrition_log.dart';
import '../bloc/home_bloc.dart';
import '../models/home_nutrition_view_data.dart';

class HomeNutritionMapper {
  const HomeNutritionMapper._();

  static HomeNutritionSummaryViewData map(HomeLoaded homeState) {
    final macroTargets = <String, double>{
      for (final target in homeState.macroTargets)
        target.categoryKey: target.targetValue,
    };

    final dailyMacros = homeState.dailyMacros;

    final macroItems = <HomeMacroProgressItemViewData>[
      _buildMacroItem(
        label: 'Protein',
        actual: dailyMacros['protein'] ?? 0.0,
        target: macroTargets['protein'] ?? 0.0,
        unit: 'g',
      ),
      _buildMacroItem(
        label: 'Carbs',
        actual: dailyMacros['carbs'] ?? 0.0,
        target: macroTargets['carbs'] ?? 0.0,
        unit: 'g',
      ),
      _buildMacroItem(
        label: 'Fats',
        actual: dailyMacros['fats'] ?? 0.0,
        target: macroTargets['fats'] ?? 0.0,
        unit: 'g',
      ),
    ];

    final recentLogs = homeState.todaysLogs
        .take(3)
        .map(_mapRecentLog)
        .toList(growable: false);

    return HomeNutritionSummaryViewData(
      totalCaloriesLabel: '${(dailyMacros['calories'] ?? 0.0).round()} kcal',
      macroItems: macroItems,
      recentLogs: recentLogs,
      hasLogs: recentLogs.isNotEmpty,
    );
  }

  static HomeMacroProgressItemViewData _buildMacroItem({
    required String label,
    required double actual,
    required double target,
    required String unit,
  }) {
    final bool hasTarget = target > 0;
    final double progressValue =
        hasTarget ? (actual / target).clamp(0.0, 1.0) : 0.0;
    final double remaining =
        hasTarget ? (target - actual).clamp(0.0, target) : 0.0;
    final bool isComplete = hasTarget && actual >= target;

    final String progressText = hasTarget
        ? '${actual.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit'
        : '${actual.toStringAsFixed(0)} $unit';

    final String trailingText = hasTarget
        ? isComplete
            ? 'Done'
            : '${remaining.toStringAsFixed(0)} $unit left'
        : 'No target';

    return HomeMacroProgressItemViewData(
      label: label,
      progressText: progressText,
      trailingText: trailingText,
      progressValue: progressValue,
      isComplete: isComplete,
      hasTarget: hasTarget,
    );
  }

  static HomeNutritionRecentLogItemViewData _mapRecentLog(NutritionLog log) {
    return HomeNutritionRecentLogItemViewData(
      title: log.mealName,
      subtitle:
          '${log.proteinGrams.toStringAsFixed(0)}P • '
          '${log.carbsGrams.toStringAsFixed(0)}C • '
          '${log.fatGrams.toStringAsFixed(0)}F • '
          '${log.calories.round()} kcal',
      isMealLog: log.isMealLog,
    );
  }
}