/// Grammar data for spoken time-period recognition.
///
/// Each set contains the lowercased phrases that map to a particular
/// relative time window. Multi-word phrases are included as-is; the
/// matcher is expected to normalise whitespace before checking.
abstract final class VoiceTimePhraseGrammar {
  VoiceTimePhraseGrammar._();

  /// Phrases that refer to the current calendar day.
  static const Set<String> todayPhrases = {
    'today',
    'now',
    'tonight',
    'this morning',
    'this afternoon',
    'this evening',
    'right now',
    'just now',
  };

  /// Phrases that refer to the current ISO week (Mon–Sun).
  static const Set<String> thisWeekPhrases = {
    'this week',
    'weekly',
    "this week's",
    'week',
    'past week',
    'last seven days',
    'last 7 days',
    'past 7 days',
    'past seven days',
  };

  /// Phrases that refer to the previous calendar day.
  static const Set<String> yesterdayPhrases = {'yesterday'};

  /// Returns true if [text] (after lowercasing and trimming) matches a
  /// "today" phrase.
  static bool isToday(String text) =>
      todayPhrases.contains(text.trim().toLowerCase());

  /// Returns true if [text] matches a "this week" phrase.
  static bool isThisWeek(String text) =>
      thisWeekPhrases.contains(text.trim().toLowerCase());

  /// Returns true if [text] matches a "yesterday" phrase.
  static bool isYesterday(String text) =>
      yesterdayPhrases.contains(text.trim().toLowerCase());
}
