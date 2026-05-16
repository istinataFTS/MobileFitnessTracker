/// Single source of truth for username rules.
///
/// Used at registration ([SignUpCubit]) and when a user renames themselves
/// from Settings ([ProfileCubit.updateUsername]) so the two paths can never
/// diverge. Pure and side-effect free — trivially unit-testable.
abstract final class UsernameValidator {
  UsernameValidator._();

  static const int minLength = 3;
  static const int maxLength = 30;

  /// Letters, digits and underscore only — mirrors the `user_profiles`
  /// uniqueness/handle expectations on the backend.
  static final RegExp _pattern = RegExp(r'^[a-zA-Z0-9_]+$');

  /// Returns `null` when [raw] (after trimming) is a valid username,
  /// otherwise a human-readable error message suitable for display.
  static String? validate(String raw) {
    final String value = raw.trim();

    if (value.isEmpty) {
      return 'Username is required.';
    }

    if (value.length < minLength || value.length > maxLength) {
      return 'Username must be between $minLength and $maxLength characters.';
    }

    if (!_pattern.hasMatch(value)) {
      return 'Username may only contain letters, numbers, and underscores.';
    }

    return null;
  }
}
