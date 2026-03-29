import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/auth_session_service.dart';
import '../../../core/session/session_sync_service.dart';
import '../../../domain/entities/app_session.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/repositories/app_session_repository.dart';
import '../../../domain/repositories/user_profile_repository.dart';

class ProfileState extends Equatable {
  const ProfileState({
    required this.session,
    required this.isLoading,
    required this.hasLoaded,
    this.userProfile,
    this.errorMessage,
  });

  final AppSession session;
  final bool isLoading;
  final bool hasLoaded;
  final UserProfile? userProfile;
  final String? errorMessage;

  factory ProfileState.initial() {
    return const ProfileState(
      session: AppSession.guest(),
      isLoading: false,
      hasLoaded: false,
      userProfile: null,
      errorMessage: null,
    );
  }

  ProfileState copyWith({
    AppSession? session,
    bool? isLoading,
    bool? hasLoaded,
    UserProfile? userProfile,
    bool clearUserProfile = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ProfileState(
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      userProfile:
          clearUserProfile ? null : (userProfile ?? this.userProfile),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        session,
        isLoading,
        hasLoaded,
        userProfile,
        errorMessage,
      ];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required AppSessionRepository repository,
    required SessionSyncService sessionSyncService,
    required AuthSessionService authSessionService,
    required UserProfileRepository userProfileRepository,
  })  : _repository = repository,
        _sessionSyncService = sessionSyncService,
        _authSessionService = authSessionService,
        _userProfileRepository = userProfileRepository,
        super(ProfileState.initial());

  final AppSessionRepository _repository;
  final SessionSyncService _sessionSyncService;
  final AuthSessionService _authSessionService;
  final UserProfileRepository _userProfileRepository;

  Future<void> ensureLoaded() async {
    if (state.hasLoaded || state.isLoading) {
      return;
    }

    await _loadProfile();
  }

  Future<void> loadProfile() async {
    await _loadProfile();
  }

  Future<void> refreshProfile() async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    final refreshResult = await _sessionSyncService.runManualRefresh();
    final sessionResult = await _repository.getCurrentSession();

    await sessionResult.fold(
      (failure) async {
        emit(
          state.copyWith(
            session: const AppSession.guest(),
            isLoading: false,
            hasLoaded: true,
            clearUserProfile: true,
            errorMessage: _combineMessages(
              primary: refreshResult.isSuccess ? null : refreshResult.message,
              fallback: failure.message,
            ),
          ),
        );
      },
      (session) async {
        final userProfile = await _fetchUserProfile(session);

        emit(
          state.copyWith(
            session: session,
            userProfile: userProfile,
            isLoading: false,
            hasLoaded: true,
            errorMessage:
                refreshResult.isSuccess ? null : refreshResult.message,
            clearErrorMessage: refreshResult.isSuccess,
          ),
        );
      },
    );
  }

  Future<void> signOut() async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    final signOutResult = await _authSessionService.signOut();
    final sessionResult = await _repository.getCurrentSession();

    sessionResult.fold(
      (failure) {
        emit(
          state.copyWith(
            session: const AppSession.guest(),
            isLoading: false,
            hasLoaded: true,
            clearUserProfile: true,
            errorMessage: signOutResult.isSuccess
                ? failure.message
                : _combineMessages(
                    primary: signOutResult.message,
                    fallback: failure.message,
                  ),
          ),
        );
      },
      (session) {
        emit(
          state.copyWith(
            session: session,
            isLoading: false,
            hasLoaded: true,
            clearUserProfile: true,
            errorMessage:
                signOutResult.isSuccess ? null : signOutResult.message,
          ),
        );
      },
    );
  }

  /// Saves [updated] to the remote and refreshes the in-state profile on success.
  Future<void> updateProfile(UserProfile updated) async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    final result = await _userProfileRepository.upsertProfile(updated);

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          ),
        );
      },
      (profile) {
        emit(
          state.copyWith(
            userProfile: profile,
            isLoading: false,
            clearErrorMessage: true,
          ),
        );
      },
    );
  }

  void clearError() {
    if (state.errorMessage == null) {
      return;
    }

    emit(state.copyWith(clearErrorMessage: true));
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _loadProfile() async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    final sessionResult = await _repository.getCurrentSession();

    await sessionResult.fold(
      (failure) async {
        emit(
          state.copyWith(
            session: const AppSession.guest(),
            isLoading: false,
            hasLoaded: true,
            clearUserProfile: true,
            errorMessage: failure.message,
          ),
        );
      },
      (session) async {
        final userProfile = await _fetchUserProfile(session);

        emit(
          state.copyWith(
            session: session,
            userProfile: userProfile,
            isLoading: false,
            hasLoaded: true,
            clearErrorMessage: true,
          ),
        );
      },
    );
  }

  /// Loads the [UserProfile] when the session is authenticated; returns null
  /// for guests or when the remote is unavailable.
  Future<UserProfile?> _fetchUserProfile(AppSession session) async {
    if (!session.isAuthenticated || session.user == null) {
      return null;
    }

    final result =
        await _userProfileRepository.getProfile(session.user!.id);

    return result.fold((_) => null, (profile) => profile);
  }

  String _combineMessages({
    required String? primary,
    required String fallback,
  }) {
    if (primary == null || primary.isEmpty) {
      return fallback;
    }

    return '$primary | $fallback';
  }
}