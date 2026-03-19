import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/domain/repositories/app_settings_repository.dart';
import 'package:fitness_tracker/presentation/settings/bloc/app_settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSettingsRepository extends Mock implements AppSettingsRepository {}

void main() {
  late MockAppSettingsRepository repository;
  late AppSettingsCubit cubit;

  const loadedSettings = AppSettings(
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

  test('ensureLoaded loads settings only once after successful load', () async {
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
      (_) async => Left(CacheFailure(message: 'settings unavailable')),
    );

    await cubit.loadSettings();

    expect(cubit.state.hasLoaded, isTrue);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.errorMessage, 'settings unavailable');
    expect(cubit.state.settings, const AppSettings.defaults());
  });

  test('saveSettings updates current state on success', () async {
    when(() => repository.saveSettings(any())).thenAnswer(
      (_) async => const Right(null),
    );

    final success = await cubit.setWeekStartDay(WeekStartDay.sunday);

    expect(success, isTrue);
    expect(cubit.state.settings.weekStartDay, WeekStartDay.sunday);
    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.hasLoaded, isTrue);
  });
}