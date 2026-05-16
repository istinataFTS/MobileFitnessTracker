/// Grammar data for nutrition-related spoken phrase recognition.
///
/// Provides keyword sets used by the offline intent matchers to
/// distinguish nutrition logging from workout logging, and to detect
/// macro-query intent.
/// All entries are lowercase; callers must normalise before lookup.
abstract final class VoiceNutritionPhraseGrammar {
  VoiceNutritionPhraseGrammar._();

  /// Words whose presence in an utterance strongly suggests the user is
  /// logging food / nutrition (not a workout set).
  static const Set<String> logMarkers = {
    'calories',
    'calorie',
    'cal',
    'kcal',
    'protein',
    'proteins',
    'carbs',
    'carb',
    'carbohydrate',
    'carbohydrates',
    'fat',
    'fats',
    'macros',
    'macro',
    'nutrition',
    'nutritional',
    'food',
    'meal',
    'ate',
    'eat',
    'eaten',
    'drinking',
    'drank',
    'drink',
    'had',
    'grams',
    'gram',
    'g',
    'serving',
    'servings',
  };

  /// Phrases (or individual words) that trigger a daily-macro query.
  static const Set<String> macroQueryTriggers = {
    'macros',
    'macro',
    'nutrition',
    'calories',
    'calorie',
    'protein',
    'carbs',
    'fat',
    'daily intake',
    'intake',
    'what did i eat',
    'what have i eaten',
    'what i ate',
    'food today',
    'meals today',
    'nutrition today',
    'calorie count',
    'calorie total',
  };

  /// Returns true if any nutrition log marker appears as a whole word in [text].
  static bool hasLogMarker(String text) {
    final lower = text.toLowerCase();
    return logMarkers.any(
      (marker) => RegExp(r'\b' + RegExp.escape(marker) + r'\b').hasMatch(lower),
    );
  }

  /// Returns true if any macro-query trigger appears in [text].
  static bool hasMacroQueryTrigger(String text) {
    final lower = text.toLowerCase();
    return macroQueryTriggers.any(
      (trigger) =>
          RegExp(r'\b' + RegExp.escape(trigger) + r'\b').hasMatch(lower),
    );
  }
}
