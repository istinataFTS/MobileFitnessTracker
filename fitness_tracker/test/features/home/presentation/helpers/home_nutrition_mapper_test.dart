import 'package:fitness_tracker/domain/entities/nutrition_log.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:fitness_tracker/presentation/pages/home/bloc/home_bloc.dart';
import 'package:fitness_tracker/presentation/pages/home/helpers/home_nutrition_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2024, 1, 1);

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

  test('maps nutrition summary with macro targets and recent logs', () {
    final state = HomeLoaded(
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
    );

    final viewData = HomeNutritionMapper.map(state);

    expect(viewData.totalCaloriesLabel, '660 kcal');
    expect(viewData.hasLogs, isTrue);
    expect(viewData.macroItems, hasLength(3));
    expect(viewData.recentLogs, hasLength(2));

    expect(viewData.macroItems[0].label, 'Protein');
    expect(viewData.macroItems[0].progressText, '60 / 150 g');
    expect(viewData.macroItems[0].trailingText, '90 g left');
    expect(viewData.macroItems[0].hasTarget, isTrue);

    expect(viewData.macroItems[2].label, 'Fats');
    expect(viewData.macroItems[2].hasTarget, isFalse);
    expect(viewData.macroItems[2].trailingText, 'No target');

    expect(viewData.recentLogs[0].title, 'Chicken Rice');
    expect(viewData.recentLogs[0].isMealLog, isTrue);
    expect(viewData.recentLogs[1].isMealLog, isFalse);
  });

  test('maps empty nutrition state without logs', () {
    final state = HomeLoaded(
      targets: const <Target>[],
      weeklySets: const [],
      todaysLogs: const <NutritionLog>[],
      dailyMacros: const <String, double>{
        'protein': 0,
        'carbs': 0,
        'fats': 0,
        'calories': 0,
      },
    );

    final viewData = HomeNutritionMapper.map(state);

    expect(viewData.totalCaloriesLabel, '0 kcal');
    expect(viewData.hasLogs, isFalse);
    expect(viewData.recentLogs, isEmpty);
    expect(viewData.macroItems, hasLength(3));
  });
}