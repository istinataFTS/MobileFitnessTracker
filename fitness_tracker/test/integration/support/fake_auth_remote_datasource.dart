import 'package:fitness_tracker/data/datasources/remote/auth_remote_datasource.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';

/// In-memory [AuthRemoteDataSource] for integration tests.
///
/// The real Supabase-backed data source requires network credentials and
/// mutates remote state; integration tests need neither. This fake keeps
/// a single "signed-in" [AppUser] plus a call log so tests can assert
/// which auth operations fired without caring about transport details.
///
/// Behaviour knobs:
/// * [isConfigured] — flipped off to simulate a missing Supabase URL/key,
///   which exercises the "remote sync unavailable" branch of sign-in.
/// * [signInError], [signUpError], [signOutError] — when non-null the
///   corresponding call records itself then throws, so failure-path tests
///   don't need a separate fake.
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  FakeAuthRemoteDataSource({
    this.isConfigured = true,
    AppUser? initialUser,
    this.signInError,
    this.signUpError,
    this.signOutError,
  }) : _currentUser = initialUser;

  @override
  bool isConfigured;

  AppUser? _currentUser;

  /// Ordered log of public-API invocations, one entry per call. Entries
  /// are short verbs (`"signInWithEmail"`, `"signOut"`, …) suitable for
  /// direct `expect(log, equals([...]))` comparisons.
  final List<String> callLog = <String>[];

  Object? signInError;
  Object? signUpError;
  Object? signOutError;

  /// Queued users returned by [signInWithEmail] / [verifyEmailOtp] /
  /// [signUpWithEmail] — first in, first out. When empty, those calls
  /// fabricate a minimal [AppUser] from the supplied email.
  final List<AppUser> queuedUsers = <AppUser>[];

  /// Controls the `requiresEmailConfirmation` flag on the next
  /// [signUpWithEmail] result.
  bool nextSignUpRequiresEmailConfirmation = false;

  @override
  Future<AppUser?> getCurrentUser() async {
    callLog.add('getCurrentUser');
    return _currentUser;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    callLog.add('signInWithEmail');
    if (signInError != null) throw signInError!;
    final user = _nextUser(email: email);
    _currentUser = user;
    return user;
  }

  @override
  Future<SignUpResult> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    callLog.add('signUpWithEmail');
    if (signUpError != null) throw signUpError!;
    final user = _nextUser(email: email, username: username);
    _currentUser = user;
    return SignUpResult(
      user: user,
      requiresEmailConfirmation: nextSignUpRequiresEmailConfirmation,
    );
  }

  @override
  Future<AppUser> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    callLog.add('verifyEmailOtp');
    final user = _nextUser(email: email);
    _currentUser = user;
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    callLog.add('sendPasswordResetEmail');
  }

  @override
  Future<void> signOut() async {
    callLog.add('signOut');
    if (signOutError != null) throw signOutError!;
    _currentUser = null;
  }

  AppUser _nextUser({required String email, String? username}) {
    if (queuedUsers.isNotEmpty) {
      return queuedUsers.removeAt(0);
    }
    return AppUser(
      id: 'fake-${email.hashCode.toUnsigned(32)}',
      email: email,
      displayName: username ?? email.split('@').first,
    );
  }
}
