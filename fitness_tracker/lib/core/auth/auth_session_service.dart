import '../../domain/entities/app_user.dart';
import '../session/session_sync_service.dart';

enum AuthSessionActionStatus {
  completed,
  failed,
}

class AuthSessionActionResult {
  final AuthSessionActionStatus status;
  final String message;
  final AppUser? user;
  final SessionSyncActionResult? sessionResult;

  const AuthSessionActionResult({
    required this.status,
    required this.message,
    this.user,
    this.sessionResult,
  });

  bool get isSuccess => status == AuthSessionActionStatus.completed;
  bool get isFailure => status == AuthSessionActionStatus.failed;
}

abstract class AuthSessionService {
  Future<AuthSessionActionResult> signInWithEmail({
    required String email,
    required String password,
  });

  Future<SessionSyncActionResult> signOut();
}