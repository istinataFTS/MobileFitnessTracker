import 'package:equatable/equatable.dart';

/// Represents a nutrition log entry
/// 
/// Supports two types of logs:
/// 1. Meal-based log: References a Meal entity via mealId, stores grams consumed
/// 2. Direct macro log: Stores macros directly without meal reference
/// 
/// This unified approach uses a single table with optional mealId field:
/// - If mealId is NOT null: it's a meal log (grams must also be set)
/// - If mealId IS null: it's a direct macro log
class NutritionLog extends Equatable {
  final String id;
  
  /// Optional reference to a Meal entity
  /// Null for direct macro logs, non-null for meal logs
  final String? mealId;
  
  /// Name of the meal (for display purposes)
  final String mealName;
  
  /// Grams consumed (only applicable for meal logs)
  /// Should be null for direct macro logs
  final double? gramsConsumed;
  
  // Actual macronutrients logged (in grams)
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  
  // Total calories
  final double calories;
  
  // Date when nutrition was consumed
  final DateTime loggedAt;
  
  // Timestamp when log was created
  final DateTime createdAt;

  const NutritionLog({
    required this.id,
    this.mealId,
    required this.mealName,
    this.gramsConsumed,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.calories,
    required this.loggedAt,
    required this.createdAt,
  });

  /// Check if this is a meal-based log
  bool get isMealLog => mealId != null;

  /// Check if this is a direct macro log
  bool get isDirectMacroLog => mealId == null;

  /// Calculate expected calories from macros
  /// Formula: 4 calories per gram of carbs/protein, 9 calories per gram of fat
  double get calculatedCalories {
    return (carbsGrams * 4.0) + (proteinGrams * 4.0) + (fatGrams * 9.0);
  }

  /// Check if stored calories match calculated calories (within 1 calorie tolerance)
  bool get hasValidCalories {
    return (calories - calculatedCalories).abs() <= 1.0;
  }

  /// Validate meal log constraints
  /// - Must have mealId
  /// - Must have grams > 0
  bool get isValidMealLog {
    return mealId != null && gramsConsumed != null && gramsConsumed! > 0;
  }

  /// Validate direct macro log constraints
  /// - Must NOT have mealId
  /// - Must have at least one macro > 0
  bool get isValidDirectMacroLog {
    return mealId == null && 
           (carbsGrams > 0 || proteinGrams > 0 || fatGrams > 0);
  }

  NutritionLog copyWith({
    String? id,
    String? mealId,
    String? mealName,
    double? gramsConsumed,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
    double? calories,
    DateTime? loggedAt,
    DateTime? createdAt,
  }) {
    return NutritionLog(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      mealName: mealName ?? this.mealName,
      gramsConsumed: gramsConsumed ?? this.gramsConsumed,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      calories: calories ?? this.calories,
      loggedAt: loggedAt ?? this.loggedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        mealId,
        mealName,
        gramsConsumed,
        proteinGrams,
        carbsGrams,
        fatGrams,
        calories,
        loggedAt,
        createdAt,
      ];
}