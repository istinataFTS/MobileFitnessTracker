import '../../../../domain/entities/time_period.dart';
import '../../../../domain/muscle_visual/muscle_visual_contract.dart';
import 'body_view.dart';

class BodyRegionContract {
  final String id;
  final String muscleGroup;
  final BodyView view;
  final String overlayAssetPath;
  final MuscleVisualAggregationMode defaultAggregationMode;

  const BodyRegionContract({
    required this.id,
    required this.muscleGroup,
    required this.view,
    required this.overlayAssetPath,
    required this.defaultAggregationMode,
  });

  static const String _bodyAssetRoot = 'assets/images/body';

  static const List<BodyRegionContract> all = <BodyRegionContract>[
    BodyRegionContract(
      id: 'front-neck',
      muscleGroup: 'upper-traps',
      view: BodyView.front,
      overlayAssetPath: '$_bodyAssetRoot/neckFront.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'front-upper-traps',
      muscleGroup: 'upper-traps',
      view: BodyView.front,
      overlayAssetPath: '$_bodyAssetRoot/uppertrapsFront.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'front-front-delts',
      muscleGroup: 'front-delts',
      view: BodyView.front,
      overlayAssetPath: '$_bodyAssetRoot/frontdelts.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'front-chest',
      muscleGroup: 'mid-chest',
      view: BodyView.front,
      overlayAssetPath: '$_bodyAssetRoot/chest.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'front-biceps',
      muscleGroup: 'biceps',
      view: BodyView.front,
      overlayAssetPath: '$_bodyAssetRoot/biceps.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'front-forearms',
      muscleGroup: 'forearms',
      view: BodyView.front,
      overlayAssetPath: '$_bodyAssetRoot/forearmsFront.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'front-abs',
      muscleGroup: 'abs',
      view: BodyView.front,
      overlayAssetPath: '$_bodyAssetRoot/abs.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'front-obliques',
      muscleGroup: 'obliques',
      view: BodyView.front,
      overlayAssetPath: '$_bodyAssetRoot/obliques.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'front-lovehandles',
      muscleGroup: 'lovehandles',
      view: BodyView.front,
      overlayAssetPath: '$_bodyAssetRoot/lovehandles.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'front-hipadductors',
      muscleGroup: 'hipadductors',
      view: BodyView.front,
      overlayAssetPath: '$_bodyAssetRoot/hipadductorsFront.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'front-quads',
      muscleGroup: 'quads',
      view: BodyView.front,
      overlayAssetPath: '$_bodyAssetRoot/quads.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'front-calves',
      muscleGroup: 'calves',
      view: BodyView.front,
      overlayAssetPath: '$_bodyAssetRoot/calvesFront.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'back-upper-traps',
      muscleGroup: 'upper-traps',
      view: BodyView.back,
      overlayAssetPath: '$_bodyAssetRoot/uppertraps.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'back-middle-traps',
      muscleGroup: 'middle-traps',
      view: BodyView.back,
      overlayAssetPath: '$_bodyAssetRoot/middletraps.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'back-lower-traps',
      muscleGroup: 'lower-traps',
      view: BodyView.back,
      overlayAssetPath: '$_bodyAssetRoot/lowertraps.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'back-rear-delts',
      muscleGroup: 'rear-delts',
      view: BodyView.back,
      overlayAssetPath: '$_bodyAssetRoot/reardeltBack.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'back-lats',
      muscleGroup: 'lats',
      view: BodyView.back,
      overlayAssetPath: '$_bodyAssetRoot/lats.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'back-smalllats',
      muscleGroup: 'lats',
      view: BodyView.back,
      overlayAssetPath: '$_bodyAssetRoot/smalllats.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'back-triceps',
      muscleGroup: 'triceps',
      view: BodyView.back,
      overlayAssetPath: '$_bodyAssetRoot/triceps.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'back-forearms',
      muscleGroup: 'forearms',
      view: BodyView.back,
      overlayAssetPath: '$_bodyAssetRoot/forearms.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'back-lowerback',
      muscleGroup: 'lower-back',
      view: BodyView.back,
      overlayAssetPath: '$_bodyAssetRoot/lowerback.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'back-glutes',
      muscleGroup: 'glutes',
      view: BodyView.back,
      overlayAssetPath: '$_bodyAssetRoot/glutes.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'back-hipadductors',
      muscleGroup: 'hipadductors',
      view: BodyView.back,
      overlayAssetPath: '$_bodyAssetRoot/hipadductors.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'back-hamstrings',
      muscleGroup: 'hamstrings',
      view: BodyView.back,
      overlayAssetPath: '$_bodyAssetRoot/hamstring.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'back-quads',
      muscleGroup: 'quads',
      view: BodyView.back,
      overlayAssetPath: '$_bodyAssetRoot/quadsback.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
    BodyRegionContract(
      id: 'back-calves',
      muscleGroup: 'calves',
      view: BodyView.back,
      overlayAssetPath: '$_bodyAssetRoot/calves.png',
      defaultAggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
    ),
  ];

  static List<BodyRegionContract> forView(BodyView view) {
    return all.where((region) => region.view == view).toList(growable: false);
  }

  static List<BodyRegionContract> forMuscle(String muscleGroup) {
    return all
        .where((region) => region.muscleGroup == muscleGroup)
        .toList(growable: false);
  }
}