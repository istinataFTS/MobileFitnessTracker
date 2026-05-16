import 'parsed.dart';

/// A function that tries to match a pre-normalised utterance to a
/// [ParsedIntent]. Returns null when this matcher cannot handle the input.
typedef IntentMatcher = ParsedIntent? Function(String normalised);

/// Offline intent parser.
///
/// Accepts an ordered list of [IntentMatcher] functions and tries each in
/// sequence, returning the first non-null result. Falls back to
/// [ParsedUnrecognized] when no matcher fires.
///
/// ## Normalisation
/// Input text is lowercased, trimmed, and has runs of whitespace collapsed
/// to a single space before being handed to each matcher. Matchers may
/// assume the input is already normalised.
///
/// ## Ordering
/// Matchers are tried in the order supplied. Put delete/edit matchers before
/// log matchers to avoid ambiguous prefixes capturing more-specific intents.
class IntentParser {
  const IntentParser(this._matchers);

  final List<IntentMatcher> _matchers;

  /// Parses [text] and returns the best matching [ParsedIntent].
  ParsedIntent parse(String text) {
    final norm = normalise(text);
    if (norm.isEmpty) return const ParsedUnrecognized();
    for (final matcher in _matchers) {
      final result = matcher(norm);
      if (result != null) return result;
    }
    return const ParsedUnrecognized();
  }

  /// Lowercases [text], trims leading/trailing whitespace, and collapses
  /// internal whitespace runs to a single space.
  ///
  /// Exposed as a public static so individual matchers can call it on their
  /// own sub-strings without duplicating the logic.
  static String normalise(String text) =>
      text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
