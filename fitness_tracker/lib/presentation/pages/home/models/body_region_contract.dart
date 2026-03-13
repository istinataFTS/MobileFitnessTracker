import 'dart:ui';

import 'package:equatable/equatable.dart';

import 'body_view.dart';

class BodyRegionContract extends Equatable {
  final String id;
  final String muscleGroup;
  final BodyView view;
  final Rect normalizedRect;

  const BodyRegionContract({
    required this.id,
    required this.muscleGroup,
    required this.view,
    required this.normalizedRect,
  });

  static const List<BodyRegionContract> all = [
    // ==================== FRONT VIEW ====================

    BodyRegionContract(
      id: 'front-delts-left',
      muscleGroup: 'front-delts',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.28, 0.16, 0.12, 0.08),
    ),
    BodyRegionContract(
      id: 'front-delts-right',
      muscleGroup: 'front-delts',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.60, 0.16, 0.12, 0.08),
    ),

    BodyRegionContract(
      id: 'side-delts-left-front',
      muscleGroup: 'side-delts',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.20, 0.19, 0.10, 0.09),
    ),
    BodyRegionContract(
      id: 'side-delts-right-front',
      muscleGroup: 'side-delts',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.70, 0.19, 0.10, 0.09),
    ),

    BodyRegionContract(
      id: 'upper-chest-left',
      muscleGroup: 'upper-chest',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.34, 0.22, 0.12, 0.06),
    ),
    BodyRegionContract(
      id: 'upper-chest-right',
      muscleGroup: 'upper-chest',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.54, 0.22, 0.12, 0.06),
    ),

    BodyRegionContract(
      id: 'mid-chest-left',
      muscleGroup: 'mid-chest',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.32, 0.28, 0.14, 0.08),
    ),
    BodyRegionContract(
      id: 'mid-chest-right',
      muscleGroup: 'mid-chest',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.54, 0.28, 0.14, 0.08),
    ),

    BodyRegionContract(
      id: 'lower-chest-left',
      muscleGroup: 'lower-chest',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.33, 0.35, 0.13, 0.06),
    ),
    BodyRegionContract(
      id: 'lower-chest-right',
      muscleGroup: 'lower-chest',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.54, 0.35, 0.13, 0.06),
    ),

    BodyRegionContract(
      id: 'biceps-left',
      muscleGroup: 'biceps',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.18, 0.30, 0.10, 0.14),
    ),
    BodyRegionContract(
      id: 'biceps-right',
      muscleGroup: 'biceps',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.72, 0.30, 0.10, 0.14),
    ),

    BodyRegionContract(
      id: 'forearms-left-front',
      muscleGroup: 'forearms',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.14, 0.43, 0.08, 0.16),
    ),
    BodyRegionContract(
      id: 'forearms-right-front',
      muscleGroup: 'forearms',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.78, 0.43, 0.08, 0.16),
    ),

    BodyRegionContract(
      id: 'abs',
      muscleGroup: 'abs',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.41, 0.42, 0.18, 0.15),
    ),

    BodyRegionContract(
      id: 'obliques-left',
      muscleGroup: 'obliques',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.31, 0.43, 0.08, 0.14),
    ),
    BodyRegionContract(
      id: 'obliques-right',
      muscleGroup: 'obliques',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.61, 0.43, 0.08, 0.14),
    ),

    BodyRegionContract(
      id: 'quads-left',
      muscleGroup: 'quads',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.37, 0.62, 0.11, 0.22),
    ),
    BodyRegionContract(
      id: 'quads-right',
      muscleGroup: 'quads',
      view: BodyView.front,
      normalizedRect: Rect.fromLTWH(0.52, 0.62, 0.11, 0.22),
    ),

    // ==================== BACK VIEW ====================

    BodyRegionContract(
      id: 'rear-delts-left',
      muscleGroup: 'rear-delts',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.27, 0.17, 0.12, 0.08),
    ),
    BodyRegionContract(
      id: 'rear-delts-right',
      muscleGroup: 'rear-delts',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.61, 0.17, 0.12, 0.08),
    ),

    BodyRegionContract(
      id: 'side-delts-left-back',
      muscleGroup: 'side-delts',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.19, 0.19, 0.10, 0.09),
    ),
    BodyRegionContract(
      id: 'side-delts-right-back',
      muscleGroup: 'side-delts',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.71, 0.19, 0.10, 0.09),
    ),

    BodyRegionContract(
      id: 'upper-traps',
      muscleGroup: 'upper-traps',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.39, 0.18, 0.22, 0.06),
    ),
    BodyRegionContract(
      id: 'middle-traps',
      muscleGroup: 'middle-traps',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.36, 0.25, 0.28, 0.08),
    ),
    BodyRegionContract(
      id: 'lower-traps',
      muscleGroup: 'lower-traps',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.40, 0.33, 0.20, 0.08),
    ),

    BodyRegionContract(
      id: 'lats-left',
      muscleGroup: 'lats',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.24, 0.28, 0.14, 0.22),
    ),
    BodyRegionContract(
      id: 'lats-right',
      muscleGroup: 'lats',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.62, 0.28, 0.14, 0.22),
    ),

    BodyRegionContract(
      id: 'triceps-left',
      muscleGroup: 'triceps',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.18, 0.30, 0.10, 0.15),
    ),
    BodyRegionContract(
      id: 'triceps-right',
      muscleGroup: 'triceps',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.72, 0.30, 0.10, 0.15),
    ),

    BodyRegionContract(
      id: 'forearms-left-back',
      muscleGroup: 'forearms',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.13, 0.44, 0.08, 0.16),
    ),
    BodyRegionContract(
      id: 'forearms-right-back',
      muscleGroup: 'forearms',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.79, 0.44, 0.08, 0.16),
    ),

    BodyRegionContract(
      id: 'lower-back',
      muscleGroup: 'lower-back',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.41, 0.45, 0.18, 0.12),
    ),

    BodyRegionContract(
      id: 'glutes-left',
      muscleGroup: 'glutes',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.37, 0.57, 0.12, 0.12),
    ),
    BodyRegionContract(
      id: 'glutes-right',
      muscleGroup: 'glutes',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.51, 0.57, 0.12, 0.12),
    ),

    BodyRegionContract(
      id: 'hamstrings-left',
      muscleGroup: 'hamstrings',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.38, 0.69, 0.10, 0.18),
    ),
    BodyRegionContract(
      id: 'hamstrings-right',
      muscleGroup: 'hamstrings',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.52, 0.69, 0.10, 0.18),
    ),

    BodyRegionContract(
      id: 'calves-left',
      muscleGroup: 'calves',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.39, 0.87, 0.08, 0.10),
    ),
    BodyRegionContract(
      id: 'calves-right',
      muscleGroup: 'calves',
      view: BodyView.back,
      normalizedRect: Rect.fromLTWH(0.53, 0.87, 0.08, 0.10),
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
  List<Object?> get props => [id, muscleGroup, view, normalizedRect];
}