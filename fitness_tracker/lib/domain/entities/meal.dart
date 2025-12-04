import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// Represents a meal with nutritional information per 100g
/// 
/// Stores macronutrients (carbs, protein, fat) and total calories.
/// All macro values are per 100g serving.
/// 
/// Calories are calculated as: 4*carbs + 4*protein + 9*fat
/// The entity validates that calories match the macro breakdown.
class Meal extends Equatable {
  final String id;
  final String name;
  
  // Macronutrients per 100g (in grams)
  final double carbsPer100g;
  final double proteinPer100g;
  final double fatPer100g;
  
  // Total calories per 100g
  final double caloriesPer100g;
  
  final DateTime createdAt;

  const Meal({
    required this.id,
    required this.name,
    required this.carbsPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.caloriesPer100g,
    required this.createdAt,
  });

  /// Calculate expected calories from macros
  /// Formula: 4 calories per gram of carbs/protein, 9 calories per gram of fat
  double get calculatedCalories {
    return (carbsPer100g * 4.0) + (proteinPer100g * 4.0) + (fatPer100g * 9.0);
  }

  /// Check if stored calories match calculated calories (within 1 calorie tolerance)
  bool get hasValidCalories {
    return (caloriesPer100g - calculatedCalories).abs() <= 1.0;
  }

  /// Calculate macros and calories for a given weight in grams
  MealNutrition calculateForGrams(double grams) {
    final multiplier = grams / AppConstants.baseServingSizeGrams;
    return MealNutrition(
      carbs: carbsPer100g * multiplier,
      protein: proteinPer100g * multiplier,
      fat: fatPer100g * multiplier,
      calories: caloriesPer100g * multiplier,
      grams: grams,
    );
  }

  Meal copyWith({
    String? id,
    String? name,
    double? carbsPer100g,
    double? proteinPer100g,
    double? fatPer100g,
    double? caloriesPer100g,
    DateTime? createdAt,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        carbsPer100g,
        proteinPer100g,
        fatPer100g,
        caloriesPer100g,
        createdAt,
      ];
}

/// Helper class for calculated nutrition values
class MealNutrition {
  final double carbs;
  final double protein;
  final double fat;
  final double calories;
  final double grams;

  const MealNutrition({
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.calories,
    required this.grams,
  });
}