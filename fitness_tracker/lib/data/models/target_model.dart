import '../../core/constants/database_tables.dart';
import '../../core/enums/sync_status.dart';
import '../../domain/entities/entity_sync_metadata.dart';
import '../../domain/entities/target.dart';

class TargetModel extends Target {
  const TargetModel({
    required super.id,
    super.ownerUserId,
    required super.type,
    required super.categoryKey,
    required super.targetValue,
    required super.unit,
    required super.period,
    required super.createdAt,
    super.updatedAt,
    super.syncMetadata,
  });

  factory TargetModel.fromEntity(Target target) {
    return TargetModel(
      id: target.id,
      ownerUserId: target.ownerUserId,
      type: target.type,
      categoryKey: target.categoryKey,
      targetValue: target.targetValue,
      unit: target.unit,
      period: target.period,
      createdAt: target.createdAt,
      updatedAt: target.updatedAt,
      syncMetadata: target.syncMetadata,
    );
  }

  factory TargetModel.fromMap(Map<String, dynamic> map) {
    final createdAt = DateTime.parse(
      map[DatabaseTables.targetCreatedAt] as String,
    );
    final updatedAtRaw = map[DatabaseTables.targetUpdatedAt] as String?;

    return TargetModel(
      id: map[DatabaseTables.targetId] as String,
      ownerUserId: map['owner_user_id'] as String?,
      type: _targetTypeFromString(
        map[DatabaseTables.targetType] as String,
      ),
      categoryKey: map[DatabaseTables.targetCategoryKey] as String,
      targetValue: (map[DatabaseTables.targetValue] as num).toDouble(),
      unit: map[DatabaseTables.targetUnit] as String,
      period: _targetPeriodFromString(
        map[DatabaseTables.targetPeriod] as String,
      ),
      createdAt: createdAt,
      updatedAt:
          updatedAtRaw == null ? createdAt : DateTime.parse(updatedAtRaw),
      syncMetadata: EntitySyncMetadata(
        serverId: map[DatabaseTables.targetServerId] as String?,
        status: _syncStatusFromStorage(
          map[DatabaseTables.targetSyncStatus] as String?,
        ),
        lastSyncedAt: _parseNullableDateTime(
          map[DatabaseTables.targetLastSyncedAt] as String?,
        ),
        lastSyncError: map[DatabaseTables.targetLastSyncError] as String?,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DatabaseTables.targetId: id,
      'owner_user_id': ownerUserId,
      DatabaseTables.targetType: _targetTypeToString(type),
      DatabaseTables.targetCategoryKey: categoryKey,
      DatabaseTables.targetValue: targetValue,
      DatabaseTables.targetUnit: unit,
      DatabaseTables.targetPeriod: _targetPeriodToString(period),
      DatabaseTables.targetCreatedAt: createdAt.toIso8601String(),
      DatabaseTables.targetUpdatedAt: updatedAt.toIso8601String(),
      DatabaseTables.targetServerId: syncMetadata.serverId,
      DatabaseTables.targetSyncStatus: syncMetadata.status.name,
      DatabaseTables.targetLastSyncedAt:
          syncMetadata.lastSyncedAt?.toIso8601String(),
      DatabaseTables.targetLastSyncError: syncMetadata.lastSyncError,
    };
  }

  factory TargetModel.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt'] as String);
    final updatedAtRaw = json['updatedAt'] as String?;

    return TargetModel(
      id: json['id'] as String,
      ownerUserId: json['ownerUserId'] as String?,
      type: _targetTypeFromString(json['type'] as String),
      categoryKey: json['categoryKey'] as String,
      targetValue: (json['targetValue'] as num).toDouble(),
      unit: json['unit'] as String,
      period: _targetPeriodFromString(json['period'] as String),
      createdAt: createdAt,
      updatedAt:
          updatedAtRaw == null ? createdAt : DateTime.parse(updatedAtRaw),
      syncMetadata: EntitySyncMetadata(
        serverId: json['serverId'] as String?,
        status: _syncStatusFromStorage(json['syncStatus'] as String?),
        lastSyncedAt: _parseNullableDateTime(json['lastSyncedAt'] as String?),
        lastSyncError: json['lastSyncError'] as String?,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerUserId': ownerUserId,
      'type': _targetTypeToString(type),
      'categoryKey': categoryKey,
      'targetValue': targetValue,
      'unit': unit,
      'period': _targetPeriodToString(period),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'serverId': syncMetadata.serverId,
      'syncStatus': syncMetadata.status.name,
      'lastSyncedAt': syncMetadata.lastSyncedAt?.toIso8601String(),
      'lastSyncError': syncMetadata.lastSyncError,
    };
  }

  static DateTime? _parseNullableDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.parse(value);
  }

  static SyncStatus _syncStatusFromStorage(String? value) {
    return SyncStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SyncStatus.localOnly,
    );
  }

  static TargetType _targetTypeFromString(String value) {
    switch (value) {
      case 'muscle_sets':
        return TargetType.muscleSets;
      case 'macro':
        return TargetType.macro;
      default:
        throw ArgumentError('Unsupported target type: $value');
    }
  }

  static String _targetTypeToString(TargetType type) {
    switch (type) {
      case TargetType.muscleSets:
        return 'muscle_sets';
      case TargetType.macro:
        return 'macro';
    }
  }

  static TargetPeriod _targetPeriodFromString(String value) {
    switch (value) {
      case 'daily':
        return TargetPeriod.daily;
      case 'weekly':
        return TargetPeriod.weekly;
      default:
        throw ArgumentError('Unsupported target period: $value');
    }
  }

  static String _targetPeriodToString(TargetPeriod period) {
    switch (period) {
      case TargetPeriod.daily:
        return 'daily';
      case TargetPeriod.weekly:
        return 'weekly';
    }
  }
}