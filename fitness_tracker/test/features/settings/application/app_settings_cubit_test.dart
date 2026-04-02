import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/domain/repositories/app_settings_repository.dart';
import 'package:fitness_tracker/features/settings/application/app_settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSettingsRepository extends Mock implements AppSettingsRepository {}

void main() {
  late MockAppSettingsRepository repository;
  late AppSettingsCubit cubit;

  const AppSettings loadedSettings = AppSettings(
    notificationsEnabled: false,
    weekStartDay: WeekStartDay.sunday,
    weightUnit: WeightUnit.pounds,
  );

  setUp(() {
    repository = MockAppSettingsRepository();
    cubit = AppSettingsCubit(repository: repository);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('initial state uses defaults and starts idle until loaded', () {
    expect(cubit.state.settings, const AppSettings.defaults());
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.hasLoaded, isFalse);
    expect(cubit.state.errorMessage, isNull);
  });

  test('ensureLoaded triggers first load when not loaded yet', () async {
    when(() => repository.getSettings()).thenAnswer(
      (_) async => const Right(loadedSettings),
    );

    await cubit.ensureLoaded();

    verify(() => repository.getSettings()).called(1);
    expect(cubit.state.settings, loadedSettings);
    expect(cubit.state.hasLoaded, isTrue);
    expect(cubit.state.isLoading, isFalse);
  });

  test('ensureLoaded does not load twice after successful load', () async {
    when(() => repository.getSettings()).thenAnswer(
      (_) async => const Right(loadedSettings),
    );

    await cubit.ensureLoaded();
    await cubit.ensureLoaded();

    verify(() => repository.getSettings()).called(1);
    expect(cubit.state.settings, loadedSettings);
    expect(cubit.state.hasLoaded, isTrue);
    expect(cubit.state.isLoading, isFalse);
  });

  test('loadSettings stores failure and marks state as loaded', () async {
    when(() => repository.getSettings()).thenAnswer(
      (_) async => const Left(CacheFailure('settings unavailable')),
    );

    await cubit.loadSettings();

    expect(cubit.state.hasLoaded, isTrue);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.errorMessage, 'settings unavailable');
    expect(cubit.state.settings, const AppSettings.defaults());
  });

  test('refreshSettings reloads current settings from repository', () async {
    when(() => repository.getSettings()).thenAnswer(
      (_) async => const Right(loadedSettings),
    );

    await cubit.refreshSettings();

    verify(() => repository.getSettings()).called(1);
    expect(cubit.state.settings, loadedSettings);
    expect(cubit.state.hasLoaded, isTrue);
    expect(cubit.state.isLoading, isFalse);
  });

  test('refreshSettings does nothing while saving is in progress', () async {
    when(() => repository.saveSettings(any())).thenAnswer(
      (_) async => const Right(null),
    );

    final Future<bool> saveFuture =
        cubit.saveSettings(const AppSettings.defaults());

    await Future<void>.delayed(Duration.zero);

    await cubit.refreshSettings();

    verifyNever(() => repository.getSettings());

    await saveFuture;
    expect(cubit.state.isSaving, isFalse);
  });

  test('saveSettings updates current state on success', () async {
    when(() => repository.saveSettings(any())).thenAnswer(
      (_) async => const Right(null),
    );

    final bool success = await cubit.setWeekStartDay(WeekStartDay.sunday);

    expect(success, isTrue);
    expect(cubit.state.settings.weekStartDay, WeekStartDay.sunday);
    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.hasLoaded, isTrue);
  });

  test('setNotificationsEnabled updates only notifications field', () async {
    when(() => repository.saveSettings(any())).thenAnswer(
      (_) async => const Right(null),
    );

    await cubit.saveSettings(
      const AppSettings(
        notificationsEnabled: true,
        weekStartDay: WeekStartDay.monday,
        weightUnit: WeightUnit.kilograms,
      ),
    );

    final bool success = await cubit.setNotificationsEnabled(false);

    expect(success, isTrue);
    expect(
      cubit.state.settings,
      const AppSettings(
        notificationsEnabled: false,
        weekStartDay: WeekStartDay.monday,
        weightUnit: WeightUnit.kilograms,
      ),
    );
  });

  test('setWeightUnit updates only weight unit field', () async {
    when(() => repository.saveSettings(any())).thenAnswer(
      (_) async => const Right(null),
    );

    await cubit.saveSettings(
      const AppSettings(
        notificationsEnabled: true,
        weekStartDay: WeekStartDay.sunday,
        weightUnit: WeightUnit.kilograms,
      ),
    );

    final bool success = await cubit.setWeightUnit(WeightUnit.pounds);

    expect(success, isTrue);
    expect(
      cubit.state.settings,
      const AppSettings(
        notificationsEnabled: true,
        weekStartDay: WeekStartDay.sunday,
        weightUnit: WeightUnit.pounds,
      ),
    );
  });

  test('saveSettings stores error and returns false on failure', () async {
    when(() => repository.saveSettings(any())).thenAnswer(
      (_) async => const Left(CacheFailure('save failed')),
    );

    final bool success = await cubit.setWeightUnit(WeightUnit.pounds);

    expect(success, isFalse);
    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.errorMessage, 'save failed');
  });

  test('successful load clears previous error message', () async {
    when(() => repository.getSettings()).thenAnswer(
      (_) async => const Left(CacheFailure('settings unavailable')),
    );

    await cubit.loadSettings();
    expect(cubit.state.errorMessage, 'settings unavailable');

    when(() => repository.getSettings()).thenAnswer(
      (_) async => const Right(loadedSettings),
    );

    await cubit.loadSettings();

    expect(cubit.state.settings, loadedSettings);
    expect(cubit.state.errorMessage, isNull);
  });

  test('clearError removes an existing error message', () async {
    when(() => repository.getSettings()).thenAnswer(
      (_) async => const Left(CacheFailure('settings unavailable')),
    );

    await cubit.loadSettings();
    expect(cubit.state.errorMessage, 'settings unavailable');

    cubit.clearError();

    expect(cubit.state.errorMessage, isNull);
  });

  test('clearError is a no-op when there is no error', () {
    cubit.clearError();

    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state, AppSettingsState.initial());
  });
}