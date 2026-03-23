import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/enums/data_source_preference.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/data/datasources/local/workout_set_local_datasource.dart';
import 'package:fitness_tracker/data/datasources/remote/workout_set_remote_datasource.dart';
import 'package:fitness_tracker/data/repositories/workout_set_repository_impl.dart';
import 'package:fitness_tracker/data/sync/workout_set_sync_coordinator.dart';
import 'package:fitness_tracker/domain/entities/workout_set.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutSetLocalDataSource extends Mock
    implements WorkoutSetLocalDataSource {}

class MockWorkoutSetRemoteDataSource extends Mock
    implements WorkoutSetRemoteDataSource {}

class MockWorkoutSetSyncCoordinator extends Mock
    implements WorkoutSetSyncCoordinator {}

void main() {
  late MockWorkoutSetLocalDataSource localDataSource;
  late MockWorkoutSetRemoteDataSource remoteDataSource;
  late MockWorkoutSetSyncCoordinator syncCoordinator;
  late WorkoutSetRepositoryImpl repository;

  final DateTime baseDate = DateTime(2026, 3, 22, 10, 0);

  WorkoutSet buildWorkoutSet({
    required String id,
    required String exerciseId,
    required DateTime date,
    int reps = 10,
    double weight = 80,
    int intensity = 8,
  }) {
    return WorkoutSet(
      id: id,
      exerciseId: exerciseId,
      reps: reps,
      weight: weight,
      intensity: intensity,
      date: date,
      createdAt: date,
      updatedAt: date,
    );
  }

  setUp(() {
    localDataSource = MockWorkoutSetLocalDataSource();
    remoteDataSource = MockWorkoutSetRemoteDataSource();
    syncCoordinator = MockWorkoutSetSyncCoordinator();

    repository = WorkoutSetRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      syncCoordinator: syncCoordinator,
    );

    when(() => remoteDataSource.isConfigured).thenReturn(false);
    when(() => syncCoordinator.isRemoteSyncEnabled).thenReturn(false);
  });

  group('WorkoutSetRepositoryImpl.getAllSets', () {
    test('returns local sets for localOnly', () async {
      final List<WorkoutSet> localSets = <WorkoutSet>[
        buildWorkoutSet(
          id: 'set-1',
          exerciseId: 'bench',
          date: baseDate,
        ),
      ];

      when(() => localDataSource.getAllSets()).thenAnswer(
        (_) async => localSets,
      );

      final Either<Failure, List<WorkoutSet>> result =
          await repository.getAllSets();

      expect(result, Right<Failure, List<WorkoutSet>>(localSets));
      verify(() => localDataSource.getAllSets()).called(1);
      verifyNever(() => remoteDataSource.getAllSets());
      verifyNever(() => localDataSource.replaceAll(any()));
    });

    test('hydrates local cache from remote for remoteThenLocal', () async {
      final List<WorkoutSet> remoteSets = <WorkoutSet>[
        buildWorkoutSet(
          id: 'set-1',
          exerciseId: 'bench',
          date: baseDate,
        ),
        buildWorkoutSet(
          id: 'set-2',
          exerciseId: 'squat',
          date: baseDate.add(const Duration(days: 1)),
        ),
      ];

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => remoteDataSource.getAllSets()).thenAnswer(
        (_) async => remoteSets,
      );
      when(() => localDataSource.replaceAll(remoteSets)).thenAnswer(
        (_) async {},
      );

      final Either<Failure, List<WorkoutSet>> result =
          await repository.getAllSets(
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      expect(result, Right<Failure, List<WorkoutSet>>(remoteSets));
      verify(() => remoteDataSource.getAllSets()).called(1);
      verify(() => localDataSource.replaceAll(remoteSets)).called(1);
      verifyNever(() => localDataSource.getAllSets());
    });
  });

  group('WorkoutSetRepositoryImpl.getSetById', () {
    test('falls back to local when remoteThenLocal returns null', () async {
      final WorkoutSet localSet = buildWorkoutSet(
        id: 'set-1',
        exerciseId: 'bench',
        date: baseDate,
      );

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => remoteDataSource.getSetById('set-1')).thenAnswer(
        (_) async => null,
      );
      when(() => localDataSource.getSetById('set-1')).thenAnswer(
        (_) async => localSet,
      );

      final Either<Failure, WorkoutSet?> result = await repository.getSetById(
        'set-1',
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      expect(result, Right<Failure, WorkoutSet?>(localSet));
      verify(() => remoteDataSource.getSetById('set-1')).called(1);
      verify(() => localDataSource.getSetById('set-1')).called(1);
      verifyNever(() => localDataSource.addSet(any()));
      verifyNever(() => localDataSource.updateSet(any()));
    });

    test('updates existing local set when remoteThenLocal returns remote value', () async {
      final WorkoutSet remoteSet = buildWorkoutSet(
        id: 'set-1',
        exerciseId: 'bench',
        date: baseDate,
        weight: 100,
      );
      final WorkoutSet existingLocal = buildWorkoutSet(
        id: 'set-1',
        exerciseId: 'bench',
        date: baseDate,
        weight: 80,
      );

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => remoteDataSource.getSetById('set-1')).thenAnswer(
        (_) async => remoteSet,
      );
      when(() => localDataSource.getSetById('set-1')).thenAnswer(
        (_) async => existingLocal,
      );
      when(() => localDataSource.updateSet(remoteSet)).thenAnswer(
        (_) async {},
      );

      final Either<Failure, WorkoutSet?> result = await repository.getSetById(
        'set-1',
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      expect(result, Right<Failure, WorkoutSet?>(remoteSet));
      verify(() => localDataSource.updateSet(remoteSet)).called(1);
      verifyNever(() => localDataSource.addSet(any()));
    });
  });

  group('WorkoutSetRepositoryImpl filtered reads', () {
    test('filters remoteThenLocal sets by exercise id', () async {
      final List<WorkoutSet> remoteSets = <WorkoutSet>[
        buildWorkoutSet(id: 'set-1', exerciseId: 'bench', date: baseDate),
        buildWorkoutSet(id: 'set-2', exerciseId: 'bench', date: baseDate),
        buildWorkoutSet(id: 'set-3', exerciseId: 'squat', date: baseDate),
      ];

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => remoteDataSource.getAllSets()).thenAnswer(
        (_) async => remoteSets,
      );
      when(() => localDataSource.replaceAll(remoteSets)).thenAnswer(
        (_) async {},
      );

      final Either<Failure, List<WorkoutSet>> result =
          await repository.getSetsByExerciseId(
        'bench',
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      result.fold(
        (_) => fail('expected Right result'),
        (List<WorkoutSet> sets) {
          expect(sets, hasLength(2));
          expect(sets.every((WorkoutSet set) => set.exerciseId == 'bench'), isTrue);
        },
      );
    });

    test('filters remoteThenLocal sets by date range', () async {
      final DateTime startDate = DateTime(2026, 3, 22);
      final DateTime endDate = DateTime(2026, 3, 23, 23, 59, 59);

      final List<WorkoutSet> remoteSets = <WorkoutSet>[
        buildWorkoutSet(id: 'set-1', exerciseId: 'bench', date: DateTime(2026, 3, 22, 9)),
        buildWorkoutSet(id: 'set-2', exerciseId: 'bench', date: DateTime(2026, 3, 23, 18)),
        buildWorkoutSet(id: 'set-3', exerciseId: 'squat', date: DateTime(2026, 3, 24, 8)),
      ];

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => remoteDataSource.getAllSets()).thenAnswer(
        (_) async => remoteSets,
      );
      when(() => localDataSource.replaceAll(remoteSets)).thenAnswer(
        (_) async {},
      );

      final Either<Failure, List<WorkoutSet>> result =
          await repository.getSetsByDateRange(
        startDate,
        endDate,
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      result.fold(
        (_) => fail('expected Right result'),
        (List<WorkoutSet> sets) {
          expect(sets, hasLength(2));
          expect(
            sets.map((WorkoutSet set) => set.id).toList(),
            <String>['set-1', 'set-2'],
          );
        },
      );
    });
  });

  group('WorkoutSetRepositoryImpl writes', () {
    test('addSet delegates to sync coordinator', () async {
      final WorkoutSet set = buildWorkoutSet(
        id: 'set-1',
        exerciseId: 'bench',
        date: baseDate,
      );

      when(() => syncCoordinator.persistAddedSet(set)).thenAnswer(
        (_) async {},
      );

      final Either<Failure, void> result = await repository.addSet(set);

      expect(result.isRight(), isTrue);
      verify(() => syncCoordinator.persistAddedSet(set)).called(1);
    });

    test('updateSet delegates to sync coordinator', () async {
      final WorkoutSet set = buildWorkoutSet(
        id: 'set-1',
        exerciseId: 'bench',
        date: baseDate,
        weight: 95,
      );

      when(() => syncCoordinator.persistUpdatedSet(set)).thenAnswer(
        (_) async {},
      );

      final Either<Failure, void> result = await repository.updateSet(set);

      expect(result.isRight(), isTrue);
      verify(() => syncCoordinator.persistUpdatedSet(set)).called(1);
    });

    test('deleteSet delegates to sync coordinator', () async {
      when(() => syncCoordinator.persistDeletedSet('set-1')).thenAnswer(
        (_) async {},
      );

      final Either<Failure, void> result = await repository.deleteSet('set-1');

      expect(result.isRight(), isTrue);
      verify(() => syncCoordinator.persistDeletedSet('set-1')).called(1);
    });

    test('syncPendingSets delegates to sync coordinator', () async {
      when(() => syncCoordinator.syncPendingChanges()).thenAnswer(
        (_) async {},
      );

      final Either<Failure, void> result = await repository.syncPendingSets();

      expect(result.isRight(), isTrue);
      verify(() => syncCoordinator.syncPendingChanges()).called(1);
    });
  });
}