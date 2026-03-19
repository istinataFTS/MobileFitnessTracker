import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/app_settings.dart';
import '../../../domain/repositories/app_settings_repository.dart';

class AppSettingsState extends Equatable {
  const AppSettingsState({
    required this.settings,
    required this.isLoading,
    required this.isSaving,
    required this.hasLoaded,
    this.errorMessage,
  });

  final AppSettings settings;
  final bool isLoading;
  final bool isSaving;
  final bool hasLoaded;
  final String? errorMessage;

  factory AppSettingsState.initial() {
    return const AppSettingsState(
      settings: AppSettings.defaults(),
      isLoading: true,
      isSaving: false,
      hasLoaded: false,
      errorMessage: null,
    );
  }

  AppSettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
    bool? isSaving,
    bool? hasLoaded,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AppSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        settings,
        isLoading,
        isSaving,
        hasLoaded,
        errorMessage,
      ];
}

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit({
    required AppSettingsRepository repository,
  })  : _repository = repository,
        super(AppSettingsState.initial());

  final AppSettingsRepository _repository;

  Future<void> ensureLoaded() async {
    if (state.hasLoaded || state.isLoading || state.isSaving) {
      return;
    }

    await _loadSettings();
  }

  Future<void> loadSettings() async {
    await _loadSettings();
  }

  Future<void> refreshSettings() async {
    if (state.isSaving) {
      return;
    }

    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    emit(
      state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      ),
    );

    final result = await _repository.getSettings();

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            settings: const AppSettings.defaults(),
            isLoading: false,
            hasLoaded: true,
            errorMessage: failure.message,
          ),
        );
      },
      (settings) {
        emit(
          state.copyWith(
            settings: settings,
            isLoading: false,
            hasLoaded: true,
            clearErrorMessage: true,
          ),
        );
      },
    );
  }

  Future<bool> saveSettings(AppSettings nextSettings) async {
    emit(
      state.copyWith(
        isSaving: true,
        clearErrorMessage: true,
      ),
    );

    final result = await _repository.saveSettings(nextSettings);

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            isSaving: false,
            errorMessage: failure.message,
          ),
        );
        return false;
      },
      (_) {
        emit(
          state.copyWith(
            settings: nextSettings,
            isSaving: false,
            hasLoaded: true,
            clearErrorMessage: true,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> setNotificationsEnabled(bool value) {
    return saveSettings(
      state.settings.copyWith(
        notificationsEnabled: value,
      ),
    );
  }

  Future<bool> setWeekStartDay(WeekStartDay value) {
    return saveSettings(
      state.settings.copyWith(
        weekStartDay: value,
      ),
    );
  }

  Future<bool> setWeightUnit(WeightUnit value) {
    return saveSettings(
      state.settings.copyWith(
        weightUnit: value,
      ),
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