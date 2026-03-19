import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/app_session.dart';
import '../../../domain/repositories/app_session_repository.dart';

class ProfileState extends Equatable {
  const ProfileState({
    required this.session,
    required this.isLoading,
    required this.hasLoaded,
    this.errorMessage,
  });

  final AppSession session;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;

  factory ProfileState.initial() {
    return const ProfileState(
      session: AppSession.guest(),
      isLoading: false,
      hasLoaded: false,
      errorMessage: null,
    );
  }

  ProfileState copyWith({
    AppSession? session,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ProfileState(
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        session,
        isLoading,
        hasLoaded,
        errorMessage,
      ];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required AppSessionRepository repository,
  })  : _repository = repository,
        super(ProfileState.initial());

  final AppSessionRepository _repository;

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
    await _loadProfile();
  }

  Future<void> _loadProfile() async {
    emit(
      state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      ),
    );

    final result = await _repository.getCurrentSession();

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            session: const AppSession.guest(),
            isLoading: false,
            hasLoaded: true,
            errorMessage: failure.message,
          ),
        );
      },
      (session) {
        emit(
          state.copyWith(
            session: session,
            isLoading: false,
            hasLoaded: true,
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

    emit(
      state.copyWith(
        clearErrorMessage: true,
      ),
    );
  }
}