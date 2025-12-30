import 'package:equatable/equatable.dart';
import '../../core/constants/muscle_stimulus_constants.dart';

/// Represents a single set performed in a workout
/// Links to an Exercise entity via exerciseId
class WorkoutSet extends Equatable {
  final String id;
  final String exerciseId; // Reference to Exercise entity
  final int reps;
  final double weight;
  final int intensity; // 0-5 intensity rating (NEW: Phase 9)
  final DateTime date;
  final DateTime createdAt;

  const WorkoutSet({
    required this.id,
    required this.exerciseId,
    required this.reps,
    required this.weight,
    this.intensity = MuscleStimulus.defaultIntensity, // Default to 3 (moderate)
    required this.date,
    required this.createdAt,
  });

  /// Create a copy with optional field updates
  WorkoutSet copyWith({
    String? id,
    String? exerciseId,
    int? reps,
    double? weight,
    int? intensity,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      intensity: intensity ?? this.intensity,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get validated intensity (clamped to 0-5 range)
  int get validatedIntensity => MuscleStimulus.clampIntensity(intensity);

  /// Get intensity label for display
  String get intensityLabel => MuscleStimulus.getIntensityLabel(validatedIntensity);

  @override
  List<Object?> get props => [
        id,
        exerciseId,
        reps,
        weight,
        intensity,
        date,
        createdAt,
      ];
}