import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/constants/database_tables.dart';
import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/core/enums/sync_status.dart';
import 'package:fitness_tracker/data/datasources/local/database_helper.dart';
import 'package:fitness_tracker/data/datasources/local/target_local_datasource.dart';
import 'package:fitness_tracker/data/models/target_model.dart';
import 'package:fitness_tracker/domain/entities/app_session.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/domain/entities/entity_sync_metadata.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:fitness_tracker/domain/repositories/app_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockAppSessionRepository extends Mock implements AppSessionRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database database;
  late MockDatabaseHelper databaseHelper;
  late MockAppSessionRepository mockSessionRepository;
  late TargetLocalDataSourceImpl dataSource;

  final DateTime baseDate = DateTime(2026, 3, 22, 10, 0);

  TargetModel buildTarget({
    required String id,
    required String categoryKey,
    String? ownerUserId = 'user-1',
    TargetType type = TargetType.muscleSets,
    TargetPeriod period = TargetPeriod.weekly,
    double targetValue = 12,
    DateTime? updatedAt,
    EntitySyncMetadata syncMetadata = const EntitySyncMetadata(),
  }) {
    return TargetModel(
      id: id,
      ownerUserId: ownerUserId,
      type: type,
      categoryKey: categoryKey,
      targetValue: targetValue,
      unit: type == TargetType.macro ? 'grams' : 'sets',
      period: period,
      createdAt: baseDate,
      updatedAt: updatedAt ?? baseDate,
      syncMetadata: syncMetadata,
    );
  }

  Future<void> createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseTables.targets} (
        ${DatabaseTables.targetId} TEXT PRIMARY KEY,
        ${DatabaseTables.ownerUserId} TEXT,
        ${DatabaseTables.targetType} TEXT NOT NULL,
        ${DatabaseTables.targetCategoryKey} TEXT NOT NULL,
        ${DatabaseTables.targetValue} REAL NOT NULL,
        ${DatabaseTables.targetUnit} TEXT NOT NULL,
        ${DatabaseTables.targetPeriod} TEXT NOT NULL,
        ${DatabaseTables.targetCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.targetUpdatedAt} TEXT NOT NULL,
        ${DatabaseTables.targetServerId} TEXT,
        ${DatabaseTables.targetSyncStatus} TEXT NOT NULL DEFAULT 'localOnly',
        ${DatabaseTables.targetLastSyncedAt} TEXT,
        ${DatabaseTables.targetLastSyncError} TEXT
      )
    ''');
  }

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async => createSchema(db),
      ),
    );

    databaseHelper = MockDatabaseHelper();
    when(() => databaseHelper.database).thenAnswer((_) async => database);

    mockSessionRepository = MockAppSessionRepository();
    when(() => mockSessionRepository.getCurrentSession()).thenAnswer(
      (_) async => const Right(
        AppSession(
          authMode: AuthMode.authenticated,
          user: AppUser(id: 'user-1', email: 'user1@test.com'),
        ),
      ),
    );

    dataSource = TargetLocalDataSourceImpl(
      databaseHelper: databaseHelper,
      appSessionRepository: mockSessionRepository,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('TargetLocalDataSourceImpl reads', () {
    test('getAllTargets hides pendingDelete rows', () async {
      await dataSource.insertTarget(
        buildTarget(id: 'target-1', categoryKey: 'chest'),
      );
      await dataSource.insertTarget(
        buildTarget(
          id: 'target-2',
          categoryKey: 'back',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      final targets = await dataSource.getAllTargets();

      expect(targets.map((target) => target.id).toList(), <String>['target-1']);
    });

    test('getTargetById returns null for pendingDelete row', () async {
      await dataSource.insertTarget(
        buildTarget(
          id: 'target-1',
          categoryKey: 'chest',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      final target = await dataSource.getTargetById('target-1');

      expect(target, isNull);
    });

    test('getTargetByTypeAndCategory hides pendingDelete rows', () async {
      await dataSource.insertTarget(
        buildTarget(id: 'target-1', categoryKey: 'chest'),
      );
      await dataSource.insertTarget(
        buildTarget(
          id: 'target-2',
          categoryKey: 'chest',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      final target = await dataSource.getTargetByTypeAndCategory(
        TargetType.muscleSets,
        'chest',
        TargetPeriod.weekly,
      );

      expect(target, isNotNull);
      expect(target!.id, 'target-1');
    });
  });

  group('TargetLocalDataSourceImpl mergeRemoteTargets', () {
    test('preserves pending local update over newer remote row', () async {
      final localPendingTarget = buildTarget(
        id: 'target-1',
        categoryKey: 'chest',
        targetValue: 14,
        updatedAt: baseDate.add(const Duration(hours: 1)),
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.pendingUpdate,
        ),
      );

      final remoteTarget = buildTarget(
        id: 'target-1',
        categoryKey: 'chest',
        targetValue: 18,
        updatedAt: baseDate.add(const Duration(hours: 2)),
        syncMetadata: const EntitySyncMetadata(status: SyncStatus.synced),
      );

      await dataSource.insertTarget(localPendingTarget);

      await dataSource.mergeRemoteTargets(<TargetModel>[remoteTarget]);

      final targets = await dataSource.getAllTargets();
      expect(targets, hasLength(1));
      expect(targets.first.targetValue, 14);
      expect(targets.first.syncMetadata.status, SyncStatus.pendingUpdate);
    });

    test(
      'adds remote-only rows while preserving local pending upload',
      () async {
        final localPendingTarget = buildTarget(
          id: 'target-1',
          categoryKey: 'chest',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingUpload,
          ),
        );

        final remoteTarget = buildTarget(
          id: 'target-2',
          categoryKey: 'protein',
          type: TargetType.macro,
          period: TargetPeriod.daily,
          targetValue: 180,
          syncMetadata: const EntitySyncMetadata(status: SyncStatus.synced),
        );

        await dataSource.insertTarget(localPendingTarget);

        await dataSource.mergeRemoteTargets(<TargetModel>[remoteTarget]);

        final targets = await dataSource.getAllTargets();
        expect(targets.map((target) => target.id).toSet(), <String>{
          'target-1',
          'target-2',
        });
        expect(
          targets
              .firstWhere((target) => target.id == 'target-1')
              .syncMetadata
              .status,
          SyncStatus.pendingUpload,
        );
      },
    );

    test(
      'keeps pendingDelete row hidden even if remote still has it',
      () async {
        final localPendingDelete = buildTarget(
          id: 'target-1',
          categoryKey: 'chest',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        );

        final remoteTarget = buildTarget(
          id: 'target-1',
          categoryKey: 'chest',
          targetValue: 20,
          syncMetadata: const EntitySyncMetadata(status: SyncStatus.synced),
        );

        await dataSource.insertTarget(localPendingDelete);

        await dataSource.mergeRemoteTargets(<TargetModel>[remoteTarget]);

        final visibleTargets = await dataSource.getAllTargets();
        expect(visibleTargets, isEmpty);

        final rawRows = await database.query(DatabaseTables.targets);
        expect(rawRows, hasLength(1));
        expect(
          rawRows.first[DatabaseTables.targetSyncStatus],
          SyncStatus.pendingDelete.name,
        );
      },
    );
  });

  group('TargetLocalDataSourceImpl state transitions', () {
    test('markAsPendingDelete updates sync status and error', () async {
      await dataSource.insertTarget(
        buildTarget(id: 'target-1', categoryKey: 'chest'),
      );

      await dataSource.markAsPendingDelete(
        'target-1',
        errorMessage: 'delete queued',
      );

      final rawRows = await database.query(
        DatabaseTables.targets,
        where: '${DatabaseTables.targetId} = ?',
        whereArgs: <Object?>['target-1'],
      );

      expect(
        rawRows.single[DatabaseTables.targetSyncStatus],
        SyncStatus.pendingDelete.name,
      );
      expect(
        rawRows.single[DatabaseTables.targetLastSyncError],
        'delete queued',
      );
    });

    test(
      'upsertTarget inserts when missing and updates when present',
      () async {
        final inserted = buildTarget(id: 'target-1', categoryKey: 'chest');

        await dataSource.upsertTarget(inserted);

        final updated = buildTarget(
          id: 'target-1',
          categoryKey: 'chest',
          targetValue: 16,
          updatedAt: baseDate.add(const Duration(hours: 2)),
        );

        await dataSource.upsertTarget(updated);

        final target = await dataSource.getTargetById('target-1');
        expect(target, isNotNull);
        expect(target!.targetValue, 16);
      },
    );

    test('upsertTarget does not revive a pendingDelete row', () async {
      await dataSource.insertTarget(
        buildTarget(
          id: 'target-1',
          categoryKey: 'chest',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      await dataSource.upsertTarget(
        buildTarget(
          id: 'target-1',
          categoryKey: 'chest',
          targetValue: 18,
          syncMetadata: const EntitySyncMetadata(status: SyncStatus.synced),
        ),
      );

      final visibleTarget = await dataSource.getTargetById('target-1');
      expect(visibleTarget, isNull);

      final rawRows = await database.query(
        DatabaseTables.targets,
        where: '${DatabaseTables.targetId} = ?',
        whereArgs: <Object?>['target-1'],
      );
      expect(rawRows, hasLength(1));
      expect(
        rawRows.single[DatabaseTables.targetSyncStatus],
        SyncStatus.pendingDelete.name,
      );
    });
  });

  group('TargetLocalDataSourceImpl user isolation', () {
    test('getAllTargets only returns targets owned by the current user',
        () async {
      await dataSource.insertTarget(
        buildTarget(id: 'target-1', categoryKey: 'chest', ownerUserId: 'user-1'),
      );
      await dataSource.insertTarget(
        buildTarget(id: 'target-2', categoryKey: 'back', ownerUserId: 'user-2'),
      );

      final targets = await dataSource.getAllTargets();

      expect(targets.map((t) => t.id).toList(), <String>['target-1']);
    });

    test('getTargetById returns null for a target owned by another user',
        () async {
      await dataSource.insertTarget(
        buildTarget(
          id: 'target-1',
          categoryKey: 'chest',
          ownerUserId: 'user-2',
        ),
      );

      final target = await dataSource.getTargetById('target-1');

      expect(target, isNull);
    });

    test(
        'getTargetByTypeAndCategory returns null for another user\'s target',
        () async {
      await dataSource.insertTarget(
        buildTarget(
          id: 'target-1',
          categoryKey: 'chest',
          ownerUserId: 'user-2',
        ),
      );

      final target = await dataSource.getTargetByTypeAndCategory(
        TargetType.muscleSets,
        'chest',
        TargetPeriod.weekly,
      );

      expect(target, isNull);
    });
  });

  group('TargetLocalDataSourceImpl prepareForInitialCloudMigration', () {
    test('claims guest localOnly target and queues upload', () async {
      await dataSource.insertTarget(
        buildTarget(
          id: 'target-1',
          categoryKey: 'chest',
          ownerUserId: null,
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.localOnly,
            lastSyncError: 'offline',
          ),
        ),
      );

      await dataSource.prepareForInitialCloudMigration(userId: 'user-1');

      final target = await dataSource.getTargetById('target-1');
      expect(target, isNotNull);
      expect(target!.ownerUserId, 'user-1');
      expect(target.syncMetadata.status, SyncStatus.pendingUpload);
      expect(target.syncMetadata.lastSyncError, isNull);
    });

    test('recovers guest syncError target into pendingUpload', () async {
      await dataSource.insertTarget(
        buildTarget(
          id: 'target-1',
          categoryKey: 'chest',
          ownerUserId: null,
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.syncError,
            lastSyncError: 'offline',
          ),
        ),
      );

      await dataSource.prepareForInitialCloudMigration(userId: 'user-1');

      final target = await dataSource.getTargetById('target-1');
      expect(target, isNotNull);
      expect(target!.ownerUserId, 'user-1');
      expect(target.syncMetadata.status, SyncStatus.pendingUpload);
      expect(target.syncMetadata.lastSyncError, isNull);
    });
  });
}
