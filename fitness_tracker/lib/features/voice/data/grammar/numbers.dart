/// Grammar data for spoken number recognition.
///
/// Covers cardinal words (one … ninety-nine), round hundreds, common
/// fractions, and the "a" article used as "one" (e.g. "a hundred").
/// Compound numbers ("twenty five", "eighty five") are handled by
/// [parseCompound], which splits on whitespace and sums word values.
abstract final class VoiceNumberGrammar {
  VoiceNumberGrammar._();

  /// Single-token word → numeric value.
  /// Keys are lowercase; callers must normalise before lookup.
  static const Map<String, num> _wordValues = {
    'zero': 0,
    'oh': 0,
    'a': 1,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
    'hundred': 100,
    'half': 0.5,
    'quarter': 0.25,
  };

  /// Parses a single whitespace-free token as a number.
  /// Returns null if the token is neither a numeric literal nor a known word.
  static num? parseSingle(String token) {
    final t = token.trim().toLowerCase();
    if (t.isEmpty) return null;
    final direct = double.tryParse(t);
    if (direct != null) return direct;
    return _wordValues[t];
  }

  /// Parses a multi-word phrase such as "eighty five" or "twenty point five".
  ///
  /// Strategy:
  /// 1. Try the whole phrase as a numeric literal.
  /// 2. Try it as a single word in the vocabulary.
  /// 3. Split on whitespace and sum individual word values (handles
  ///    "twenty five" → 25, "a hundred" → 100).
  /// Returns null if no interpretation succeeds.
  static num? parseCompound(String phrase) {
    final lower = phrase.trim().toLowerCase();
    if (lower.isEmpty) return null;

    final direct = double.tryParse(lower);
    if (direct != null) return direct;

    final single = _wordValues[lower];
    if (single != null) return single;

    num sum = 0;
    bool matched = false;
    for (final word in lower.split(RegExp(r'\s+'))) {
      final v = _wordValues[word];
      if (v != null) {
        sum += v;
        matched = true;
      }
    }
    return matched ? sum : null;
  }
}
