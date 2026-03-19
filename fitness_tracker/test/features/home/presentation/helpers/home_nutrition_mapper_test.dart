import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/domain/entities/exercise.dart';
import 'package:fitness_tracker/domain/entities/nutrition_log.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:fitness_tracker/features/home/application/home_bloc.dart';
import 'package:fitness_tracker/features/home/application/muscle_visual_bloc.dart';
import 'package:fitness_tracker/features/home/presentation/mappers/home_view_data_mapper.dart';
import 'package:fitness_tracker/features/home/presentation/models/home_view_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime createdAt = DateTime(2024, 1, 1);

  Target buildMacroTarget({
    required String id,
    required String categoryKey,
    required double targetValue,
  }) {
    return Target(
      id: id,
      type: TargetType.macro,
      categoryKey: categoryKey,
      targetValue: targetValue,
      unit: 'g',
      period: TargetPeriod.daily,
      createdAt: createdAt,
    );
  }

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
      servingSizeGrams: 100,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fats,
      calories: calories,
      date: createdAt,
      createdAt: createdAt,
    );
  }

  const AppSettings settings = AppSettings(
    notificationsEnabled: true,
    weekStartDay: WeekStartDay.monday,
    weightUnit: WeightUnit.kilograms,
  );

  test('maps nutrition summary with macro targets and recent logs', () {
    final HomeLoaded state = HomeLoaded(
      targets: <Target>[
        buildMacroTarget(
          id: 'protein-target',
          categoryKey: 'protein',
          targetValue: 150,
        ),
        buildMacroTarget(
          id: 'carbs-target',
          categoryKey: 'carbs',
          targetValue: 250,
        ),
      ],
      weeklySets: const [],
      todaysLogs: <NutritionLog>[
        buildLog(
          id: '1',
          mealName: 'Chicken Rice',
          protein: 40,
          carbs: 60,
          fats: 10,
          calories: 490,
        ),
        buildLog(
          id: '2',
          mealName: 'Yogurt',
          protein: 20,
          carbs: 12,
          fats: 5,
          calories: 170,
          isMealLog: false,
        ),
      ],
      dailyMacros: const <String, double>{
        'protein': 60,
        'carbs': 72,
        'fats': 15,
        'calories': 660,
      },
      exercises: const <Exercise>[],
    );

    final HomePageViewData viewData = HomeViewDataMapper.map(
      homeState: state,
      muscleVisualState: const MuscleVisualInitial(),
      settings: settings,
    );

    expect(viewData.nutrition.totalCaloriesLabel, '660 kcal');
    expect(viewData.nutrition.hasEntries, isTrue);
    expect(viewData.nutrition.macros, hasLength(3));
    expect(viewData.nutrition.recentEntries, hasLength(2));

    expect(viewData.nutrition.macros[0].label, 'Protein');
    expect(viewData.nutrition.macros[0].progressLabel, '60 / 150 g');
    expect(viewData.nutrition.macros[0].trailingLabel, '90 g left');
    expect(viewData.nutrition.macros[0].hasTarget, isTrue);

    expect(viewData.nutrition.macros[2].label, 'Fats');
    expect(viewData.nutrition.macros[2].hasTarget, isFalse);
    expect(viewData.nutrition.macros[2].trailingLabel, 'No target');

    expect(viewData.nutrition.recentEntries[0].title, 'Chicken Rice');
    expect(viewData.nutrition.recentEntries[0].isMealLog, isTrue);
    expect(viewData.nutrition.recentEntries[1].isMealLog, isFalse);
  });

  test('maps empty nutrition state without logs', () {
    final HomeLoaded state = HomeLoaded(
      targets: const <Target>[],
      weeklySets: const [],
      todaysLogs: const <NutritionLog>[],
      dailyMacros: const <String, double>{
        'protein': 0,
        'carbs': 0,
        'fats': 0,
        'calories': 0,
      },
      exercises: const <Exercise>[],
    );

    final HomePageViewData viewData = HomeViewDataMapper.map(
      homeState: state,
      muscleVisualState: const MuscleVisualInitial(),
      settings: settings,
    );

    expect(viewData.nutrition.totalCaloriesLabel, '0 kcal');
    expect(viewData.nutrition.hasEntries, isFalse);
    expect(viewData.nutrition.recentEntries, isEmpty);
    expect(viewData.nutrition.macros, hasLength(3));
  });
}