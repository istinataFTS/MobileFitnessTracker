import 'package:json_annotation/json_annotation.dart';
import '../../core/constants/database_tables.dart';
import '../../domain/entities/workout_set.dart';

part 'workout_set_model.g.dart';

@JsonSerializable()
class WorkoutSetModel extends WorkoutSet {
  const WorkoutSetModel({
    required super.id,
    required super.muscleGroup,
    required super.exerciseName,
    required super.reps,
    required super.weight,
    required super.date,
    required super.createdAt,
  });

  factory WorkoutSetModel.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSetModelFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutSetModelToJson(this);

  factory WorkoutSetModel.fromEntity(WorkoutSet set) {
    return WorkoutSetModel(
      id: set.id,
      muscleGroup: set.muscleGroup,
      exerciseName: set.exerciseName,
      reps: set.reps,
      weight: set.weight,
      date: set.date,
      createdAt: set.createdAt,
    );
  }

  factory WorkoutSetModel.fromMap(Map<String, dynamic> map) {
    return WorkoutSetModel(
      id: map[DatabaseTables.setId] as String,
      muscleGroup: map[DatabaseTables.setMuscleGroup] as String,
      exerciseName: map[DatabaseTables.setExerciseName] as String,
      reps: map[DatabaseTables.setReps] as int,
      weight: (map[DatabaseTables.setWeight] as num).toDouble(),
      date: DateTime.parse(map[DatabaseTables.setDate] as String),
      createdAt: DateTime.parse(map[DatabaseTables.setCreatedAt] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DatabaseTables.setId: id,
      DatabaseTables.setMuscleGroup: muscleGroup,
      DatabaseTables.setExerciseName: exerciseName,
      DatabaseTables.setReps: reps,
      DatabaseTables.setWeight: weight,
      DatabaseTables.setDate: date.toIso8601String(),
      DatabaseTables.setCreatedAt: createdAt.toIso8601String(),
    };
  }
}