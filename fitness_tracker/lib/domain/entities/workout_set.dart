import 'package:equatable/equatable.dart';

class WorkoutSet extends Equatable {
  final String id;
  final String muscleGroup;
  final String exerciseName;
  final int reps;
  final double weight;
  final DateTime date;
  final DateTime createdAt;

  const WorkoutSet({
    required this.id,
    required this.muscleGroup,
    required this.exerciseName,
    required this.reps,
    required this.weight,
    required this.date,
    required this.createdAt,
  });

  WorkoutSet copyWith({
    String? id,
    String? muscleGroup,
    String? exerciseName,
    int? reps,
    double? weight,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      exerciseName: exerciseName ?? this.exerciseName,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        muscleGroup,
        exerciseName,
        reps,
        weight,
        date,
        createdAt,
      ];
}