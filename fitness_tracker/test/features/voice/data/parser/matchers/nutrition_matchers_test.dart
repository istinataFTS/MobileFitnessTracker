import 'package:fitness_tracker/features/voice/data/parser/intent_parser.dart';
import 'package:fitness_tracker/features/voice/data/parser/matchers/nutrition_matchers.dart';
import 'package:fitness_tracker/features/voice/data/parser/parsed.dart';
import 'package:flutter_test/flutter_test.dart';

T? _match<T extends ParsedIntent>(ParsedIntent? Function(String) matcher, String text) {
  final result = matcher(IntentParser.normalise(text));
  if (result is T) return result;
  return null;
}

void main() {
  // =========================================================================
  // matchDeleteNutrition
  // =========================================================================

  group('matchDeleteNutrition', () {
    test('01 — delete my last meal', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'delete my last meal'), isNotNull);
    });

    test('02 — remove the last meal', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'remove the last meal'), isNotNull);
    });

    test('03 — undo my last food entry', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'undo my last food entry'), isNotNull);
    });

    test('04 — cancel the last nutrition entry', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'cancel the last nutrition entry'), isNotNull);
    });

    test('05 — erase my last meal log', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'erase my last meal log'), isNotNull);
    });

    test('06 — delete the food I just logged', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'delete the food i just logged'), isNotNull);
    });

    test('07 — remove my last nutrition log', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'remove my last nutrition log'), isNotNull);
    });

    test('08 — delete what I ate', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'delete what i ate'), isNotNull);
    });

    test('09 — undo the meal I logged', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'undo the meal i logged'), isNotNull);
    });

    test('10 — cancel my food log', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'cancel my food log'), isNotNull);
    });

    test('11 — scratch the last food entry', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'scratch the last food entry'), isNotNull);
    });

    test('12 — forget my last meal', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'forget my last meal'), isNotNull);
    });

    test('13 — drop that nutrition entry', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'drop that nutrition entry'), isNotNull);
    });

    test('14 — clear the last calorie log', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'clear the last calorie log'), isNotNull);
    });

    test('15 — remove that food', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'remove that food'), isNotNull);
    });

    test('16 — delete my last nutrition entry', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'delete my last nutrition entry'), isNotNull);
    });

    test('17 — undo the food I just ate', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'undo the food i just ate'), isNotNull);
    });

    test('18 — discard last meal entry', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'discard last meal entry'), isNotNull);
    });

    test('19 — remove that meal', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'remove that meal'), isNotNull);
    });

    test('20 — erase that food log', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'erase that food log'), isNotNull);
    });

    test('21 — cancel last intake log', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'cancel last intake log'), isNotNull);
    });

    // Negative cases.
    test('no match — workout delete', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'delete my last set'), isNull);
    });

    test('no match — no delete verb', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'log oats 300 calories'), isNull);
    });

    test('no match — delete verb but no nutrition reference', () {
      expect(_match<ParsedDeleteNutrition>(matchDeleteNutrition, 'delete something'), isNull);
    });
  });

  // =========================================================================
  // matchLogNutrition
  // =========================================================================

  group('matchLogNutrition', () {
    test('01 — log oats 300 calories', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'log oats 300 calories');
      expect(r, isNotNull);
      expect(r!.mealName, 'oats');
      expect(r.calories, 300);
    });

    test('02 — add chicken breast 200 calories 30 grams protein', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'add chicken breast 200 calories 30 grams protein');
      expect(r, isNotNull);
      expect(r!.mealName, 'chicken breast');
      expect(r.calories, 200);
      expect(r.proteinGrams, 30);
    });

    test('03 — i ate oats 300 cal 10 protein 50 carbs', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'i ate oats 300 cal 10 protein 50 carbs');
      expect(r, isNotNull);
      expect(r!.mealName, 'oats');
      expect(r.calories, 300);
      expect(r.proteinGrams, 10);
      expect(r.carbsGrams, 50);
    });

    test('04 — log greek yogurt 150 calories', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'log greek yogurt 150 calories');
      expect(r, isNotNull);
      expect(r!.mealName, 'greek yogurt');
      expect(r.calories, 150);
    });

    test('05 — had rice 250 cal 5 fat', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'had rice 250 cal 5 fat');
      expect(r, isNotNull);
      expect(r!.mealName, 'rice');
      expect(r.calories, 250);
      expect(r.fatGrams, 5);
    });

    test('06 — record banana 100 kcal', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'record banana 100 kcal');
      expect(r, isNotNull);
      expect(r!.mealName, 'banana');
      expect(r.calories, 100);
    });

    test('07 — log egg whites 50 calories 10 protein', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'log egg whites 50 calories 10 protein');
      expect(r, isNotNull);
      expect(r!.mealName, 'egg whites');
      expect(r.proteinGrams, 10);
    });

    test('08 — track peanut butter 190 cal 8 protein 16 fat', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'track peanut butter 190 cal 8 protein 16 fat');
      expect(r, isNotNull);
      expect(r!.mealName, 'peanut butter');
      expect(r.calories, 190);
      expect(r.proteinGrams, 8);
      expect(r.fatGrams, 16);
    });

    test('09 — add protein shake 120 calories 25 grams protein', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'add protein shake 120 calories 25 grams protein');
      expect(r, isNotNull);
      expect(r!.mealName, 'protein shake');
    });

    test('10 — log whole milk 150 calories 8 protein 8 fat 12 carbs', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'log whole milk 150 calories 8 protein 8 fat 12 carbs');
      expect(r, isNotNull);
      expect(r!.mealName, 'whole milk');
      expect(r.calories, 150);
      expect(r.proteinGrams, 8);
      expect(r.fatGrams, 8);
      expect(r.carbsGrams, 12);
    });

    test('11 — save sweet potato 130 cal', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'save sweet potato 130 cal');
      expect(r, isNotNull);
      expect(r!.mealName, 'sweet potato');
    });

    test('12 — note salmon 200 calories 25 protein', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'note salmon 200 calories 25 protein');
      expect(r, isNotNull);
    });

    test('13 — ate cottage cheese 90 calories', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'ate cottage cheese 90 calories');
      expect(r, isNotNull);
      expect(r!.mealName, 'cottage cheese');
    });

    test('14 — log tuna 100 cal 22 protein', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'log tuna 100 cal 22 protein');
      expect(r, isNotNull);
    });

    test('15 — enter oatmeal 300 calories 10 protein 50 carbs 5 fat', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'enter oatmeal 300 calories 10 protein 50 carbs 5 fat');
      expect(r, isNotNull);
      expect(r!.mealName, 'oatmeal');
    });

    test('16 — i had a banana 100 calories', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'i had a banana 100 calories');
      expect(r, isNotNull);
      expect(r!.mealName, 'banana');
    });

    test('17 — just ate bread 200 cal', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'just ate bread 200 cal');
      expect(r, isNotNull);
      expect(r!.mealName, 'bread');
    });

    test('18 — logged almonds 160 calories 6 protein', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'logged almonds 160 calories 6 protein');
      expect(r, isNotNull);
    });

    test('19 — track avocado 240 calories 2 protein 22 fat 12 carbs', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'track avocado 240 calories 2 protein 22 fat 12 carbs');
      expect(r, isNotNull);
      expect(r!.mealName, 'avocado');
      expect(r.calories, 240);
    });

    test('20 — add broccoli 55 calories 5 protein', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'add broccoli 55 calories 5 protein');
      expect(r, isNotNull);
      expect(r!.mealName, 'broccoli');
    });

    test('21 — log whey protein 120 calories 25 grams protein', () {
      final r = _match<ParsedLogNutrition>(matchLogNutrition, 'log whey protein 120 calories 25 grams protein');
      expect(r, isNotNull);
    });

    // Negative cases.
    test('no match — workout log', () {
      expect(_match<ParsedLogNutrition>(matchLogNutrition, 'log bench press 80 kg 10 reps'), isNull);
    });

    test('no match — delete utterance', () {
      expect(_match<ParsedLogNutrition>(matchLogNutrition, 'delete my last meal'), isNull);
    });

    test('no match — too short', () {
      expect(_match<ParsedLogNutrition>(matchLogNutrition, 'log oats'), isNull);
    });

    test('no match — no nutrition marker', () {
      expect(_match<ParsedLogNutrition>(matchLogNutrition, 'log oats 80 by 10'), isNull);
    });
  });
}
