
import '../../../../config/env_config.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/muscle_groups.dart';
import '../../../../core/constants/muscle_stimulus_constants.dart'
    show MuscleStimulus;
import '../../../../core/utils/week_range_label_formatter.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/entities/muscle_visual_data.dart';
import '../../../../domain/entities/nutrition_log.dart';
import '../../../../domain/entities/target.dart';
import '../../../../domain/entities/time_period.dart';
import '../../application/models/home_dashboard_data.dart';
import '../../application/muscle_visual_bloc.dart';
import '../models/home_view_data.dart';

class HomeViewDataMapper {
  const HomeViewDataMapper._();

  /// Maps fine-grained muscle-group slugs (from [MuscleStimulus] constants) to
  /// the front-side body overlay assets.  Keys are typed constants — any key
  /// mismatch (slug changed, typo) fails at compile-time, not silently at
  /// runtime.
  static const Map<String, List<String>> _frontBodyAssetMap =
      <String, List<String>>{
        MuscleStimulus.frontDelts: <String>[
          'assets/images/body/front_delts.png',
        ],
        MuscleStimulus.sideDelts: <String>[
          'assets/images/body/front_delts.png',
          'assets/images/body/front_reardelt.png',
        ],
        MuscleStimulus.upperTraps: <String>[
          'assets/images/body/front_uppertraps.png',
          'assets/images/body/front_neck.png',
        ],
        MuscleStimulus.upperChest: <String>[
          'assets/images/body/front_chest.png',
        ],
        MuscleStimulus.midChest: <String>[
          'assets/images/body/front_chest.png',
        ],
        MuscleStimulus.lowerChest: <String>[
          'assets/images/body/front_chest.png',
        ],
        MuscleStimulus.biceps: <String>['assets/images/body/front_biceps.png'],
        MuscleStimulus.forearms: <String>[
          'assets/images/body/front_forearms.png',
        ],
        MuscleStimulus.abs: <String>['assets/images/body/front_abs.png'],
        MuscleStimulus.obliques: <String>[
          'assets/images/body/front_obliques.png',
        ],
        MuscleStimulus.lovehandles: <String>[
          'assets/images/body/front_lovehandles.png',
        ],
        MuscleStimulus.hipadductors: <String>[
          'assets/images/body/front_hipadductors.png',
        ],
        MuscleStimulus.quads: <String>['assets/images/body/front_quads.png'],
        MuscleStimulus.calves: <String>['assets/images/body/front_calves.png'],
      };

  /// Maps fine-grained muscle-group slugs to the back-side body overlay assets.
  static const Map<String, List<String>> _backBodyAssetMap =
      <String, List<String>>{
        MuscleStimulus.rearDelts: <String>[
          'assets/images/body/back_reardelt.png',
        ],
        MuscleStimulus.sideDelts: <String>[
          'assets/images/body/back_reardelt.png',
        ],
        MuscleStimulus.upperTraps: <String>[
          'assets/images/body/back_uppertraps.png',
        ],
        MuscleStimulus.middleTraps: <String>[
          'assets/images/body/back_middletraps.png',
        ],
        MuscleStimulus.lowerTraps: <String>[
          'assets/images/body/back_lowertraps.png',
        ],
        MuscleStimulus.lats: <String>[
          'assets/images/body/back_lats.png',
          'assets/images/body/back_smalllats.png',
        ],
        MuscleStimulus.triceps: <String>[
          'assets/images/body/back_triceps.png',
        ],
        MuscleStimulus.forearms: <String>[
          'assets/images/body/back_forearms.png',
        ],
        MuscleStimulus.lowerBack: <String>[
          'assets/images/body/back_lowerback.png',
        ],
        MuscleStimulus.glutes: <String>['assets/images/body/back_glutes.png'],
        MuscleStimulus.hipadductors: <String>[
          'assets/images/body/back_hipadductors.png',
        ],
        MuscleStimulus.quads: <String>['assets/images/body/back_quads.png'],
        MuscleStimulus.hamstrings: <String>[
          'assets/images/body/back_hamstring.png',
        ],
        MuscleStimulus.calves: <String>['assets/images/body/back_calves.png'],
      };

  static HomePageViewData map({
    required HomeDashboardData homeData,
    required MuscleVisualState muscleVisualState,
    required AppSettings settings,
  }) {
    final List<Target> trainingTargets = _filterTrainingTargets(
      homeData.targets,
    );
    final List<Target> macroTargets = _filterMacroTargets(homeData.targets);
    final TimePeriod currentPeriod = _resolveCurrentPeriod(muscleVisualState);
    final MuscleMapMode currentMode = _resolveCurrentMode(muscleVisualState);

    return HomePageViewData(
      greeting: '${AppStrings.hello}, ${EnvConfig.userName}!',
      weekRangeLabel: WeekRangeLabelFormatter.formatForDate(
        DateTime.now(),
        weekStartDay: settings.weekStartDay,
      ),
      nutrition: _mapNutrition(
        macroTargets: macroTargets,
        dailyMacros: homeData.dailyMacros,
        todaysLogs: homeData.todaysLogs,
      ),
      progress: _mapProgress(
        weeklySetCount: homeData.weeklySetCount,
        trainingTargets: trainingTargets,
        muscleVisualState: muscleVisualState,
        currentPeriod: currentPeriod,
        currentMode: currentMode,
      ),
      muscleGroups: _mapMuscleGroupProgress(
        targets: trainingTargets,
        muscleSetCounts: homeData.muscleSetCounts,
      ),
      showMuscleGroups: trainingTargets.isNotEmpty,
    );
  }

  static List<Target> _filterTrainingTargets(List<Target> targets) {
    return targets
        .where((Target target) => target.isWeeklyMuscleTarget)
        .toList(growable: false);
  }

  static List<Target> _filterMacroTargets(List<Target> targets) {
    return targets
        .where((Target target) => target.isDailyMacroTarget)
        .toList(growable: false);
  }

  static TimePeriod _resolveCurrentPeriod(MuscleVisualState muscleVisualState) {
    if (muscleVisualState is MuscleVisualLoaded) {
      return muscleVisualState.currentPeriod;
    }

    if (muscleVisualState is MuscleVisualLoading) {
      return muscleVisualState.period;
    }

    if (muscleVisualState is MuscleVisualError) {
      return muscleVisualState.period;
    }

    return TimePeriod.week;
  }

  static MuscleMapMode _resolveCurrentMode(MuscleVisualState muscleVisualState) {
    if (muscleVisualState is MuscleVisualLoaded) return muscleVisualState.mode;
    if (muscleVisualState is MuscleVisualLoading) return muscleVisualState.mode;
    if (muscleVisualState is MuscleVisualError) return muscleVisualState.mode;
    return MuscleMapMode.volume;
  }

  static HomeNutritionCardViewData _mapNutrition({
    required List<Target> macroTargets,
    required Map<String, double> dailyMacros,
    required List<NutritionLog> todaysLogs,
  }) {
    final Map<String, double> targetMap = <String, double>{
      for (final Target target in macroTargets)
        target.categoryKey: target.targetValue,
    };

    return HomeNutritionCardViewData(
      totalCaloriesLabel: '${(dailyMacros['calories'] ?? 0).round()} kcal',
      macros: <HomeMacroProgressViewData>[
        _buildMacroProgress(
          label: 'Protein',
          unit: 'g',
          actual: dailyMacros['protein'] ?? 0,
          target: targetMap['protein'] ?? 0,
        ),
        _buildMacroProgress(
          label: 'Carbs',
          unit: 'g',
          actual: dailyMacros['carbs'] ?? 0,
          target: targetMap['carbs'] ?? 0,
        ),
        _buildMacroProgress(
          label: 'Fats',
          unit: 'g',
          actual: dailyMacros['fats'] ?? 0,
          target: targetMap['fats'] ?? 0,
        ),
      ],
      recentEntries: todaysLogs
          .take(3)
          .map(
            (NutritionLog log) => HomeRecentNutritionEntryViewData(
              title: log.mealName,
              subtitle:
                  '${log.proteinGrams.toStringAsFixed(0)}P • '
                  '${log.carbsGrams.toStringAsFixed(0)}C • '
                  '${log.fatGrams.toStringAsFixed(0)}F • '
                  '${log.calories.round()} kcal',
              isMealLog: log.isMealLog,
            ),
          )
          .toList(growable: false),
      hasEntries: todaysLogs.isNotEmpty,
    );
  }

  static HomeMacroProgressViewData _buildMacroProgress({
    required String label,
    required String unit,
    required double actual,
    required double target,
  }) {
    final bool hasTarget = target > 0;
    final bool isComplete = hasTarget && actual >= target;
    final double progressValue = hasTarget
        ? (actual / target).clamp(0.0, 1.0)
        : 0.0;
    final double remaining = hasTarget
        ? (target - actual).clamp(0.0, target)
        : 0.0;

    return HomeMacroProgressViewData(
      label: label,
      progressLabel: hasTarget
          ? '${actual.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit'
          : '${actual.toStringAsFixed(0)} $unit',
      trailingLabel: hasTarget
          ? (isComplete ? 'Done' : '${remaining.toStringAsFixed(0)} $unit left')
          : 'No target',
      progressValue: progressValue,
      hasTarget: hasTarget,
      isComplete: isComplete,
    );
  }

  static HomeProgressCardViewData _mapProgress({
    required int weeklySetCount,
    required List<Target> trainingTargets,
    required MuscleVisualState muscleVisualState,
    required TimePeriod currentPeriod,
    required MuscleMapMode currentMode,
  }) {
    // Resolver-sourced count so the stat card can never disagree with the
    // body map — both now count only sets that resolved to ≥1 positive
    // muscle factor.
    final int totalSets = weeklySetCount;
    final int totalTarget = trainingTargets.fold<int>(
      0,
      (int sum, Target target) => sum + target.weeklyGoal,
    );
    final int remainingTarget = (totalTarget - totalSets).clamp(0, totalTarget);
    final bool selectorEnabled = muscleVisualState is! MuscleVisualLoading;

    // In fatigue mode the period selector is hidden — fatigue is always "now".
    final bool showPeriodSelector = currentMode == MuscleMapMode.volume;

    final String cardTitle = currentMode == MuscleMapMode.fatigue
        ? 'Muscle Fatigue'
        : '${AppStrings.progress} • ${_periodLabel(currentPeriod)}';

    final HomeBodyVisualViewData emptyVisual = HomeBodyVisualViewData(
      frontLayers: const <HomeBodyOverlayViewData>[],
      backLayers: const <HomeBodyOverlayViewData>[],
      subtitle: _bodySubtitle(
        hasHighlights: false,
        mode: currentMode,
      ),
    );

    if (muscleVisualState is MuscleVisualLoading ||
        muscleVisualState is MuscleVisualInitial) {
      return HomeProgressCardViewData(
        title: cardTitle,
        selectedPeriod: currentPeriod,
        selectorEnabled: selectorEnabled,
        showPeriodSelector: showPeriodSelector,
        muscleMapMode: currentMode,
        totalSetsLabel: totalSets.toString(),
        remainingTargetLabel: totalTarget > 0 ? remainingTarget.toString() : '-',
        trainedMusclesLabel: '-',
        targetTone: _targetTone(
          remainingTarget,
          showTarget: totalTarget > 0 && currentPeriod == TimePeriod.week,
        ),
        bodyVisual: emptyVisual,
        muscleSummary: const <HomeMuscleSummaryItemViewData>[],
        isLoading: true,
        errorMessage: null,
      );
    }

    if (muscleVisualState is MuscleVisualError) {
      return HomeProgressCardViewData(
        title: cardTitle,
        selectedPeriod: currentPeriod,
        selectorEnabled: selectorEnabled,
        showPeriodSelector: showPeriodSelector,
        muscleMapMode: currentMode,
        totalSetsLabel: totalSets.toString(),
        remainingTargetLabel:
            totalTarget > 0 && currentPeriod == TimePeriod.week
            ? remainingTarget.toString()
            : '-',
        trainedMusclesLabel: '-',
        targetTone: _targetTone(
          remainingTarget,
          showTarget: totalTarget > 0 && currentPeriod == TimePeriod.week,
        ),
        bodyVisual: emptyVisual,
        muscleSummary: const <HomeMuscleSummaryItemViewData>[],
        isLoading: false,
        errorMessage: muscleVisualState.message,
      );
    }

    final MuscleVisualLoaded loaded = muscleVisualState as MuscleVisualLoaded;
    final bool showTarget =
        loaded.currentPeriod == TimePeriod.week && totalTarget > 0;

    final List<MuscleVisualData> trained =
        loaded.muscleData.values
            .where(
              (MuscleVisualData item) =>
                  item.hasTrained && item.totalStimulus > 0,
            )
            .toList()
          ..sort(
            (MuscleVisualData a, MuscleVisualData b) =>
                b.totalStimulus.compareTo(a.totalStimulus),
          );

    final HomeBodyVisualViewData bodyVisual = _mapBodyVisual(
      loaded.muscleData,
      mode: currentMode,
    );

    return HomeProgressCardViewData(
      title: cardTitle,
      selectedPeriod: currentPeriod,
      selectorEnabled: selectorEnabled,
      showPeriodSelector: showPeriodSelector,
      muscleMapMode: currentMode,
      totalSetsLabel: totalSets.toString(),
      remainingTargetLabel: showTarget ? remainingTarget.toString() : '-',
      trainedMusclesLabel: loaded.trainedMuscleCount.toString(),
      targetTone: _targetTone(remainingTarget, showTarget: showTarget),
      bodyVisual: bodyVisual,
      muscleSummary: trained
          .take(6)
          .map(
            (MuscleVisualData item) => HomeMuscleSummaryItemViewData(
              displayName: item.displayName,
              stimulusLabel: item.totalStimulus.toStringAsFixed(0),
              intensityLabel: item.intensityLevel,
              color: item.color,
            ),
          )
          .toList(growable: false),
      isLoading: false,
      errorMessage: null,
    );
  }

  static HomeBodyVisualViewData _mapBodyVisual(
    Map<String, MuscleVisualData> muscleData, {
    required MuscleMapMode mode,
  }) {
    final Map<String, HomeBodyOverlayViewData> frontLayers =
        <String, HomeBodyOverlayViewData>{};
    final Map<String, HomeBodyOverlayViewData> backLayers =
        <String, HomeBodyOverlayViewData>{};

    for (final MuscleVisualData item in muscleData.values) {
      if (!item.hasTrained || item.overlayOpacity <= 0) {
        continue;
      }

      for (final String assetPath
          in _frontBodyAssetMap[item.muscleGroup] ?? const <String>[]) {
        _mergeOverlay(frontLayers, assetPath: assetPath, item: item);
      }

      for (final String assetPath
          in _backBodyAssetMap[item.muscleGroup] ?? const <String>[]) {
        _mergeOverlay(backLayers, assetPath: assetPath, item: item);
      }
    }

    final bool hasHighlights =
        frontLayers.isNotEmpty || backLayers.isNotEmpty;

    return HomeBodyVisualViewData(
      frontLayers: frontLayers.values.toList(growable: false),
      backLayers: backLayers.values.toList(growable: false),
      subtitle: _bodySubtitle(hasHighlights: hasHighlights, mode: mode),
    );
  }

  static String _bodySubtitle({
    required bool hasHighlights,
    required MuscleMapMode mode,
  }) {
    if (mode == MuscleMapMode.fatigue) {
      return hasHighlights ? 'Current fatigue level' : 'Muscles fully recovered';
    }
    return hasHighlights ? 'Front and back load' : 'No training load yet';
  }

  static void _mergeOverlay(
    Map<String, HomeBodyOverlayViewData> target, {
    required String assetPath,
    required MuscleVisualData item,
  }) {
    final HomeBodyOverlayViewData candidate = HomeBodyOverlayViewData(
      assetPath: assetPath,
      color: item.color,
      opacity: item.overlayOpacity,
      label: item.displayName,
    );

    final HomeBodyOverlayViewData? existing = target[assetPath];
    if (existing == null || candidate.opacity >= existing.opacity) {
      target[assetPath] = candidate;
    }
  }

  static HomeTone _targetTone(int remainingTarget, {required bool showTarget}) {
    if (!showTarget) {
      return HomeTone.muted;
    }

    if (remainingTarget <= 0) {
      return HomeTone.success;
    }

    if (remainingTarget <= 3) {
      return HomeTone.warning;
    }

    return HomeTone.primary;
  }

  static List<HomeMuscleGroupProgressViewData> _mapMuscleGroupProgress({
    required List<Target> targets,
    required Map<String, int> muscleSetCounts,
  }) {
    return targets
        .map((Target target) {
          final int currentSets = muscleSetCounts[target.categoryKey] ?? 0;
          final int targetSets = target.weeklyGoal;
          final double rawProgress = targetSets > 0
              ? currentSets / targetSets
              : 0;
          final double progressValue = rawProgress.clamp(0.0, 1.0);
          final int percentage = (rawProgress * 100).clamp(0, 100).toInt();
          final bool isComplete = targetSets > 0 && currentSets >= targetSets;

          return HomeMuscleGroupProgressViewData(
            title: MuscleGroups.getDisplayName(target.categoryKey),
            progressLabel: '$currentSets / $targetSets ${target.unit}',
            percentageLabel: '$percentage%',
            progressValue: progressValue,
            isComplete: isComplete,
            tone: isComplete ? HomeTone.success : HomeTone.primary,
          );
        })
        .toList(growable: false);
  }

  static String _periodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.today:
        return AppStrings.periodToday;
      case TimePeriod.week:
        return AppStrings.periodWeek;
      case TimePeriod.month:
        return AppStrings.periodMonth;
      case TimePeriod.allTime:
        return AppStrings.periodAllTime;
    }
  }
}
