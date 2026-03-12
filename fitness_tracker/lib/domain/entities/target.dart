import 'package:equatable/equatable.dart';

enum TargetType {
  muscleSets,
  macro,
}

enum TargetPeriod {
  daily,
  weekly,
}

enum MacroTargetType {
  protein,
  carbs,
  fats,
}

class Target extends Equatable {
  final String id;
  final TargetType type;
  final String categoryKey;
  final double targetValue;
  final String unit;
  final TargetPeriod period;
  final DateTime createdAt;

  const Target({
    required this.id,
    required this.type,
    required this.categoryKey,
    required this.targetValue,
    required this.unit,
    required this.period,
    required this.createdAt,
  });

  bool get isMuscleTarget => type == TargetType.muscleSets;
  bool get isMacroTarget => type == TargetType.macro;

  bool get isWeeklyMuscleTarget =>
      type == TargetType.muscleSets && period == TargetPeriod.weekly;

  bool get isDailyMacroTarget =>
      type == TargetType.macro && period == TargetPeriod.daily;

  String get muscleGroup => categoryKey;

  int get weeklyGoal => targetValue.round();

  double get goalValue => targetValue;

  Target copyWith({
    String? id,
    TargetType? type,
    String? categoryKey,
    double? targetValue,
    String? unit,
    TargetPeriod? period,
    DateTime? createdAt,
  }) {
    return Target(
      id: id ?? this.id,
      type: type ?? this.type,
      categoryKey: categoryKey ?? this.categoryKey,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        categoryKey,
        targetValue,
        unit,
        period,
        createdAt,
      ];
}