import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/enums/data_source_preference.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/data/datasources/local/nutrition_log_local_datasource.dart';
import 'package:fitness_tracker/data/datasources/remote/nutrition_log_remote_datasource.dart';
import 'package:fitness_tracker/data/models/nutrition_log_model.dart';
import 'package:fitness_tracker/data/repositories/nutrition_log_repository_impl.dart';
import 'package:fitness_tracker/data/sync/nutrition_log_sync_coordinator.dart';
import 'package:fitness_tracker/domain/entities/nutrition_log.dart';
import 'package:fitness_tracker/domain/repositories/nutrition_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNutritionLogLocalDataSource extends Mock
    implements NutritionLogLocalDataSource {}

class MockNutritionLogRemoteDataSource extends Mock
    implements NutritionLogRemoteDataSource {}

class MockNutritionLogSyncCoordinator extends Mock
    implements NutritionLogSyncCoordinator {}

void main() {
  late MockNutritionLogLocalDataSource localDataSource;
  late MockNutritionLogRemoteDataSource remoteDataSource;
  late MockNutritionLogSyncCoordinator syncCoordinator;
  late NutritionLogRepositoryImpl repository;

  final DateTime targetDate = DateTime(2026, 3, 21, 12, 0);

  NutritionLogModel buildLogModel({
    required String id,
    required DateTime loggedAt,
    String? mealId,
    String mealName = 'Chicken Bowl',
    double? gramsConsumed = 100,
    double protein = 25,
    double carbs = 30,
    double fat = 10,
    double calories = 310,
  }) {
    return NutritionLogModel(
      id: id,
      mealId: mealId,
      mealName: mealName,
      gramsConsumed: gramsConsumed,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      calories: calories,
      loggedAt: loggedAt,
      createdAt: loggedAt,
      updatedAt: loggedAt,
    );
  }

  NutritionLog buildLogEntity({
    required String id,
    required DateTime loggedAt,
    String? mealId,
    String mealName = 'Chicken Bowl',
    double? gramsConsumed = 100,
    double protein = 25,
    double carbs = 30,
    double fat = 10,
    double calories = 310,
  }) {
    return NutritionLog(
      id: id,
      mealId: mealId,
      mealName: mealName,
      gramsConsumed: gramsConsumed,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      calories: calories,
      loggedAt: loggedAt,
      createdAt: loggedAt,
      updatedAt: loggedAt,
    );
  }

  setUp(() {
    localDataSource = MockNutritionLogLocalDataSource();
    remoteDataSource = MockNutritionLogRemoteDataSource();
    syncCoordinator = MockNutritionLogSyncCoordinator();

    repository = NutritionLogRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      syncCoordinator: syncCoordinator,
    );

    when(() => remoteDataSource.isConfigured).thenReturn(false);
    when(() => syncCoordinator.isRemoteSyncEnabled).thenReturn(false);
  });

  group('NutritionLogRepositoryImpl.getAllLogs', () {
    test('returns local logs for localOnly without touching remote', () async {
      final List<NutritionLogModel> localLogs = <NutritionLogModel>[
        buildLogModel(id: '1', loggedAt: targetDate),
      ];

      when(() => localDataSource.getAllLogs()).thenAnswer(
        (_) async => localLogs,
      );

      final Either<Failure, List<NutritionLog>> result =
          await repository.getAllLogs();

      expect(result, Right<Failure, List<NutritionLog>>(localLogs));
      verify(() => localDataSource.getAllLogs()).called(1);
      verifyNever(() => remoteDataSource.getAllLogs());
      verifyNever(() => localDataSource.replaceAllLogs(any()));
    });

    test('hydrates local cache from remote for remoteThenLocal', () async {
      final List<NutritionLog> remoteLogs = <NutritionLog>[
        buildLogEntity(id: '1', loggedAt: targetDate),
        buildLogEntity(
          id: '2',
          loggedAt: targetDate.add(const Duration(hours: 2)),
          protein: 35,
          carbs: 20,
          fat: 15,
          calories: 355,
        ),
      ];

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => remoteDataSource.getAllLogs()).thenAnswer(
        (_) async => remoteLogs,
      );
      when(() => localDataSource.replaceAllLogs(any())).thenAnswer(
        (_) async {},
      );

      final Either<Failure, List<NutritionLog>> result =
          await repository.getAllLogs(
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      expect(result, Right<Failure, List<NutritionLog>>(remoteLogs));
      verify(() => remoteDataSource.getAllLogs()).called(1);
      verify(() => localDataSource.replaceAllLogs(any())).called(1);
      verifyNever(() => localDataSource.getAllLogs());
    });
  });

  group('NutritionLogRepositoryImpl.getLogById', () {
    test('falls back to local when remoteThenLocal returns null', () async {
      final NutritionLogModel localLog =
          buildLogModel(id: 'log-1', loggedAt: targetDate);

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => remoteDataSource.getLogById('log-1')).thenAnswer(
        (_) async => null,
      );
      when(() => localDataSource.getLogById('log-1')).thenAnswer(
        (_) async => localLog,
      );

      final Either<Failure, NutritionLog?> result = await repository.getLogById(
        'log-1',
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      expect(result, Right<Failure, NutritionLog?>(localLog));
      verify(() => remoteDataSource.getLogById('log-1')).called(1);
      verify(() => localDataSource.getLogById('log-1')).called(1);
      verifyNever(() => localDataSource.insertLog(any()));
      verifyNever(() => localDataSource.updateLog(any()));
    });

    test('updates existing local log when remoteThenLocal returns remote value', () async {
      final NutritionLog remoteLog = buildLogEntity(
        id: 'log-1',
        loggedAt: targetDate,
        calories: 420,
      );
      final NutritionLogModel existingLocal = buildLogModel(
        id: 'log-1',
        loggedAt: targetDate,
        calories: 310,
      );

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => remoteDataSource.getLogById('log-1')).thenAnswer(
        (_) async => remoteLog,
      );
      when(() => localDataSource.getLogById('log-1')).thenAnswer(
        (_) async => existingLocal,
      );
      when(() => localDataSource.updateLog(any())).thenAnswer((_) async {});

      final Either<Failure, NutritionLog?> result = await repository.getLogById(
        'log-1',
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      expect(result, Right<Failure, NutritionLog?>(remoteLog));
      verify(() => localDataSource.updateLog(any())).called(1);
      verifyNever(() => localDataSource.insertLog(any()));
    });
  });

  group('NutritionLogRepositoryImpl.getDailyMacros', () {
    test('returns local datasource macros when remote is not configured', () async {
      when(() => remoteDataSource.isConfigured).thenReturn(false);
      when(() => localDataSource.getDailyMacros(targetDate)).thenAnswer(
        (_) async => <String, double>{
          'totalCarbs': 80,
          'totalProtein': 60,
          'totalFat': 20,
          'totalCalories': 740,
          'logsCount': 2,
        },
      );

      final Either<Failure, DailyMacros> result =
          await repository.getDailyMacros(
        targetDate,
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      result.fold(
        (_) => fail('expected Right result'),
        (DailyMacros macros) {
          expect(macros.totalCarbs, 80);
          expect(macros.totalProtein, 60);
          expect(macros.totalFat, 20);
          expect(macros.totalCalories, 740);
          expect(macros.logsCount, 2);
          expect(macros.date, targetDate);
        },
      );

      verify(() => localDataSource.getDailyMacros(targetDate)).called(1);
      verifyNever(() => remoteDataSource.getLogsByDate(any()));
    });

    test('aggregates remote logs into daily macros when remote is configured', () async {
      final List<NutritionLog> remoteLogs = <NutritionLog>[
        buildLogEntity(
          id: '1',
          loggedAt: targetDate,
          protein: 25,
          carbs: 40,
          fat: 10,
          calories: 350,
        ),
        buildLogEntity(
          id: '2',
          loggedAt: targetDate.add(const Duration(hours: 3)),
          protein: 35,
          carbs: 20,
          fat: 15,
          calories: 355,
        ),
      ];

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => remoteDataSource.getLogsByDate(targetDate)).thenAnswer(
        (_) async => remoteLogs,
      );

      final Either<Failure, DailyMacros> result =
          await repository.getDailyMacros(
        targetDate,
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      result.fold(
        (_) => fail('expected Right result'),
        (DailyMacros macros) {
          expect(macros.totalProtein, 60);
          expect(macros.totalCarbs, 60);
          expect(macros.totalFat, 25);
          expect(macros.totalCalories, 705);
          expect(macros.logsCount, 2);
          expect(macros.date, targetDate);
        },
      );

      verify(() => remoteDataSource.getLogsByDate(targetDate)).called(1);
      verifyNever(() => localDataSource.getDailyMacros(any()));
    });
  });

  group('NutritionLogRepositoryImpl deletes and writes', () {
    test('deleteLogsByDate delegates each matching log deletion to sync coordinator', () async {
      final List<NutritionLogModel> dateLogs = <NutritionLogModel>[
        buildLogModel(id: 'log-1', loggedAt: targetDate),
        buildLogModel(
          id: 'log-2',
          loggedAt: targetDate.add(const Duration(hours: 2)),
        ),
      ];

      when(() => localDataSource.getLogsByDate(targetDate)).thenAnswer(
        (_) async => dateLogs,
      );
      when(() => syncCoordinator.persistDeletedLog(any())).thenAnswer(
        (_) async {},
      );

      final Either<Failure, void> result =
          await repository.deleteLogsByDate(targetDate);

      expect(result.isRight(), isTrue);
      verify(() => localDataSource.getLogsByDate(targetDate)).called(1);
      verify(() => syncCoordinator.persistDeletedLog('log-1')).called(1);
      verify(() => syncCoordinator.persistDeletedLog('log-2')).called(1);
    });

    test('addLog delegates to sync coordinator', () async {
      final NutritionLog log = buildLogEntity(id: 'log-1', loggedAt: targetDate);

      when(() => syncCoordinator.persistAddedLog(log)).thenAnswer(
        (_) async {},
      );

      final Either<Failure, void> result = await repository.addLog(log);

      expect(result.isRight(), isTrue);
      verify(() => syncCoordinator.persistAddedLog(log)).called(1);
    });

    test('updateLog delegates to sync coordinator', () async {
      final NutritionLog log = buildLogEntity(
        id: 'log-1',
        loggedAt: targetDate,
        calories: 420,
      );

      when(() => syncCoordinator.persistUpdatedLog(log)).thenAnswer(
        (_) async {},
      );

      final Either<Failure, void> result = await repository.updateLog(log);

      expect(result.isRight(), isTrue);
      verify(() => syncCoordinator.persistUpdatedLog(log)).called(1);
    });

    test('deleteLog delegates to sync coordinator', () async {
      when(() => syncCoordinator.persistDeletedLog('log-1')).thenAnswer(
        (_) async {},
      );

      final Either<Failure, void> result = await repository.deleteLog('log-1');

      expect(result.isRight(), isTrue);
      verify(() => syncCoordinator.persistDeletedLog('log-1')).called(1);
    });
  });
}