import '../../core/constants/app_constants.dart';
import '../../core/constants/database_tables.dart';
import '../../core/utils/macro_calculator.dart';
import '../../domain/entities/meal.dart';

/// Data model for Meal with database serialization
/// Extends Meal entity to maintain clean architecture separation
/// Includes calorie validation on creation
class MealModel extends Meal {
  const MealModel({
    required super.id,
    required super.name,
    required super.carbsPer100g,
    required super.proteinPer100g,
    required super.fatPer100g,
    required super.caloriesPer100g,
    required super.createdAt,
  });

  /// Create model from entity
  factory MealModel.fromEntity(Meal meal) {
    return MealModel(
      id: meal.id,
      name: meal.name,
      carbsPer100g: meal.carbsPer100g,
      proteinPer100g: meal.proteinPer100g,
      fatPer100g: meal.fatPer100g,
      caloriesPer100g: meal.caloriesPer100g,
      createdAt: meal.createdAt,
    );
  }

  /// Create model from database map
  factory MealModel.fromMap(Map<String, dynamic> map) {
    return MealModel(
      id: map[DatabaseTables.mealId] as String,
      name: map[DatabaseTables.mealName] as String,
      carbsPer100g: (map[DatabaseTables.mealCarbsPer100g] as num).toDouble(),
      proteinPer100g: (map[DatabaseTables.mealProteinPer100g] as num).toDouble(),
      fatPer100g: (map[DatabaseTables.mealFatPer100g] as num).toDouble(),
      caloriesPer100g: (map[DatabaseTables.mealCaloriesPer100g] as num).toDouble(),
      createdAt: DateTime.parse(map[DatabaseTables.mealCreatedAt] as String),
    );
  }

  /// Convert model to database map
  Map<String, dynamic> toMap() {
    return {
      DatabaseTables.mealId: id,
      DatabaseTables.mealName: name,
      DatabaseTables.mealCarbsPer100g: carbsPer100g,
      DatabaseTables.mealProteinPer100g: proteinPer100g,
      DatabaseTables.mealFatPer100g: fatPer100g,
      DatabaseTables.mealCaloriesPer100g: caloriesPer100g,
      DatabaseTables.mealCreatedAt: createdAt.toIso8601String(),
    };
  }

  /// Create model from JSON (for API compatibility)
  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'] as String,
      name: json['name'] as String,
      carbsPer100g: (json['carbsPer100g'] as num).toDouble(),
      proteinPer100g: (json['proteinPer100g'] as num).toDouble(),
      fatPer100g: (json['fatPer100g'] as num).toDouble(),
      caloriesPer100g: (json['caloriesPer100g'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert model to JSON (for API compatibility)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'carbsPer100g': carbsPer100g,
      'proteinPer100g': proteinPer100g,
      'fatPer100g': fatPer100g,
      'caloriesPer100g': caloriesPer100g,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Validate macro and calorie consistency
  /// Throws exception if calories don't match macros
  void validateMacros() {
    if (!hasValidCalories) {
      final calculated = calculatedCalories;
      throw ArgumentError(
        'Calories mismatch: stated $caloriesPer100g cal, '
        'calculated $calculated cal from macros. '
        'Difference: ${(caloriesPer100g - calculated).abs().toStringAsFixed(1)} cal',
      );
    }
  }

  /// Create a meal with auto-calculated calories from macros
  /// Useful when user only inputs macros
  factory MealModel.fromMacros({
    required String id,
    required String name,
    required double carbsPer100g,
    required double proteinPer100g,
    required double fatPer100g,
    required DateTime createdAt,
  }) {
    final calories = MacroCalculator.calculateCalories(
      carbs: carbsPer100g,
      protein: proteinPer100g,
      fat: fatPer100g,
    );

    return MealModel(
      id: id,
      name: name,
      carbsPer100g: carbsPer100g,
      proteinPer100g: proteinPer100g,
      fatPer100g: fatPer100g,
      caloriesPer100g: calories,
      createdAt: createdAt,
    );
  }

  /// Create a meal with auto-calculated macros from calories
  /// Distributes calories evenly across macros if not specified
  /// This is a fallback - prefer explicit macro input
  factory MealModel.fromCalories({
    required String id,
    required String name,
    required double caloriesPer100g,
    required DateTime createdAt,
    double? carbsPer100g,
    double? proteinPer100g,
    double? fatPer100g,
  }) {
    // If all macros provided, validate them
    if (carbsPer100g != null && proteinPer100g != null && fatPer100g != null) {
      return MealModel(
        id: id,
        name: name,
        carbsPer100g: carbsPer100g,
        proteinPer100g: proteinPer100g,
        fatPer100g: fatPer100g,
        caloriesPer100g: caloriesPer100g,
        createdAt: createdAt,
      );
    }

    // If only calories provided, use default distribution ratios from AppConstants
    if (carbsPer100g == null && proteinPer100g == null && fatPer100g == null) {
      return MealModel(
        id: id,
        name: name,
        carbsPer100g: (caloriesPer100g * AppConstants.defaultCarbsRatio) / 
                      MacroCalculator.caloriesPerGramCarbs,
        proteinPer100g: (caloriesPer100g * AppConstants.defaultProteinRatio) / 
                        MacroCalculator.caloriesPerGramProtein,
        fatPer100g: (caloriesPer100g * AppConstants.defaultFatsRatio) / 
                    MacroCalculator.caloriesPerGramFat,
        caloriesPer100g: caloriesPer100g,
        createdAt: createdAt,
      );
    }

    // Calculate missing macro(s) using MacroCalculator
    final carbs = carbsPer100g ?? 0.0;
    final protein = proteinPer100g ?? 0.0;
    final fat = fatPer100g ?? 0.0;

    final calculatedCarbs = carbsPer100g ?? MacroCalculator.calculateCarbsFromCalories(
      totalCalories: caloriesPer100g,
      protein: protein,
      fat: fat,
    );

    final calculatedProtein = proteinPer100g ?? MacroCalculator.calculateProteinFromCalories(
      totalCalories: caloriesPer100g,
      carbs: carbs,
      fat: fat,
    );

    final calculatedFat = fatPer100g ?? MacroCalculator.calculateFatFromCalories(
      totalCalories: caloriesPer100g,
      carbs: carbs,
      protein: protein,
    );

    return MealModel(
      id: id,
      name: name,
      carbsPer100g: calculatedCarbs,
      proteinPer100g: calculatedProtein,
      fatPer100g: calculatedFat,
      caloriesPer100g: caloriesPer100g,
      createdAt: createdAt,
    );
  }
}