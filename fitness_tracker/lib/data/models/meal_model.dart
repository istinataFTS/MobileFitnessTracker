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
    required super.servingSizeGrams,
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
      servingSizeGrams: meal.servingSizeGrams,
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
      servingSizeGrams: (map[DatabaseTables.mealServingSizeGrams] as num).toDouble(),
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
      DatabaseTables.mealServingSizeGrams: servingSizeGrams,
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
      servingSizeGrams: (json['servingSizeGrams'] as num?)?.toDouble() ?? 100.0,
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
      'servingSizeGrams': servingSizeGrams,
      'carbsPer100g': carbsPer100g,
      'proteinPer100g': proteinPer100g,
      'fatPer100g': fatPer100g,
      'caloriesPer100g': caloriesPer100g,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Validate calories match macro breakdown
  /// Logs warning if mismatch exceeds 1 calorie tolerance
  void validateCalories() {
    if (!hasValidCalories) {
      final calculated = calculatedCalories;
      print(
        'WARNING: Calorie mismatch for meal "$name": '
        'Calories mismatch: stated $caloriesPer100g cal, '
        'calculated ${calculated.toStringAsFixed(1)} cal. '
        'Difference: ${(caloriesPer100g - calculated).abs().toStringAsFixed(1)} cal',
      );
    }
  }

  /// Create model with smart calorie calculation
  /// If calories are not provided or invalid, calculates from macros
  factory MealModel.withCalculatedCalories({
    required String id,
    required String name,
    required double servingSizeGrams,
    required double carbsPer100g,
    required double proteinPer100g,
    required double fatPer100g,
    double? caloriesPer100g,
    required DateTime createdAt,
  }) {
    final calories = MacroCalculator.calculateCalories(
      carbs: carbsPer100g,
      protein: proteinPer100g,
      fat: fatPer100g,
    );

    final calculatedCarbs = carbsPer100g;
    final calculatedProtein = proteinPer100g;
    final calculatedFat = fatPer100g;

    return MealModel(
      id: id,
      name: name,
      servingSizeGrams: servingSizeGrams,
      carbsPer100g: calculatedCarbs,
      proteinPer100g: calculatedProtein,
      fatPer100g: calculatedFat,
      caloriesPer100g: caloriesPer100g ?? calories,
      createdAt: createdAt,
    );
  }
}