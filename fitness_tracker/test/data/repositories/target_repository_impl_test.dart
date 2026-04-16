import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/enums/data_source_preference.dart';
import 'package:fitness_tracker/core/enums/sync_status.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/data/datasources/local/target_local_datasource.dart';
import 'package:fitness_tracker/data/datasources/remote/target_remote_datasource.dart';
import 'package:fitness_tracker/data/models/target_model.dart';
import 'package:fitness_tracker/data/repositories/target_repository_impl.dart';
import 'package:fitness_tracker/data/sync/target_sync_coordinator.dart';
import 'package:fitness_tracker/domain/entities/entity_sync_metadata.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTargetLocalDataSource extends Mock implements TargetLocalDataSource {}

class MockTargetRemoteDataSource extends Mock implements TargetRemoteDataSource {}

class MockTargetSyncCoordinator extends Mock implements TargetSyncCoordinator {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      TargetModel(
        id: 'fallback-id',
        type: TargetType.muscleSets,
        categoryKey: 'chest',
        targetValue: 12,
        unit: 'sets',
        period: TargetPeriod.weekly,
        createdAt: DateTime(2026),
      ),
    );
  });

  late MockTargetLocalDataSource localDataSource;
  late MockTargetRemoteDataSource remoteDataSource;
  late MockTargetSyncCoordinator syncCoordinator;
  late TargetRepositoryImpl repository;

  final DateTime baseDate = DateTime(2026, 3, 22, 10, 0);

  Target buildTarget({
    required String id,
    required String categoryKey,
    TargetType type = TargetType.muscleSets,
    TargetPeriod period = TargetPeriod.weekly,
    double targetValue = 12,
    EntitySyncMetadata syncMetadata = const EntitySyncMetadata(),
  }) {
    return Target(
      id: id,
      type: type,
      categoryKey: categoryKey,
      targetValue: targetValue,
      unit: type == TargetType.macro ? 'grams' : 'sets',
      period: period,
      createdAt: baseDate,
      updatedAt: baseDate,
      syncMetadata: syncMetadata,
    );
  }

  TargetModel buildTargetModel({
    required String id,
    required String categoryKey,
    TargetType type = TargetType.muscleSets,
    TargetPeriod period = TargetPeriod.weekly,
    double targetValue = 12,
    EntitySyncMetadata syncMetadata = const EntitySyncMetadata(),
  }) {
    return TargetModel(
      id: id,
      type: type,
      categoryKey: categoryKey,
      targetValue: targetValue,
      unit: type == TargetType.macro ? 'grams' : 'sets',
      period: period,
      createdAt: baseDate,
      updatedAt: baseDate,
      syncMetadata: syncMetadata,
    );
  }

  setUp(() {
    localDataSource = MockTargetLocalDataSource();
    remoteDataSource = MockTargetRemoteDataSource();
    syncCoordinator = MockTargetSyncCoordinator();

    repository = TargetRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      syncCoordinator: syncCoordinator,
    );

    when(() => remoteDataSource.isConfigured).thenReturn(false);
    when(() => syncCoordinator.isRemoteSyncEnabled).thenReturn(false);
  });

  group('TargetRepositoryImpl.getAllTargets', () {
    test('returns local targets for localOnly', () async {
      final List<TargetModel> localTargets = <TargetModel>[
        buildTargetModel(id: 'target-1', categoryKey: 'chest'),
      ];

      when(() => localDataSource.getAllTargets()).thenAnswer(
        (_) async => localTargets,
      );

      final Either<Failure, List<Target>> result =
          await repository.getAllTargets();

      expect(result, Right<Failure, List<Target>>(localTargets));
      verify(() => localDataSource.getAllTargets()).called(1);
      verifyNever(() => remoteDataSource.getAllTargets());
      verifyNever(() => localDataSource.mergeRemoteTargets(any()));
    });

    test('merges remote cache for remoteThenLocal instead of replaceAll',
        () async {
      final List<TargetModel> localTargets = <TargetModel>[
        buildTargetModel(
          id: 'target-1',
          categoryKey: 'chest',
          targetValue: 14,
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingUpdate,
          ),
        ),
      ];

      final List<Target> remoteTargets = <Target>[
        buildTarget(
          id: 'target-1',
          categoryKey: 'chest',
          targetValue: 18,
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.synced,
          ),
        ),
        buildTarget(
          id: 'target-2',
          categoryKey: 'protein',
          type: TargetType.macro,
          period: TargetPeriod.daily,
          targetValue: 180,
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.synced,
          ),
        ),
      ];

      final List<TargetModel> mergedTargets = <TargetModel>[
        localTargets.first,
        buildTargetModel(
          id: 'target-2',
          categoryKey: 'protein',
          type: TargetType.macro,
          period: TargetPeriod.daily,
          targetValue: 180,
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.synced,
          ),
        ),
      ];

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => localDataSource.getAllTargets()).thenAnswer(
        (_) async => localTargets,
      );
      when(() => remoteDataSource.getAllTargets()).thenAnswer(
        (_) async => remoteTargets,
      );
      when(() => localDataSource.mergeRemoteTargets(any())).thenAnswer(
        (_) async {},
      );
      when(() => localDataSource.getAllTargets()).thenAnswer(
        (_) async => mergedTargets,
      );

      final Either<Failure, List<Target>> result =
          await repository.getAllTargets(
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      expect(result, Right<Failure, List<Target>>(mergedTargets));
      verify(() => remoteDataSource.getAllTargets()).called(1);
      verify(() => localDataSource.mergeRemoteTargets(any())).called(1);
    });
  });

  group('TargetRepositoryImpl.getTargetById', () {
    test('returns null without remote lookup when local cache is empty',
        () async {
      when(() => localDataSource.getTargetById('target-1')).thenAnswer(
        (_) async => null,
      );

      final Either<Failure, Target?> result = await repository.getTargetById(
        'target-1',
        sourcePreference: DataSourcePreference.localThenRemote,
      );

      expect(result, const Right<Failure, Target?>(null));
      verifyNever(() => remoteDataSource.getTargetById(any()));
    });

    test('preserves pending local update over remote in remoteThenLocal',
        () async {
      final TargetModel localTarget = buildTargetModel(
        id: 'target-1',
        categoryKey: 'chest',
        targetValue: 14,
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.pendingUpdate,
        ),
      );

      final Target remoteTarget = buildTarget(
        id: 'target-1',
        categoryKey: 'chest',
        targetValue: 18,
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.synced,
        ),
      );

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => localDataSource.getTargetById('target-1')).thenAnswer(
        (_) async => localTarget,
      );
      when(() => remoteDataSource.getTargetById('target-1')).thenAnswer(
        (_) async => remoteTarget,
      );
      when(
        () => localDataSource.upsertTarget(TargetModel.fromEntity(localTarget)),
      ).thenAnswer((_) async {});

      final Either<Failure, Target?> result = await repository.getTargetById(
        'target-1',
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      expect(result, Right<Failure, Target?>(localTarget));
      verify(
        () => localDataSource.upsertTarget(TargetModel.fromEntity(localTarget)),
      ).called(1);
    });

    test('returns local cache snapshot after localThenRemote upsert', () async {
      final Target remoteTarget = buildTarget(
        id: 'target-1',
        categoryKey: 'chest',
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.synced,
        ),
      );

      final TargetModel cachedTarget = buildTargetModel(
        id: 'target-1',
        categoryKey: 'chest',
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.synced,
        ),
      );

      int localReadCount = 0;

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => localDataSource.getTargetById('target-1')).thenAnswer(
        (_) async {
          localReadCount += 1;
          return localReadCount == 1 ? null : cachedTarget;
        },
      );
      when(() => remoteDataSource.getTargetById('target-1')).thenAnswer(
        (_) async => remoteTarget,
      );
      when(() => localDataSource.upsertTarget(any())).thenAnswer(
        (_) async {},
      );

      final Either<Failure, Target?> result = await repository.getTargetById(
        'target-1',
        sourcePreference: DataSourcePreference.localThenRemote,
      );

      expect(result, Right<Failure, Target?>(cachedTarget));
      verify(() => localDataSource.getTargetById('target-1')).called(2);
      verify(() => localDataSource.upsertTarget(any())).called(1);
    });

    test('returns null when hidden pending delete remains after remote refresh',
        () async {
      final Target remoteTarget = buildTarget(
        id: 'target-1',
        categoryKey: 'chest',
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.synced,
        ),
      );

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => localDataSource.getTargetById('target-1')).thenAnswer(
        (_) async => null,
      );
      when(() => remoteDataSource.getTargetById('target-1')).thenAnswer(
        (_) async => remoteTarget,
      );
      when(() => localDataSource.upsertTarget(any())).thenAnswer(
        (_) async {},
      );

      final Either<Failure, Target?> result = await repository.getTargetById(
        'target-1',
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      expect(result, const Right<Failure, Target?>(null));
      verify(() => localDataSource.getTargetById('target-1')).called(2);
      verify(() => localDataSource.upsertTarget(any())).called(1);
    });
  });

  group('TargetRepositoryImpl writes', () {
    test('addTarget delegates to sync coordinator', () async {
      final Target target = buildTarget(
        id: 'target-1',
        categoryKey: 'chest',
      );

      when(() => syncCoordinator.persistAddedTarget(target)).thenAnswer(
        (_) async {},
      );

      final Either<Failure, void> result = await repository.addTarget(target);

      expect(result.isRight(), isTrue);
      verify(() => syncCoordinator.persistAddedTarget(target)).called(1);
    });

    test('updateTarget delegates to sync coordinator', () async {
      final Target target = buildTarget(
        id: 'target-1',
        categoryKey: 'chest',
      );

      when(() => syncCoordinator.persistUpdatedTarget(target)).thenAnswer(
        (_) async {},
      );

      final Either<Failure, void> result = await repository.updateTarget(target);

      expect(result.isRight(), isTrue);
      verify(() => syncCoordinator.persistUpdatedTarget(target)).called(1);
    });

    test('deleteTarget delegates to sync coordinator', () async {
      when(() => syncCoordinator.persistDeletedTarget('target-1')).thenAnswer(
        (_) async {},
      );

      final Either<Failure, void> result = await repository.deleteTarget(
        'target-1',
      );

      expect(result.isRight(), isTrue);
      verify(() => syncCoordinator.persistDeletedTarget('target-1')).called(1);
    });
  });
}
