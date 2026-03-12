import '../../core/constants/database_tables.dart';
import '../../core/utils/macro_calculator.dart';
import '../../domain/entities/meal.dart';

/// Data model for Meal entity with database serialization
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

  /// Create MealModel from Meal entity
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

  /// Create MealModel from database map
  factory MealModel.fromMap(Map<String, dynamic> map) {
    return MealModel(
      id: map[DatabaseTables.mealId] as String,
      name: map[DatabaseTables.mealName] as String,
      servingSizeGrams: (map[DatabaseTables.mealServingSize] as num).toDouble(),
      carbsPer100g: (map[DatabaseTables.mealCarbsPer100g] as num).toDouble(),
      proteinPer100g:
          (map[DatabaseTables.mealProteinPer100g] as num).toDouble(),
      fatPer100g: (map[DatabaseTables.mealFatPer100g] as num).toDouble(),
      caloriesPer100g:
          (map[DatabaseTables.mealCaloriesPer100g] as num).toDouble(),
      createdAt: DateTime.parse(map[DatabaseTables.mealCreatedAt] as String),
    );
  }

  /// Convert MealModel to database map
  Map<String, dynamic> toMap() {
    return {
      DatabaseTables.mealId: id,
      DatabaseTables.mealName: name,
      DatabaseTables.mealServingSize: servingSizeGrams,
      DatabaseTables.mealCarbsPer100g: carbsPer100g,
      DatabaseTables.mealProteinPer100g: proteinPer100g,
      DatabaseTables.mealFatPer100g: fatPer100g,
      DatabaseTables.mealCaloriesPer100g: caloriesPer100g,
      DatabaseTables.mealCreatedAt: createdAt.toIso8601String(),
    };
  }

  /// Convert to JSON for serialization
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

  /// Validate calorie accuracy
  bool get hasValidCalories {
    final calculated = calculatedCalories;
    const tolerance = 5.0;
    return (caloriesPer100g - calculated).abs() <= tolerance;
  }

  /// Calculate calories from macros using 4-4-9 rule
  @override
  double get calculatedCalories {
    return MacroCalculator.calculateCalories(
      carbs: carbsPer100g,
      protein: proteinPer100g,
      fat: fatPer100g,
    );
  }

  /// Throws if the model contains invalid nutritional data.
  void validateMacros() {
    if (name.trim().isEmpty) {
      throw ArgumentError('Meal name cannot be empty');
    }

    if (servingSizeGrams <= 0) {
      throw ArgumentError('Serving size must be greater than 0');
    }

    if (carbsPer100g < 0 || proteinPer100g < 0 || fatPer100g < 0) {
      throw ArgumentError('Macros cannot be negative');
    }

    if (caloriesPer100g < 0) {
      throw ArgumentError('Calories cannot be negative');
    }
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
        'Difference: '
        '${(caloriesPer100g - calculated).abs().toStringAsFixed(1)} cal',
      );
    }
  }

  /// Create a copy with updated fields
  @override
  MealModel copyWith({
    String? id,
    String? name,
    double? servingSizeGrams,
    double? carbsPer100g,
    double? proteinPer100g,
    double? fatPer100g,
    double? caloriesPer100g,
    DateTime? createdAt,
  }) {
    return MealModel(
      id: id ?? this.id,
      name: name ?? this.name,
      servingSizeGrams: servingSizeGrams ?? this.servingSizeGrams,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Create MealModel with auto-calculated calories from macros
  factory MealModel.withCalculatedMacros({
    required String id,
    required String name,
    double servingSizeGrams = 100,
    double? carbsPer100g,
    double? proteinPer100g,
    double? fatPer100g,
    double? caloriesPer100g,
    DateTime? createdAt,
  }) {
    if (caloriesPer100g != null) {
      if (carbsPer100g == null &&
          proteinPer100g != null &&
          fatPer100g != null) {
        carbsPer100g = MacroCalculator.calculateCarbsFromCalories(
          totalCalories: caloriesPer100g,
          protein: proteinPer100g,
          fat: fatPer100g,
        );
      }

      if (proteinPer100g == null &&
          carbsPer100g != null &&
          fatPer100g != null) {
        proteinPer100g = MacroCalculator.calculateProteinFromCalories(
          totalCalories: caloriesPer100g,
          carbs: carbsPer100g,
          fat: fatPer100g,
        );
      }

      if (fatPer100g == null &&
          carbsPer100g != null &&
          proteinPer100g != null) {
        fatPer100g = MacroCalculator.calculateFatFromCalories(
          totalCalories: caloriesPer100g,
          carbs: carbsPer100g,
          protein: proteinPer100g,
        );
      }
    }

    final finalCalories = caloriesPer100g ??
        MacroCalculator.calculateCalories(
          carbs: carbsPer100g ?? 0,
          protein: proteinPer100g ?? 0,
          fat: fatPer100g ?? 0,
        );

    return MealModel(
      id: id,
      name: name,
      servingSizeGrams: servingSizeGrams,
      carbsPer100g: carbsPer100g ?? 0,
      proteinPer100g: proteinPer100g ?? 0,
      fatPer100g: fatPer100g ?? 0,
      caloriesPer100g: finalCalories,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}