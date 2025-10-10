import 'package:equatable/equatable.dart';

/// Represents a single set performed in a workout
/// Links to an Exercise entity via exerciseId
class WorkoutSet extends Equatable {
  final String id;
  final String exerciseId; // Reference to Exercise entity
  final int reps;
  final double weight;
  final DateTime date;
  final DateTime createdAt;

  const WorkoutSet({
    required this.id,
    required this.exerciseId,
    required this.reps,
    required this.weight,
    required this.date,
    required this.createdAt,
  });

  WorkoutSet copyWith({
    String? id,
    String? exerciseId,
    int? reps,
    double? weight,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        exerciseId,
        reps,
        weight,
        date,
        createdAt,
      ];
}