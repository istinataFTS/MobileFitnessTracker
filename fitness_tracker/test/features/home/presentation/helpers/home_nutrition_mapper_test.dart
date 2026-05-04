import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/domain/entities/nutrition_log.dart';
import 'package:fitness_tracker/features/home/application/models/home_dashboard_data.dart';
import 'package:fitness_tracker/features/home/application/muscle_visual_bloc.dart';
import 'package:fitness_tracker/features/home/presentation/mappers/home_view_data_mapper.dart';
import 'package:fitness_tracker/features/home/presentation/models/home_view_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime createdAt = DateTime(2024, 1, 1);

  NutritionLog buildLog({
    required String id,
    required String mealName,
    required double protein,
    required double carbs,
    required double fats,
    required double calories,
    bool isMealLog = true,
  }) {
    return NutritionLog(
      id: id,
      mealId: isMealLog ? 'meal-$id' : null,
      mealName: mealName,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fats,
      calories: calories,
      loggedAt: createdAt,
      createdAt: createdAt,
    );
  }

  const AppSettings settings = AppSettings(
    notificationsEnabled: true,
    weekStartDay: WeekStartDay.monday,
    weightUnit: WeightUnit.kilograms,
  );

  test('macro strip shows rounded non-zero values with correct units', () {
    final HomeDashboardData homeData = HomeDashboardData(
      todaysLogs: <NutritionLog>[
        buildLog(
          id: '1',
          mealName: 'Chicken Rice',
          protein: 40,
          carbs: 60,
          fats: 10,
          calories: 490,
        ),
      ],
      dailyMacros: const <String, double>{
        'protein': 60,
        'carbs': 72,
        'fats': 15,
        'calories': 660,
      },
    );

    final HomePageViewData viewData = HomeViewDataMapper.map(
      homeData: homeData,
      muscleVisualState: const MuscleVisualInitial(),
      settings: settings,
    );

    expect(viewData.nutrition.caloriesLabel, '660 kcal');
    expect(viewData.nutrition.proteinLabel, '60 g');
    expect(viewData.nutrition.carbsLabel, '72 g');
    expect(viewData.nutrition.fatsLabel, '15 g');
  });

  test('macro strip shows dash for zero macro values', () {
    final HomeDashboardData homeData = HomeDashboardData(
      todaysLogs: const <NutritionLog>[],
      dailyMacros: const <String, double>{
        'protein': 0,
        'carbs': 0,
        'fats': 0,
        'calories': 0,
      },
    );

    final HomePageViewData viewData = HomeViewDataMapper.map(
      homeData: homeData,
      muscleVisualState: const MuscleVisualInitial(),
      settings: settings,
    );

    expect(viewData.nutrition.caloriesLabel, '–');
    expect(viewData.nutrition.proteinLabel, '–');
    expect(viewData.nutrition.carbsLabel, '–');
    expect(viewData.nutrition.fatsLabel, '–');
  });

  test('macro strip renders non-zero values with correct units — smoke', () {
    final HomeDashboardData homeData = HomeDashboardData(
      todaysLogs: const <NutritionLog>[],
      dailyMacros: const <String, double>{
        'protein': 100,
        'carbs': 200,
        'fats': 50,
        'calories': 1640,
      },
    );

    final HomePageViewData viewData = HomeViewDataMapper.map(
      homeData: homeData,
      muscleVisualState: const MuscleVisualInitial(),
      settings: settings,
    );

    expect(viewData.nutrition.proteinLabel, '100 g');
    expect(viewData.nutrition.caloriesLabel, '1640 kcal');
  });
}
