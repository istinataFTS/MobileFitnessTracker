import 'package:json_annotation/json_annotation.dart';
import '../../core/constants/database_tables.dart';
import '../../domain/entities/target.dart';

part 'target_model.g.dart';

@JsonSerializable()
class TargetModel extends Target {
  const TargetModel({
    required super.id,
    required super.muscleGroup,
    required super.weeklyGoal,
    required super.createdAt,
  });

  factory TargetModel.fromJson(Map<String, dynamic> json) =>
      _$TargetModelFromJson(json);

  Map<String, dynamic> toJson() => _$TargetModelToJson(this);

  factory TargetModel.fromEntity(Target target) {
    return TargetModel(
      id: target.id,
      muscleGroup: target.muscleGroup,
      weeklyGoal: target.weeklyGoal,
      createdAt: target.createdAt,
    );
  }

  factory TargetModel.fromMap(Map<String, dynamic> map) {
    return TargetModel(
      id: map[DatabaseTables.targetId] as String,
      muscleGroup: map[DatabaseTables.targetMuscleGroup] as String,
      weeklyGoal: map[DatabaseTables.targetWeeklyGoal] as int,
      createdAt: DateTime.parse(map[DatabaseTables.targetCreatedAt] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DatabaseTables.targetId: id,
      DatabaseTables.targetMuscleGroup: muscleGroup,
      DatabaseTables.targetWeeklyGoal: weeklyGoal,
      DatabaseTables.targetCreatedAt: createdAt.toIso8601String(),
    };
  }
}