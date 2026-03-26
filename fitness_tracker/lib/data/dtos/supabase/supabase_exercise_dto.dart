import '../../../core/enums/sync_status.dart';
import '../../../domain/entities/entity_sync_metadata.dart';
import '../../../domain/entities/exercise.dart';

class SupabaseExerciseDto {
  final String id;
  final String userId;
  final String name;
  final List<String> muscleGroups;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupabaseExerciseDto({
    required this.id,
    required this.userId,
    required this.name,
    required this.muscleGroups,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupabaseExerciseDto.fromMap(Map<String, dynamic> map) {
    return SupabaseExerciseDto(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      muscleGroups: (map['muscle_groups'] as List<dynamic>)
          .map((dynamic value) => value.toString())
          .toList(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory SupabaseExerciseDto.fromEntity(Exercise entity) {
    final ownerUserId = entity.ownerUserId;
    if (ownerUserId == null || ownerUserId.isEmpty) {
      throw ArgumentError(
        'Exercise must have ownerUserId before conversion to Supabase DTO.',
      );
    }

    return SupabaseExerciseDto(
      id: entity.syncMetadata.serverId ?? entity.id,
      userId: ownerUserId,
      name: entity.name,
      muscleGroups: entity.muscleGroups,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Exercise toEntity({
    required String localId,
    required EntitySyncMetadata syncMetadata,
  }) {
    return Exercise(
      id: localId,
      ownerUserId: userId,
      name: name,
      muscleGroups: muscleGroups,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncMetadata: syncMetadata,
    );
  }

  EntitySyncMetadata toSyncedMetadata() {
    return EntitySyncMetadata(
      serverId: id,
      status: SyncStatus.synced,
      lastSyncedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'muscle_groups': muscleGroups,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
