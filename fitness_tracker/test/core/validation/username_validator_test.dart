import 'package:fitness_tracker/core/validation/username_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UsernameValidator.validate', () {
    test('returns null for a valid username', () {
      expect(UsernameValidator.validate('alice_99'), isNull);
    });

    test('trims surrounding whitespace before validating', () {
      expect(UsernameValidator.validate('  bob  '), isNull);
    });

    test('rejects an empty / whitespace-only value', () {
      expect(UsernameValidator.validate('   '), 'Username is required.');
    });

    test('rejects a value shorter than the minimum', () {
      expect(
        UsernameValidator.validate('ab'),
        'Username must be between 3 and 30 characters.',
      );
    });

    test('rejects a value longer than the maximum', () {
      expect(
        UsernameValidator.validate('a' * 31),
        'Username must be between 3 and 30 characters.',
      );
    });

    test('rejects illegal characters', () {
      expect(
        UsernameValidator.validate('bad name!'),
        'Username may only contain letters, numbers, and underscores.',
      );
    });
  });
}
