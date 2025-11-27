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
  
  /// Grams consumed (only applicable for meal logs)
  /// Should be null for direct macro logs
  final double? grams;
  
  // Actual macronutrients logged (in grams)
  final double carbs;
  final double protein;
  final double fat;
  
  // Total calories
  final double calories;
  
  // Date when nutrition was consumed
  final DateTime date;
  
  // Timestamp when log was created
  final DateTime createdAt;

  const NutritionLog({
    required this.id,
    this.mealId,
    this.grams,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.calories,
    required this.date,
    required this.createdAt,
  });

  /// Check if this is a meal-based log
  bool get isMealLog => mealId != null;

  /// Check if this is a direct macro log
  bool get isDirectMacroLog => mealId == null;

  /// Calculate expected calories from macros
  /// Formula: 4 calories per gram of carbs/protein, 9 calories per gram of fat
  double get calculatedCalories {
    return (carbs * 4.0) + (protein * 4.0) + (fat * 9.0);
  }

  /// Check if stored calories match calculated calories (within 1 calorie tolerance)
  bool get hasValidCalories {
    return (calories - calculatedCalories).abs() <= 1.0;
  }

  /// Validate meal log constraints
  /// - Must have mealId
  /// - Must have grams > 0
  bool get isValidMealLog {
    return mealId != null && grams != null && grams! > 0;
  }

  /// Validate direct macro log constraints
  /// - Must NOT have mealId
  /// - Should NOT have grams (or grams should be null)
  /// - Must have at least one macro > 0
  bool get isValidDirectMacroLog {
    return mealId == null && 
           (carbs > 0 || protein > 0 || fat > 0);
  }

  NutritionLog copyWith({
    String? id,
    String? mealId,
    double? grams,
    double? carbs,
    double? protein,
    double? fat,
    double? calories,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return NutritionLog(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      grams: grams ?? this.grams,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      calories: calories ?? this.calories,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        mealId,
        grams,
        carbs,
        protein,
        fat,
        calories,
        date,
        createdAt,
      ];
}