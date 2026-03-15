import 'package:equatable/equatable.dart';

import '../../core/constants/muscle_stimulus_constants.dart';
import 'entity_sync_metadata.dart';

class WorkoutSet extends Equatable {
  final String id;
  final String exerciseId;
  final int reps;
  final double weight;
  final int intensity;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final EntitySyncMetadata syncMetadata;

  const WorkoutSet({
    required this.id,
    required this.exerciseId,
    required this.reps,
    required this.weight,
    this.intensity = MuscleStimulus.defaultIntensity,
    required this.date,
    required this.createdAt,
    DateTime? updatedAt,
    EntitySyncMetadata? syncMetadata,
  })  : updatedAt = updatedAt ?? createdAt,
        syncMetadata = syncMetadata ?? const EntitySyncMetadata();

  WorkoutSet copyWith({
    String? id,
    String? exerciseId,
    int? reps,
    double? weight,
    int? intensity,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    EntitySyncMetadata? syncMetadata,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      intensity: intensity ?? this.intensity,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncMetadata: syncMetadata ?? this.syncMetadata,
    );
  }

  int get validatedIntensity => MuscleStimulus.clampIntensity(intensity);

  String get intensityLabel =>
      MuscleStimulus.getIntensityLabel(validatedIntensity);

  @override
  List<Object?> get props => [
        id,
        exerciseId,
        reps,
        weight,
        intensity,
        date,
        createdAt,
        updatedAt,
        syncMetadata,
      ];
}