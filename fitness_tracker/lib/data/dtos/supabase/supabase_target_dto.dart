import '../../../core/enums/sync_status.dart';
import '../../../domain/entities/entity_sync_metadata.dart';
import '../../../domain/entities/target.dart';

class SupabaseTargetDto {
  final String id;
  final String userId;
  final String type;
  final String categoryKey;
  final double targetValue;
  final String unit;
  final String period;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupabaseTargetDto({
    required this.id,
    required this.userId,
    required this.type,
    required this.categoryKey,
    required this.targetValue,
    required this.unit,
    required this.period,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupabaseTargetDto.fromMap(Map<String, dynamic> map) {
    return SupabaseTargetDto(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      categoryKey: map['category_key'] as String,
      targetValue: (map['target_value'] as num).toDouble(),
      unit: map['unit'] as String,
      period: map['period'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory SupabaseTargetDto.fromEntity(Target entity) {
    final ownerUserId = entity.ownerUserId;
    if (ownerUserId == null || ownerUserId.isEmpty) {
      throw ArgumentError(
        'Target must have ownerUserId before conversion to Supabase DTO.',
      );
    }

    return SupabaseTargetDto(
      id: entity.syncMetadata.serverId ?? entity.id,
      userId: ownerUserId,
      type: _targetTypeToStorage(entity.type),
      categoryKey: entity.categoryKey,
      targetValue: entity.targetValue,
      unit: entity.unit,
      period: _targetPeriodToStorage(entity.period),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Target toEntity({
    required String localId,
    required EntitySyncMetadata syncMetadata,
  }) {
    return Target(
      id: localId,
      ownerUserId: userId,
      type: _targetTypeFromStorage(type),
      categoryKey: categoryKey,
      targetValue: targetValue,
      unit: unit,
      period: _targetPeriodFromStorage(period),
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
      'type': type,
      'category_key': categoryKey,
      'target_value': targetValue,
      'unit': unit,
      'period': period,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static String _targetTypeToStorage(TargetType value) {
    switch (value) {
      case TargetType.muscleSets:
        return 'muscle_sets';
      case TargetType.macro:
        return 'macro';
    }
  }

  static TargetType _targetTypeFromStorage(String value) {
    switch (value) {
      case 'muscle_sets':
        return TargetType.muscleSets;
      case 'macro':
        return TargetType.macro;
      default:
        throw ArgumentError('Unsupported target type: $value');
    }
  }

  static String _targetPeriodToStorage(TargetPeriod value) {
    switch (value) {
      case TargetPeriod.daily:
        return 'daily';
      case TargetPeriod.weekly:
        return 'weekly';
    }
  }

  static TargetPeriod _targetPeriodFromStorage(String value) {
    switch (value) {
      case 'daily':
        return TargetPeriod.daily;
      case 'weekly':
        return TargetPeriod.weekly;
      default:
        throw ArgumentError('Unsupported target period: $value');
    }
  }
}