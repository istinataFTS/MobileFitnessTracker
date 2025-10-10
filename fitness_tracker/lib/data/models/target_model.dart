import '../../core/constants/database_tables.dart';
import '../../domain/entities/target.dart';

/// Data model for Target with database serialization
class TargetModel extends Target {
  const TargetModel({
    required super.id,
    required super.muscleGroup,
    required super.weeklyGoal,
    required super.createdAt,
  });

  /// Create model from entity
  factory TargetModel.fromEntity(Target target) {
    return TargetModel(
      id: target.id,
      muscleGroup: target.muscleGroup,
      weeklyGoal: target.weeklyGoal,
      createdAt: target.createdAt,
    );
  }

  /// Create model from database map
  factory TargetModel.fromMap(Map<String, dynamic> map) {
    return TargetModel(
      id: map[DatabaseTables.targetId] as String,
      muscleGroup: map[DatabaseTables.targetMuscleGroup] as String,
      weeklyGoal: map[DatabaseTables.targetWeeklyGoal] as int,
      createdAt: DateTime.parse(map[DatabaseTables.targetCreatedAt] as String),
    );
  }

  /// Convert model to database map
  Map<String, dynamic> toMap() {
    return {
      DatabaseTables.targetId: id,
      DatabaseTables.targetMuscleGroup: muscleGroup,
      DatabaseTables.targetWeeklyGoal: weeklyGoal,
      DatabaseTables.targetCreatedAt: createdAt.toIso8601String(),
    };
  }

  /// Create model from JSON (for API compatibility)
  factory TargetModel.fromJson(Map<String, dynamic> json) {
    return TargetModel(
      id: json['id'] as String,
      muscleGroup: json['muscleGroup'] as String,
      weeklyGoal: json['weeklyGoal'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert model to JSON (for API compatibility)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'muscleGroup': muscleGroup,
      'weeklyGoal': weeklyGoal,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}