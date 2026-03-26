import 'package:fitness_tracker/core/enums/sync_entity_type.dart';
import 'package:fitness_tracker/core/enums/sync_status.dart';
import 'package:fitness_tracker/data/datasources/local/pending_sync_delete_local_datasource.dart';
import 'package:fitness_tracker/data/datasources/local/target_local_datasource.dart';
import 'package:fitness_tracker/data/datasources/remote/target_remote_datasource.dart';
import 'package:fitness_tracker/data/models/target_model.dart';
import 'package:fitness_tracker/data/sync/target_sync_coordinator_impl.dart';
import 'package:fitness_tracker/domain/entities/entity_sync_metadata.dart';
import 'package:fitness_tracker/domain/entities/pending_sync_delete.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTargetLocalDataSource extends Mock implements TargetLocalDataSource {}

class MockTargetRemoteDataSource extends Mock implements TargetRemoteDataSource {}

class MockPendingSyncDeleteLocalDataSource extends Mock
    implements PendingSyncDeleteLocalDataSource {}

void main() {
  late MockTargetLocalDataSource localDataSource;
  late MockTargetRemoteDataSource remoteDataSource;
  late MockPendingSyncDeleteLocalDataSource pendingDeleteDataSource;
  late TargetSyncCoordinatorImpl coordinator;

  final DateTime baseDate = DateTime(2026, 3, 22, 10, 0);

  setUpAll(() {
    registerFallbackValue(
      PendingSyncDelete(
        id: 'fallback-delete',
        entityType: SyncEntityType.target,
        localEntityId: 'fallback-local-id',
        serverEntityId: 'fallback-server-id',
        createdAt: DateTime(2026, 3, 22, 10, 0),
      ),
    );
    registerFallbackValue(
      TargetModel(
        id: 'fallback-target',
        type: TargetType.muscleSets,
        categoryKey: 'chest',
        targetValue: 12,
        unit: 'sets',
        period: TargetPeriod.weekly,
        createdAt: DateTime(2026, 3, 22, 10, 0),
      ),
    );
  });

  Target buildTarget({
    required String id,
    SyncStatus status = SyncStatus.synced,
    String? serverId = 'server-1',
  }) {
    return Target(
      id: id,
      type: TargetType.muscleSets,
      categoryKey: 'chest',
      targetValue: 12,
      unit: 'sets',
      period: TargetPeriod.weekly,
      createdAt: baseDate,
      updatedAt: baseDate,
      syncMetadata: EntitySyncMetadata(
        status: status,
        serverId: serverId,
      ),
    );
  }

  setUp(() {
    localDataSource = MockTargetLocalDataSource();
    remoteDataSource = MockTargetRemoteDataSource();
    pendingDeleteDataSource = MockPendingSyncDeleteLocalDataSource();

    coordinator = TargetSyncCoordinatorImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      pendingSyncDeleteLocalDataSource: pendingDeleteDataSource,
    );
  });

  test('prepareForInitialCloudMigration delegates to local datasource', () async {
    when(
      () => localDataSource.prepareForInitialCloudMigration(userId: 'user-1'),
    ).thenAnswer((_) async {});

    await coordinator.prepareForInitialCloudMigration('user-1');

    verify(
      () => localDataSource.prepareForInitialCloudMigration(userId: 'user-1'),
    ).called(1);
    verifyNever(() => remoteDataSource.upsertTarget(any()));
  });

  test('delete marks synced row as pending delete before remote delete',
      () async {
    final Target existing = buildTarget(id: 'target-1');

    when(() => remoteDataSource.isConfigured).thenReturn(true);
    when(() => localDataSource.getTargetById('target-1')).thenAnswer(
      (_) async => TargetModel.fromEntity(existing),
    );
    when(() => pendingDeleteDataSource.enqueue(any())).thenAnswer((_) async {});
    when(() => localDataSource.markAsPendingDelete('target-1')).thenAnswer(
      (_) async {},
    );
    when(
      () => pendingDeleteDataSource.getPendingByEntityType(
        SyncEntityType.target,
      ),
    ).thenAnswer(
      (_) async => <PendingSyncDelete>[
        PendingSyncDelete(
          id: 'delete-1',
          entityType: SyncEntityType.target,
          localEntityId: 'target-1',
          serverEntityId: 'server-1',
          createdAt: DateTime.now(),
        ),
      ],
    );
    when(
      () => remoteDataSource.deleteTarget(
        localId: 'target-1',
        serverId: 'server-1',
      ),
    ).thenAnswer((_) async {});
    when(() => pendingDeleteDataSource.remove('delete-1')).thenAnswer(
      (_) async {},
    );
    when(() => localDataSource.deleteTarget('target-1')).thenAnswer(
      (_) async {},
    );

    await coordinator.persistDeletedTarget('target-1');

    verify(() => localDataSource.markAsPendingDelete('target-1')).called(1);
    verify(
      () => remoteDataSource.deleteTarget(
        localId: 'target-1',
        serverId: 'server-1',
      ),
    ).called(1);
    verify(() => localDataSource.deleteTarget('target-1')).called(1);
  });

  test('delete removes purely local row immediately', () async {
    final Target existing = buildTarget(
      id: 'target-1',
      status: SyncStatus.localOnly,
      serverId: null,
    );

    when(() => remoteDataSource.isConfigured).thenReturn(false);
    when(() => localDataSource.getTargetById('target-1')).thenAnswer(
      (_) async => TargetModel.fromEntity(existing),
    );
    when(() => localDataSource.deleteTarget('target-1')).thenAnswer(
      (_) async {},
    );

    await coordinator.persistDeletedTarget('target-1');

    verifyNever(() => localDataSource.markAsPendingDelete(any()));
    verify(() => localDataSource.deleteTarget('target-1')).called(1);
  });
}
