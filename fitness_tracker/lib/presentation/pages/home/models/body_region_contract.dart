import 'package:equatable/equatable.dart';

import 'body_view.dart';

class BodyRegionContract extends Equatable {
  final String id;
  final String muscleGroup;
  final BodyView view;
  final String overlayAssetPath;

  const BodyRegionContract({
    required this.id,
    required this.muscleGroup,
    required this.view,
    required this.overlayAssetPath,
  });

  static const List<BodyRegionContract> all = [
    // ==================== FRONT VIEW ====================

    BodyRegionContract(
      id: 'front-delts-left',
      muscleGroup: 'front-delts',
      view: BodyView.front,
      overlayAssetPath:
          'assets/images/body/overlays/front/front_delts_left.png',
    ),
    BodyRegionContract(
      id: 'front-delts-right',
      muscleGroup: 'front-delts',
      view: BodyView.front,
      overlayAssetPath:
          'assets/images/body/overlays/front/front_delts_right.png',
    ),

    BodyRegionContract(
      id: 'side-delts-left-front',
      muscleGroup: 'side-delts',
      view: BodyView.front,
      overlayAssetPath:
          'assets/images/body/overlays/front/side_delts_left_front.png',
    ),
    BodyRegionContract(
      id: 'side-delts-right-front',
      muscleGroup: 'side-delts',
      view: BodyView.front,
      overlayAssetPath:
          'assets/images/body/overlays/front/side_delts_right_front.png',
    ),

    BodyRegionContract(
      id: 'upper-chest-left',
      muscleGroup: 'upper-chest',
      view: BodyView.front,
      overlayAssetPath:
          'assets/images/body/overlays/front/upper_chest_left.png',
    ),
    BodyRegionContract(
      id: 'upper-chest-right',
      muscleGroup: 'upper-chest',
      view: BodyView.front,
      overlayAssetPath:
          'assets/images/body/overlays/front/upper_chest_right.png',
    ),

    BodyRegionContract(
      id: 'mid-chest-left',
      muscleGroup: 'mid-chest',
      view: BodyView.front,
      overlayAssetPath: 'assets/images/body/overlays/front/mid_chest_left.png',
    ),
    BodyRegionContract(
      id: 'mid-chest-right',
      muscleGroup: 'mid-chest',
      view: BodyView.front,
      overlayAssetPath: 'assets/images/body/overlays/front/mid_chest_right.png',
    ),

    BodyRegionContract(
      id: 'lower-chest-left',
      muscleGroup: 'lower-chest',
      view: BodyView.front,
      overlayAssetPath:
          'assets/images/body/overlays/front/lower_chest_left.png',
    ),
    BodyRegionContract(
      id: 'lower-chest-right',
      muscleGroup: 'lower-chest',
      view: BodyView.front,
      overlayAssetPath:
          'assets/images/body/overlays/front/lower_chest_right.png',
    ),

    BodyRegionContract(
      id: 'biceps-left',
      muscleGroup: 'biceps',
      view: BodyView.front,
      overlayAssetPath: 'assets/images/body/overlays/front/biceps_left.png',
    ),
    BodyRegionContract(
      id: 'biceps-right',
      muscleGroup: 'biceps',
      view: BodyView.front,
      overlayAssetPath: 'assets/images/body/overlays/front/biceps_right.png',
    ),

    BodyRegionContract(
      id: 'forearms-left-front',
      muscleGroup: 'forearms',
      view: BodyView.front,
      overlayAssetPath:
          'assets/images/body/overlays/front/forearms_left_front.png',
    ),
    BodyRegionContract(
      id: 'forearms-right-front',
      muscleGroup: 'forearms',
      view: BodyView.front,
      overlayAssetPath:
          'assets/images/body/overlays/front/forearms_right_front.png',
    ),

    BodyRegionContract(
      id: 'abs',
      muscleGroup: 'abs',
      view: BodyView.front,
      overlayAssetPath: 'assets/images/body/overlays/front/abs.png',
    ),

    BodyRegionContract(
      id: 'obliques-left',
      muscleGroup: 'obliques',
      view: BodyView.front,
      overlayAssetPath: 'assets/images/body/overlays/front/obliques_left.png',
    ),
    BodyRegionContract(
      id: 'obliques-right',
      muscleGroup: 'obliques',
      view: BodyView.front,
      overlayAssetPath: 'assets/images/body/overlays/front/obliques_right.png',
    ),

    BodyRegionContract(
      id: 'quads-left',
      muscleGroup: 'quads',
      view: BodyView.front,
      overlayAssetPath: 'assets/images/body/overlays/front/quads_left.png',
    ),
    BodyRegionContract(
      id: 'quads-right',
      muscleGroup: 'quads',
      view: BodyView.front,
      overlayAssetPath: 'assets/images/body/overlays/front/quads_right.png',
    ),

    // ==================== BACK VIEW ====================

    BodyRegionContract(
      id: 'rear-delts-left',
      muscleGroup: 'rear-delts',
      view: BodyView.back,
      overlayAssetPath:
          'assets/images/body/overlays/back/rear_delts_left.png',
    ),
    BodyRegionContract(
      id: 'rear-delts-right',
      muscleGroup: 'rear-delts',
      view: BodyView.back,
      overlayAssetPath:
          'assets/images/body/overlays/back/rear_delts_right.png',
    ),

    BodyRegionContract(
      id: 'side-delts-left-back',
      muscleGroup: 'side-delts',
      view: BodyView.back,
      overlayAssetPath:
          'assets/images/body/overlays/back/side_delts_left_back.png',
    ),
    BodyRegionContract(
      id: 'side-delts-right-back',
      muscleGroup: 'side-delts',
      view: BodyView.back,
      overlayAssetPath:
          'assets/images/body/overlays/back/side_delts_right_back.png',
    ),

    BodyRegionContract(
      id: 'upper-traps',
      muscleGroup: 'upper-traps',
      view: BodyView.back,
      overlayAssetPath: 'assets/images/body/overlays/back/upper_traps.png',
    ),
    BodyRegionContract(
      id: 'middle-traps',
      muscleGroup: 'middle-traps',
      view: BodyView.back,
      overlayAssetPath: 'assets/images/body/overlays/back/middle_traps.png',
    ),
    BodyRegionContract(
      id: 'lower-traps',
      muscleGroup: 'lower-traps',
      view: BodyView.back,
      overlayAssetPath: 'assets/images/body/overlays/back/lower_traps.png',
    ),

    BodyRegionContract(
      id: 'lats-left',
      muscleGroup: 'lats',
      view: BodyView.back,
      overlayAssetPath: 'assets/images/body/overlays/back/lats_left.png',
    ),
    BodyRegionContract(
      id: 'lats-right',
      muscleGroup: 'lats',
      view: BodyView.back,
      overlayAssetPath: 'assets/images/body/overlays/back/lats_right.png',
    ),

    BodyRegionContract(
      id: 'triceps-left',
      muscleGroup: 'triceps',
      view: BodyView.back,
      overlayAssetPath: 'assets/images/body/overlays/back/triceps_left.png',
    ),
    BodyRegionContract(
      id: 'triceps-right',
      muscleGroup: 'triceps',
      view: BodyView.back,
      overlayAssetPath: 'assets/images/body/overlays/back/triceps_right.png',
    ),

    BodyRegionContract(
      id: 'forearms-left-back',
      muscleGroup: 'forearms',
      view: BodyView.back,
      overlayAssetPath:
          'assets/images/body/overlays/back/forearms_left_back.png',
    ),
    BodyRegionContract(
      id: 'forearms-right-back',
      muscleGroup: 'forearms',
      view: BodyView.back,
      overlayAssetPath:
          'assets/images/body/overlays/back/forearms_right_back.png',
    ),

    BodyRegionContract(
      id: 'lower-back',
      muscleGroup: 'lower-back',
      view: BodyView.back,
      overlayAssetPath: 'assets/images/body/overlays/back/lower_back.png',
    ),

    BodyRegionContract(
      id: 'glutes-left',
      muscleGroup: 'glutes',
      view: BodyView.back,
      overlayAssetPath: 'assets/images/body/overlays/back/glutes_left.png',
    ),
    BodyRegionContract(
      id: 'glutes-right',
      muscleGroup: 'glutes',
      view: BodyView.back,
      overlayAssetPath: 'assets/images/body/overlays/back/glutes_right.png',
    ),

    BodyRegionContract(
      id: 'hamstrings-left',
      muscleGroup: 'hamstrings',
      view: BodyView.back,
      overlayAssetPath: 'assets/images/body/overlays/back/hamstrings_left.png',
    ),
    BodyRegionContract(
      id: 'hamstrings-right',
      muscleGroup: 'hamstrings',
      view: BodyView.back,
      overlayAssetPath:
          'assets/images/body/overlays/back/hamstrings_right.png',
    ),

    BodyRegionContract(
      id: 'calves-left',
      muscleGroup: 'calves',
      view: BodyView.back,
      overlayAssetPath: 'assets/images/body/overlays/back/calves_left.png',
    ),
    BodyRegionContract(
      id: 'calves-right',
      muscleGroup: 'calves',
      view: BodyView.back,
      overlayAssetPath: 'assets/images/body/overlays/back/calves_right.png',
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

  @override
  List<Object?> get props => [id, muscleGroup, view, overlayAssetPath];
}