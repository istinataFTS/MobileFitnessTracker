import '../../core/constants/database_tables.dart';
import '../../core/utils/macro_calculator.dart';
import '../../domain/entities/meal.dart';

/// Data model for Meal entity with database serialization
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

  /// Create MealModel from Meal entity
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

  /// Create MealModel from database map
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

  /// Convert MealModel to database map
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

  /// Convert to JSON for serialization (if needed for API or caching)
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

  /// Validate calorie accuracy
  /// Returns true if stated calories match calculated calories within tolerance
  bool get hasValidCalories {
    final calculated = calculatedCalories;
    const tolerance = 5.0; // Allow 5 calorie difference
    return (caloriesPer100g - calculated).abs() <= tolerance;
  }

  /// Calculate calories from macros using 4-4-9 rule
  double get calculatedCalories {
    return MacroCalculator.calculateCalories(
      carbs: carbsPer100g,
      protein: proteinPer100g,
      fat: fatPer100g,
    );
  }

  /// Log calorie discrepancy warning if validation fails
  void validateAndLogCalories() {
    if (!hasValidCalories) {
      final calculated = calculatedCalories;
      print('⚠️ Meal "$name" calorie mismatch:');
      print(
        'Calories mismatch: stated $caloriesPer100g cal, '
        'calculated ${calculated.toStringAsFixed(1)} cal from macros',
      );
      print(
        'Difference: ${(caloriesPer100g - calculated).abs().toStringAsFixed(1)} cal',
      );
    }
  }

  /// Create a copy with updated fields
  MealModel copyWith({
    String? id,
    String? name,
    double? carbsPer100g,
    double? proteinPer100g,
    double? fatPer100g,
    double? caloriesPer100g,
    DateTime? createdAt,
  }) {
    return MealModel(
      id: id ?? this.id,
      name: name ?? this.name,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Create MealModel with auto-calculated calories from macros
  /// If caloriesPer100g is null, calculates from macros
  /// If carbsPer100g is null, calculates from remaining calories after protein and fat
  /// If proteinPer100g is null, calculates from remaining calories after carbs and fat
  /// If fatPer100g is null, calculates from remaining calories after carbs and protein
  factory MealModel.withCalculatedMacros({
    required String id,
    required String name,
    double? carbsPer100g,
    double? proteinPer100g,
    double? fatPer100g,
    double? caloriesPer100g,
    DateTime? createdAt,
  }) {
    // If calories provided but a macro is missing, calculate the missing macro
    if (caloriesPer100g != null) {
      if (carbsPer100g == null && proteinPer100g != null && fatPer100g != null) {
        final calculatedCarbs = MacroCalculator.calculateCarbsFromCalories(
          caloriesPer100g,
          proteinPer100g,
          fatPer100g,
        );
        carbsPer100g = calculatedCarbs;
      }

      if (proteinPer100g == null && carbsPer100g != null && fatPer100g != null) {
        final calculatedProtein = MacroCalculator.calculateProteinFromCalories(
          caloriesPer100g,
          carbsPer100g,
          fatPer100g,
        );
        proteinPer100g = calculatedProtein;
      }

      if (fatPer100g == null && carbsPer100g != null && proteinPer100g != null) {
        final calculatedFat = MacroCalculator.calculateFatFromCalories(
          caloriesPer100g,
          carbsPer100g,
          proteinPer100g,
        );
        fatPer100g = calculatedFat;
      }
    }

    // Calculate calories from macros if not provided
    final finalCalories = caloriesPer100g ??
        MacroCalculator.calculateCalories(
          carbs: carbsPer100g ?? 0,
          protein: proteinPer100g ?? 0,
          fat: fatPer100g ?? 0,
        );

    return MealModel(
      id: id,
      name: name,
      carbsPer100g: carbsPer100g ?? 0,
      proteinPer100g: proteinPer100g ?? 0,
      fatPer100g: fatPer100g ?? 0,
      caloriesPer100g: finalCalories,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}