import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/errors/exceptions.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/data/datasources/local/app_metadata_local_datasource.dart';
import 'package:fitness_tracker/data/repositories/app_settings_repository_impl.dart';
import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppMetadataLocalDataSource extends Mock
    implements AppMetadataLocalDataSource {}

void main() {
  late MockAppMetadataLocalDataSource mockDataSource;
  late AppSettingsRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockAppMetadataLocalDataSource();
    repository = AppSettingsRepositoryImpl(localDataSource: mockDataSource);
  });

  group('AppSettingsRepositoryImpl', () {
    group('getSettings', () {
      test('returns defaults when datasource returns null for all keys', () async {
        when(() => mockDataSource.readBool('settings.notifications_enabled'))
            .thenAnswer((_) async => null);
        when(() => mockDataSource.readString('settings.week_start_day'))
            .thenAnswer((_) async => null);
        when(() => mockDataSource.readString('settings.weight_unit'))
            .thenAnswer((_) async => null);

        final result = await repository.getSettings();

        expect(result.isRight(), isTrue);
        expect(
          (result as Right).value,
          const AppSettings(
            notificationsEnabled: true,
            weekStartDay: WeekStartDay.monday,
            weightUnit: WeightUnit.kilograms,
          ),
        );
      });

      test('returns parsed settings when stored values are present', () async {
        when(() => mockDataSource.readBool('settings.notifications_enabled'))
            .thenAnswer((_) async => false);
        when(() => mockDataSource.readString('settings.week_start_day'))
            .thenAnswer((_) async => 'sunday');
        when(() => mockDataSource.readString('settings.weight_unit'))
            .thenAnswer((_) async => 'pounds');

        final result = await repository.getSettings();

        expect(result.isRight(), isTrue);
        expect(
          (result as Right).value,
          const AppSettings(
            notificationsEnabled: false,
            weekStartDay: WeekStartDay.sunday,
            weightUnit: WeightUnit.pounds,
          ),
        );
      });

      test('weekStartDay defaults to monday for unrecognised value', () async {
        when(() => mockDataSource.readBool('settings.notifications_enabled'))
            .thenAnswer((_) async => true);
        when(() => mockDataSource.readString('settings.week_start_day'))
            .thenAnswer((_) async => 'wednesday');
        when(() => mockDataSource.readString('settings.weight_unit'))
            .thenAnswer((_) async => null);

        final result = await repository.getSettings();

        expect(result.isRight(), isTrue);
        expect(
          ((result as Right).value as AppSettings).weekStartDay,
          WeekStartDay.monday,
        );
      });

      test('weightUnit defaults to kilograms for unrecognised value', () async {
        when(() => mockDataSource.readBool('settings.notifications_enabled'))
            .thenAnswer((_) async => true);
        when(() => mockDataSource.readString('settings.week_start_day'))
            .thenAnswer((_) async => null);
        when(() => mockDataSource.readString('settings.weight_unit'))
            .thenAnswer((_) async => 'stones');

        final result = await repository.getSettings();

        expect(result.isRight(), isTrue);
        expect(
          ((result as Right).value as AppSettings).weightUnit,
          WeightUnit.kilograms,
        );
      });

      test('returns DatabaseFailure when datasource throws', () async {
        when(() => mockDataSource.readBool('settings.notifications_enabled'))
            .thenThrow(const CacheDatabaseException('read error'));
        when(() => mockDataSource.readString(any()))
            .thenAnswer((_) async => null);

        final result = await repository.getSettings();

        expect(result.isLeft(), isTrue);
        expect((result as Left).value, isA<DatabaseFailure>());
      });
    });

    group('saveSettings', () {
      const _settings = AppSettings(
        notificationsEnabled: false,
        weekStartDay: WeekStartDay.sunday,
        weightUnit: WeightUnit.pounds,
      );

      test('persists each field under the correct key', () async {
        when(() => mockDataSource.writeBool(
              'settings.notifications_enabled',
              false,
            )).thenAnswer((_) async {});
        when(() => mockDataSource.writeString(
              'settings.week_start_day',
              'sunday',
            )).thenAnswer((_) async {});
        when(() => mockDataSource.writeString(
              'settings.weight_unit',
              'pounds',
            )).thenAnswer((_) async {});

        final result = await repository.saveSettings(_settings);

        expect(result.isRight(), isTrue);
        verify(() => mockDataSource.writeBool(
              'settings.notifications_enabled',
              false,
            )).called(1);
        verify(() => mockDataSource.writeString(
              'settings.week_start_day',
              'sunday',
            )).called(1);
        verify(() => mockDataSource.writeString(
              'settings.weight_unit',
              'pounds',
            )).called(1);
      });

      test('returns DatabaseFailure when datasource throws', () async {
        when(() => mockDataSource.writeBool(any(), any()))
            .thenThrow(const CacheDatabaseException('write error'));
        when(() => mockDataSource.writeString(any(), any()))
            .thenAnswer((_) async {});

        final result = await repository.saveSettings(_settings);

        expect(result.isLeft(), isTrue);
        expect((result as Left).value, isA<DatabaseFailure>());
      });
    });
  });
}
