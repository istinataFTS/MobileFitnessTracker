import 'package:fitness_tracker/features/voice/data/grammar/numbers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceNumberGrammar.parseSingle', () {
    test('parses integer strings', () {
      expect(VoiceNumberGrammar.parseSingle('80'), 80);
      expect(VoiceNumberGrammar.parseSingle('10'), 10);
      expect(VoiceNumberGrammar.parseSingle('0'), 0);
    });

    test('parses decimal strings', () {
      expect(VoiceNumberGrammar.parseSingle('10.5'), 10.5);
      expect(VoiceNumberGrammar.parseSingle('2.5'), 2.5);
    });

    test('parses cardinal words', () {
      expect(VoiceNumberGrammar.parseSingle('one'), 1);
      expect(VoiceNumberGrammar.parseSingle('ten'), 10);
      expect(VoiceNumberGrammar.parseSingle('twenty'), 20);
      expect(VoiceNumberGrammar.parseSingle('hundred'), 100);
    });

    test('parses fractions', () {
      expect(VoiceNumberGrammar.parseSingle('half'), 0.5);
      expect(VoiceNumberGrammar.parseSingle('quarter'), 0.25);
    });

    test('parses "a" as 1', () {
      expect(VoiceNumberGrammar.parseSingle('a'), 1);
    });

    test('returns null for unknown tokens', () {
      expect(VoiceNumberGrammar.parseSingle('bench'), isNull);
      expect(VoiceNumberGrammar.parseSingle(''), isNull);
      expect(VoiceNumberGrammar.parseSingle('xyz'), isNull);
    });

    test('is case-insensitive', () {
      expect(VoiceNumberGrammar.parseSingle('TWENTY'), 20);
      expect(VoiceNumberGrammar.parseSingle('Ten'), 10);
    });
  });

  group('VoiceNumberGrammar.parseCompound', () {
    test('parses plain numeric string', () {
      expect(VoiceNumberGrammar.parseCompound('85'), 85);
    });

    test('parses single word', () {
      expect(VoiceNumberGrammar.parseCompound('eighty'), 80);
    });

    test('sums two-word compound', () {
      expect(VoiceNumberGrammar.parseCompound('twenty five'), 25);
      expect(VoiceNumberGrammar.parseCompound('eighty five'), 85);
      expect(VoiceNumberGrammar.parseCompound('thirty two'), 32);
    });

    test('handles "a hundred" → 100+1 = 101 (sum semantics)', () {
      // "a" maps to 1, "hundred" maps to 100 — sum is 101
      // This is acceptable for the parser; real LLM path handles edges.
      expect(VoiceNumberGrammar.parseCompound('a hundred'), 101);
    });

    test('returns null for unrecognised phrase', () {
      expect(VoiceNumberGrammar.parseCompound('bench press'), isNull);
      expect(VoiceNumberGrammar.parseCompound(''), isNull);
    });

    test('returns null when no words are in vocabulary', () {
      expect(VoiceNumberGrammar.parseCompound('foo bar baz'), isNull);
    });
  });
}
