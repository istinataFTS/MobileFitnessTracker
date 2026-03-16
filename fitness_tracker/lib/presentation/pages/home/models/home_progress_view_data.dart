import 'package:equatable/equatable.dart';

enum HomeProgressTone {
  muted,
  primary,
  warning,
  success,
}

class HomeProgressStatViewData extends Equatable {
  final String value;
  final String label;
  final HomeProgressTone tone;

  const HomeProgressStatViewData({
    required this.value,
    required this.label,
    required this.tone,
  });

  @override
  List<Object?> get props => [
        value,
        label,
        tone,
      ];
}

class HomeProgressCalloutViewData extends Equatable {
  final String message;
  final HomeProgressTone tone;

  const HomeProgressCalloutViewData({
    required this.message,
    required this.tone,
  });

  @override
  List<Object?> get props => [
        message,
        tone,
      ];
}

class HomeProgressStatsViewData extends Equatable {
  final HomeProgressStatViewData totalSetsStat;
  final HomeProgressStatViewData targetStat;
  final HomeProgressStatViewData trainedMusclesStat;

  const HomeProgressStatsViewData({
    required this.totalSetsStat,
    required this.targetStat,
    required this.trainedMusclesStat,
  });

  @override
  List<Object?> get props => [
        totalSetsStat,
        targetStat,
        trainedMusclesStat,
      ];
}

class DetailedHomeProgressStatsViewData extends Equatable {
  final double progressValue;
  final String progressLabel;
  final HomeProgressTone progressTone;
  final HomeProgressStatViewData completedSetsStat;
  final HomeProgressStatViewData trainedMusclesStat;
  final HomeProgressCalloutViewData targetCallout;

  const DetailedHomeProgressStatsViewData({
    required this.progressValue,
    required this.progressLabel,
    required this.progressTone,
    required this.completedSetsStat,
    required this.trainedMusclesStat,
    required this.targetCallout,
  });

  @override
  List<Object?> get props => [
        progressValue,
        progressLabel,
        progressTone,
        completedSetsStat,
        trainedMusclesStat,
        targetCallout,
      ];
}

enum MuscleGroupProgressTone {
  primary,
  success,
}

class MuscleGroupProgressItemViewData extends Equatable {
  final String categoryKey;
  final String title;
  final String progressLabel;
  final String percentageLabel;
  final double progressValue;
  final bool showCompleteBadge;
  final MuscleGroupProgressTone tone;

  const MuscleGroupProgressItemViewData({
    required this.categoryKey,
    required this.title,
    required this.progressLabel,
    required this.percentageLabel,
    required this.progressValue,
    required this.showCompleteBadge,
    required this.tone,
  });

  @override
  List<Object?> get props => [
        categoryKey,
        title,
        progressLabel,
        percentageLabel,
        progressValue,
        showCompleteBadge,
        tone,
      ];
}