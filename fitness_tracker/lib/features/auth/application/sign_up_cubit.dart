import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/auth_session_service.dart';

enum SignUpStatus {
  initial,
  submitting,

  /// Account created; backend requires email confirmation before sign-in.
  awaitingEmailConfirmation,

  /// Account created and session established (no email confirmation needed).
  success,

  failure,
}

class SignUpState extends Equatable {
  final SignUpStatus status;
  final String? errorMessage;
  final String? email;

  const SignUpState({
    required this.status,
    this.errorMessage,
    this.email,
  });

  factory SignUpState.initial() =>
      const SignUpState(status: SignUpStatus.initial);

  bool get isInitial => status == SignUpStatus.initial;
  bool get isSubmitting => status == SignUpStatus.submitting;
  bool get isAwaitingEmailConfirmation =>
      status == SignUpStatus.awaitingEmailConfirmation;
  bool get isSuccess => status == SignUpStatus.success;
  bool get isFailure => status == SignUpStatus.failure;

  SignUpState copyWith({
    SignUpStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? email,
  }) {
    return SignUpState(
      status: status ?? this.status,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, errorMessage, email];
}

class SignUpCubit extends Cubit<SignUpState> {
  static const int _minPasswordLength = 8;
  static const int _minUsernameLength = 3;
  static const int _maxUsernameLength = 30;
  static final RegExp _usernamePattern = RegExp(r'^[a-zA-Z0-9_]+$');

  final AuthSessionService _authSessionService;

  SignUpCubit({required AuthSessionService authSessionService})
      : _authSessionService = authSessionService,
        super(SignUpState.initial());

  Future<void> submit({
    required String email,
    required String password,
    required String confirmPassword,
    required String username,
  }) async {
    if (state.isSubmitting) {
      return;
    }

    final validationError = _validate(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      username: username,
    );

    if (validationError != null) {
      emit(
        state.copyWith(
          status: SignUpStatus.failure,
          errorMessage: validationError,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SignUpStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    final result = await _authSessionService.signUpWithEmail(
      email: email.trim(),
      password: password,
      username: username.trim(),
    );

    if (result.isFailure) {
      emit(
        state.copyWith(
          status: SignUpStatus.failure,
          errorMessage: result.message,
        ),
      );
      return;
    }

    if (result.requiresEmailConfirmation) {
      emit(
        state.copyWith(
          status: SignUpStatus.awaitingEmailConfirmation,
          clearErrorMessage: true,
          email: email.trim(),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SignUpStatus.success,
        clearErrorMessage: true,
      ),
    );
  }

  void clearError() {
    if (state.errorMessage == null) {
      return;
    }

    emit(
      state.copyWith(
        status: SignUpStatus.initial,
        clearErrorMessage: true,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  String? _validate({
    required String email,
    required String password,
    required String confirmPassword,
    required String username,
  }) {
    final trimmedEmail = email.trim();
    final trimmedUsername = username.trim();

    if (trimmedEmail.isEmpty || password.isEmpty || trimmedUsername.isEmpty) {
      return 'All fields are required.';
    }

    if (!trimmedEmail.contains('@')) {
      return 'Enter a valid email address.';
    }

    if (password.length < _minPasswordLength) {
      return 'Password must be at least $_minPasswordLength characters.';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }

    if (trimmedUsername.length < _minUsernameLength ||
        trimmedUsername.length > _maxUsernameLength) {
      return 'Username must be between $_minUsernameLength and '
          '$_maxUsernameLength characters.';
    }

    if (!_usernamePattern.hasMatch(trimmedUsername)) {
      return 'Username may only contain letters, numbers, and underscores.';
    }

    return null;
  }
}
