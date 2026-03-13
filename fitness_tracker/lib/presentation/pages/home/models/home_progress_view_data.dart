import 'package:equatable/equatable.dart';

class HomeProgressStatsViewData extends Equatable {
  final int totalSets;
  final int remainingTarget;
  final int trainedMuscles;
  final bool hasTarget;

  const HomeProgressStatsViewData({
    required this.totalSets,
    required this.remainingTarget,
    required this.trainedMuscles,
    required this.hasTarget,
  });

  @override
  List<Object?> get props => [
        totalSets,
        remainingTarget,
        trainedMuscles,
        hasTarget,
      ];
}