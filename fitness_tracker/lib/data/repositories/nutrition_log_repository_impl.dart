import '../../core/constants/database_tables.dart';
import '../../domain/entities/nutrition_log.dart';

/// Data model for NutritionLog with database serialization
/// Extends NutritionLog entity to maintain clean architecture separation
class NutritionLogModel extends NutritionLog {
  const NutritionLogModel({
    required super.id,
    super.mealId,
    required super.mealName,
    super.gramsConsumed,
    required super.proteinGrams,
    required super.carbsGrams,
    required super.fatGrams,
    required super.calories,
    required super.loggedAt,
    required super.createdAt,
  });

  /// Create model from entity
  factory NutritionLogModel.fromEntity(NutritionLog log) {
    return NutritionLogModel(
      id: log.id,
      mealId: log.mealId,
      mealName: log.mealName,
      gramsConsumed: log.gramsConsumed,
      proteinGrams: log.proteinGrams,
      carbsGrams: log.carbsGrams,
      fatGrams: log.fatGrams,
      calories: log.calories,
      loggedAt: log.loggedAt,
      createdAt: log.createdAt,
    );
  }

  /// Create model from database map
  factory NutritionLogModel.fromMap(Map<String, dynamic> map) {
    return NutritionLogModel(
      id: map[DatabaseTables.nutritionLogId] as String,
      mealId: map[DatabaseTables.nutritionLogMealId] as String?,
      mealName: map[DatabaseTables.nutritionLogMealName] as String,
      gramsConsumed: (map[DatabaseTables.nutritionLogGrams] as num?)?.toDouble(),
      proteinGrams: (map[DatabaseTables.nutritionLogProtein] as num).toDouble(),
      carbsGrams: (map[DatabaseTables.nutritionLogCarbs] as num).toDouble(),
      fatGrams: (map[DatabaseTables.nutritionLogFat] as num).toDouble(),
      calories: (map[DatabaseTables.nutritionLogCalories] as num).toDouble(),
      loggedAt: DateTime.parse(map[DatabaseTables.nutritionLogDate] as String),
      createdAt: DateTime.parse(map[DatabaseTables.nutritionLogCreatedAt] as String),
    );
  }

  /// Convert model to database map
  Map<String, dynamic> toMap() {
    return {
      DatabaseTables.nutritionLogId: id,
      DatabaseTables.nutritionLogMealId: mealId,
      DatabaseTables.nutritionLogMealName: mealName,
      DatabaseTables.nutritionLogGrams: gramsConsumed,
      DatabaseTables.nutritionLogProtein: proteinGrams,
      DatabaseTables.nutritionLogCarbs: carbsGrams,
      DatabaseTables.nutritionLogFat: fatGrams,
      DatabaseTables.nutritionLogCalories: calories,
      DatabaseTables.nutritionLogDate: loggedAt.toIso8601String(),
      DatabaseTables.nutritionLogCreatedAt: createdAt.toIso8601String(),
    };
  }

  /// Create model from JSON (for API compatibility)
  factory NutritionLogModel.fromJson(Map<String, dynamic> json) {
    return NutritionLogModel(
      id: json['id'] as String,
      mealId: json['mealId'] as String?,
      mealName: json['mealName'] as String,
      gramsConsumed: (json['gramsConsumed'] as num?)?.toDouble(),
      proteinGrams: (json['proteinGrams'] as num).toDouble(),
      carbsGrams: (json['carbsGrams'] as num).toDouble(),
      fatGrams: (json['fatGrams'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      loggedAt: DateTime.parse(json['loggedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert model to JSON (for API compatibility)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealId': mealId,
      'mealName': mealName,
      'gramsConsumed': gramsConsumed,
      'proteinGrams': proteinGrams,
      'carbsGrams': carbsGrams,
      'fatGrams': fatGrams,
      'calories': calories,
      'loggedAt': loggedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Validate log data
  /// Checks if the log is valid based on type (meal log vs direct macro log)
  void validate() {
    if (isMealLog && !isValidMealLog) {
      throw ArgumentError(
        'Invalid meal log: Must have mealId and grams > 0',
      );
    }
    if (isDirectMacroLog && !isValidDirectMacroLog) {
      throw ArgumentError(
        'Invalid direct macro log: Must have at least one macro > 0',
      );
    }
    if (!hasValidCalories) {
      print(
        'WARNING: Calorie mismatch for log "$mealName": '
        'stated $calories cal, calculated ${calculatedCalories.toStringAsFixed(1)} cal',
      );
    }
  }
}