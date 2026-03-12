import '../../core/constants/database_tables.dart';
import '../../domain/entities/target.dart';

class TargetModel extends Target {
  const TargetModel({
    required super.id,
    required super.type,
    required super.categoryKey,
    required super.targetValue,
    required super.unit,
    required super.period,
    required super.createdAt,
  });

  factory TargetModel.fromEntity(Target target) {
    return TargetModel(
      id: target.id,
      type: target.type,
      categoryKey: target.categoryKey,
      targetValue: target.targetValue,
      unit: target.unit,
      period: target.period,
      createdAt: target.createdAt,
    );
  }

  factory TargetModel.fromMap(Map<String, dynamic> map) {
    return TargetModel(
      id: map[DatabaseTables.targetId] as String,
      type: _targetTypeFromString(
        map[DatabaseTables.targetType] as String,
      ),
      categoryKey: map[DatabaseTables.targetCategoryKey] as String,
      targetValue: (map[DatabaseTables.targetValue] as num).toDouble(),
      unit: map[DatabaseTables.targetUnit] as String,
      period: _targetPeriodFromString(
        map[DatabaseTables.targetPeriod] as String,
      ),
      createdAt: DateTime.parse(
        map[DatabaseTables.targetCreatedAt] as String,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DatabaseTables.targetId: id,
      DatabaseTables.targetType: _targetTypeToString(type),
      DatabaseTables.targetCategoryKey: categoryKey,
      DatabaseTables.targetValue: targetValue,
      DatabaseTables.targetUnit: unit,
      DatabaseTables.targetPeriod: _targetPeriodToString(period),
      DatabaseTables.targetCreatedAt: createdAt.toIso8601String(),
    };
  }

  factory TargetModel.fromJson(Map<String, dynamic> json) {
    return TargetModel(
      id: json['id'] as String,
      type: _targetTypeFromString(json['type'] as String),
      categoryKey: json['categoryKey'] as String,
      targetValue: (json['targetValue'] as num).toDouble(),
      unit: json['unit'] as String,
      period: _targetPeriodFromString(json['period'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': _targetTypeToString(type),
      'categoryKey': categoryKey,
      'targetValue': targetValue,
      'unit': unit,
      'period': _targetPeriodToString(period),
      'createdAt': createdAt.toIso8601String(),
    };
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