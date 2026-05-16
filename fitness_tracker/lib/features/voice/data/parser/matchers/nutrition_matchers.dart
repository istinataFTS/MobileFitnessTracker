import '../../../data/grammar/numbers.dart';
import '../../../data/grammar/nutrition_phrases.dart';
import '../../../data/grammar/verbs.dart';
import '../parsed.dart';

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// Prefix fillers to skip before the verb.
const _prefixFillers = {'i', "i've", 'ive', 'just', 'already', 'now'};

/// Tokens to skip when building the meal name (articles / determiners).
const _nameSkip = {'a', 'an', 'the', 'my', 'some', 'of'};

/// Returns true if the token is numeric (excluding "a" article).
bool _isNumeric(String token) {
  if (token == 'a') return false;
  return VoiceNumberGrammar.parseSingle(token) != null;
}

/// Tries to scan [tokens] for a number followed by an optional macro keyword.
/// Returns the numeric value or null.
double? _scanForNumber(List<String> tokens) {
  for (int i = 0; i < tokens.length; i++) {
    final v = VoiceNumberGrammar.parseSingle(tokens[i]);
    if (v != null && tokens[i] != 'a') return v.toDouble();
  }
  return null;
}

/// Tries to extract macro fields from [normed] text.
/// Scans for patterns like "200 calories", "30 grams protein", "10g fat".
({double? calories, double? protein, double? carbs, double? fat})
    _extractMacros(String normed) {
  double? calories;
  double? protein;
  double? carbs;
  double? fat;

  final tokens = normed.split(' ');
  for (int i = 0; i < tokens.length; i++) {
    final v = VoiceNumberGrammar.parseSingle(tokens[i]);
    if (v == null || tokens[i] == 'a') continue;

    // Look ahead for macro keyword.
    for (int j = i + 1; j <= i + 2 && j < tokens.length; j++) {
      final kw = tokens[j];
      if (kw == 'calories' || kw == 'calorie' || kw == 'cal' || kw == 'kcal') {
        calories = v.toDouble();
        break;
      }
      if (kw == 'protein' || kw == 'proteins') {
        protein = v.toDouble();
        break;
      }
      if (kw == 'carbs' ||
          kw == 'carb' ||
          kw == 'carbohydrate' ||
          kw == 'carbohydrates') {
        carbs = v.toDouble();
        break;
      }
      if (kw == 'fat' || kw == 'fats') {
        fat = v.toDouble();
        break;
      }
    }
  }

  return (calories: calories, protein: protein, carbs: carbs, fat: fat);
}

// ---------------------------------------------------------------------------
// Delete nutrition log
// ---------------------------------------------------------------------------

/// Matches utterances that ask to delete the most-recently logged nutrition entry.
///
/// Examples:
///   "delete my last meal"         "remove the last nutrition log"
///   "undo my last food entry"     "cancel the last nutrition entry"
///   "erase my last meal log"      "delete the food I just logged"
ParsedIntent? matchDeleteNutrition(String normed) {
  final tokens = normed.split(' ');
  final hasDeleteVerb = tokens.any(VoiceVerbGrammar.deleteVerbs.contains);
  if (!hasDeleteVerb) return null;

  // Must reference a nutrition-related concept.
  final hasNutritionRef = normed.contains('meal') ||
      normed.contains('nutrition') ||
      normed.contains('calorie') ||
      normed.contains('food') ||
      normed.contains('ate') ||
      normed.contains('eaten') ||
      normed.contains('logged food') ||
      normed.contains('log') ||
      normed.contains('entry') ||
      normed.contains('intake');
  if (!hasNutritionRef) return null;

  return const ParsedDeleteNutrition();
}

// ---------------------------------------------------------------------------
// Log nutrition
// ---------------------------------------------------------------------------

/// Matches utterances that ask to log a new nutrition entry.
///
/// Recognised patterns:
///   [verb?] [meal_name] [number] [calories|cal|kcal]? [macros...]
///   [verb?] [meal_name] [grams consumed]?
///
/// Examples:
///   "log oats 300 calories"
///   "add chicken breast 200 calories 30 grams protein"
///   "i ate oats 300 cal 10 protein 50 carbs"
///   "log greek yogurt 150 calories"
ParsedIntent? matchLogNutrition(String normed) {
  final tokens = normed.split(' ');
  if (tokens.length < 2) return null;

  // Do not match delete commands (e.g. "delete my last meal").
  if (tokens.any(VoiceVerbGrammar.deleteVerbs.contains)) return null;

  // Do not match query utterances (e.g. "what are my macros", "how many calories").
  // Query words at position 0 mean the user is asking, not logging.
  if (tokens.isNotEmpty && VoiceVerbGrammar.queryWords.contains(tokens[0])) {
    return null;
  }

  // Must contain at least one nutrition marker to distinguish from workout log.
  if (!VoiceNutritionPhraseGrammar.hasLogMarker(normed)) return null;

  int i = 0;

  // Skip personal pronoun fillers.
  while (i < tokens.length && _prefixFillers.contains(tokens[i])) {
    i++;
  }

  // Accept eating-related verbs: "ate", "had", "eat", "drink", "drank".
  const eatVerbs = {'ate', 'had', 'eat', 'eaten', 'drink', 'drank', 'drinking'};
  final isEatVerb = i < tokens.length && eatVerbs.contains(tokens[i]);

  // Accept standard log verbs.
  final isLogVerb =
      i < tokens.length && VoiceVerbGrammar.logVerbs.contains(tokens[i]);

  if (isLogVerb || isEatVerb) i++;

  // Skip a second filler after the verb ("i just ate").
  if (i < tokens.length && _prefixFillers.contains(tokens[i])) i++;
  if (i < tokens.length &&
      (VoiceVerbGrammar.logVerbs.contains(tokens[i]) ||
          eatVerbs.contains(tokens[i]))) {
    i++;
  }

  // Skip articles.
  while (i < tokens.length && _nameSkip.contains(tokens[i])) {
    i++;
  }

  if (i >= tokens.length) return null;

  // Collect meal name tokens until the first numeric token.
  // Macro markers (e.g. "protein", "calories") are NOT stopped on — they
  // can legitimately appear in food names ("protein shake", "whey protein").
  // Numbers are the reliable delimiter between name and values.
  final mealTokens = <String>[];
  while (i < tokens.length) {
    final token = tokens[i];
    if (_nameSkip.contains(token)) {
      i++;
      continue;
    }
    if (_isNumeric(token)) break;
    mealTokens.add(token);
    i++;
  }

  if (mealTokens.isEmpty) return null;
  final mealName = mealTokens.join(' ');

  // Extract macros from the remaining text.
  final remaining = tokens.sublist(i).join(' ');
  final macros = _extractMacros(remaining);

  // Also try first standalone number as calories if no explicit label found.
  double? calories = macros.calories;
  if (calories == null) {
    final firstNum = _scanForNumber(tokens.sublist(i));
    if (firstNum != null) calories = firstNum;
  }

  return ParsedLogNutrition(
    mealName: mealName,
    calories: calories,
    proteinGrams: macros.protein,
    carbsGrams: macros.carbs,
    fatGrams: macros.fat,
  );
}
