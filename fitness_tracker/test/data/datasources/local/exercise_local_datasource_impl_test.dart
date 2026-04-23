import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/constants/database_tables.dart';
import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/core/enums/sync_status.dart';
import 'package:fitness_tracker/data/datasources/local/database_helper.dart';
import 'package:fitness_tracker/data/datasources/local/exercise_local_datasource.dart';
import 'package:fitness_tracker/data/models/exercise_model.dart';
import 'package:fitness_tracker/domain/entities/app_session.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/domain/entities/entity_sync_metadata.dart';
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
  late MockAppSessionRepository appSessionRepository;
  late ExerciseLocalDataSourceImpl dataSource;

  const String currentUserId = 'user-1';
  const String otherUserId = 'user-2';

  final AppSession authenticatedSession = AppSession(
    authMode: AuthMode.authenticated,
    user: const AppUser(id: currentUserId, email: 'user@test.com'),
  );

  final DateTime baseDate = DateTime(2026, 3, 22, 10, 0);

  ExerciseModel buildExercise({
    required String id,
    String? ownerUserId,
    required String name,
    List<String> muscleGroups = const <String>['chest', 'triceps'],
    DateTime? updatedAt,
    EntitySyncMetadata syncMetadata = const EntitySyncMetadata(),
  }) {
    return ExerciseModel(
      id: id,
      ownerUserId: ownerUserId,
      name: name,
      muscleGroups: muscleGroups,
      createdAt: baseDate,
      updatedAt: updatedAt ?? baseDate,
      syncMetadata: syncMetadata,
    );
  }

  Future<void> createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseTables.exercises} (
        ${DatabaseTables.exerciseId} TEXT PRIMARY KEY,
        ${DatabaseTables.ownerUserId} TEXT,
        ${DatabaseTables.exerciseName} TEXT NOT NULL,
        ${DatabaseTables.exerciseMuscleGroups} TEXT NOT NULL,
        ${DatabaseTables.exerciseCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.exerciseUpdatedAt} TEXT NOT NULL,
        ${DatabaseTables.exerciseServerId} TEXT,
        ${DatabaseTables.exerciseSyncStatus} TEXT NOT NULL DEFAULT 'localOnly',
        ${DatabaseTables.exerciseLastSyncedAt} TEXT,
        ${DatabaseTables.exerciseLastSyncError} TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE ${DatabaseTables.exerciseMuscleFactors} (
        ${DatabaseTables.factorId} TEXT PRIMARY KEY,
        ${DatabaseTables.factorExerciseId} TEXT NOT NULL,
        ${DatabaseTables.factorMuscleGroup} TEXT NOT NULL,
        ${DatabaseTables.factorValue} REAL NOT NULL,
        ${DatabaseTables.factorCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseTables.factorExerciseId})
          REFERENCES ${DatabaseTables.exercises}(${DatabaseTables.exerciseId})
          ON DELETE CASCADE
      )
    ''');
    await db.execute('PRAGMA foreign_keys = ON');
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

    appSessionRepository = MockAppSessionRepository();
    when(() => appSessionRepository.getCurrentSession()).thenAnswer(
      (_) async => Right(authenticatedSession),
    );

    dataSource = ExerciseLocalDataSourceImpl(
      databaseHelper: databaseHelper,
      appSessionRepository: appSessionRepository,
    );
  });

  tearDown(() async {
    await database.close();
  });

  // ---------------------------------------------------------------------------
  // pendingDelete filtering (existing behaviour, unchanged)
  // ---------------------------------------------------------------------------

  group('ExerciseLocalDataSourceImpl reads', () {
    test('getAllExercises hides pendingDelete rows', () async {
      await dataSource.insertExercise(
        buildExercise(id: 'exercise-1', name: 'Bench Press'),
      );
      await dataSource.insertExercise(
        buildExercise(
          id: 'exercise-2',
          name: 'Cable Fly',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      final exercises = await dataSource.getAllExercises();

      expect(exercises.map((exercise) => exercise.id).toList(), <String>[
        'exercise-1',
      ]);
    });

    test('getExerciseById returns null for pendingDelete row', () async {
      await dataSource.insertExercise(
        buildExercise(
          id: 'exercise-1',
          name: 'Bench Press',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      final exercise = await dataSource.getExerciseById('exercise-1');

      expect(exercise, isNull);
    });

    test('getExerciseByName returns null for pendingDelete row', () async {
      await dataSource.insertExercise(
        buildExercise(
          id: 'exercise-1',
          name: 'Bench Press',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      final exercise = await dataSource.getExerciseByName('Bench Press');

      expect(exercise, isNull);
    });

    test('getExercisesForMuscle hides pendingDelete rows', () async {
      await dataSource.insertExercise(
        buildExercise(
          id: 'exercise-1',
          name: 'Bench Press',
          muscleGroups: const <String>['chest', 'triceps'],
        ),
      );
      await dataSource.insertExercise(
        buildExercise(
          id: 'exercise-2',
          name: 'Chest Press Machine',
          muscleGroups: const <String>['chest'],
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      final exercises = await dataSource.getExercisesForMuscle('chest');

      expect(exercises.map((exercise) => exercise.id).toList(), <String>[
        'exercise-1',
      ]);
    });
  });

  // ---------------------------------------------------------------------------
  // User isolation
  // ---------------------------------------------------------------------------

  group('ExerciseLocalDataSourceImpl user isolation', () {
    test('getAllExercises returns seeded (null owner) exercises to all users',
        () async {
      await dataSource.insertExercise(
        buildExercise(
          id: 'seeded-1',
          ownerUserId: null,
          name: 'Squat',
        ),
      );

      final exercises = await dataSource.getAllExercises();

      expect(exercises.map((e) => e.id).toList(), <String>['seeded-1']);
    });

    test('getAllExercises returns current user exercises but not other users',
        () async {
      await dataSource.insertExercise(
        buildExercise(
          id: 'mine',
          ownerUserId: currentUserId,
          name: 'My Exercise',
        ),
      );
      await dataSource.insertExercise(
        buildExercise(
          id: 'theirs',
          ownerUserId: otherUserId,
          name: 'Their Exercise',
        ),
      );
      await dataSource.insertExercise(
        buildExercise(
          id: 'seeded',
          ownerUserId: null,
          name: 'Seeded Exercise',
        ),
      );

      final exercises = await dataSource.getAllExercises();
      final ids = exercises.map((e) => e.id).toSet();

      expect(ids, containsAll(<String>['mine', 'seeded']));
      expect(ids, isNot(contains('theirs')));
    });

    test('getAllExercises returns only seeded exercises for guest session',
        () async {
      when(() => appSessionRepository.getCurrentSession()).thenAnswer(
        (_) async => const Right(AppSession.guest()),
      );

      await dataSource.insertExercise(
        buildExercise(id: 'seeded', ownerUserId: null, name: 'Squat'),
      );
      await dataSource.insertExercise(
        buildExercise(
          id: 'user-owned',
          ownerUserId: currentUserId,
          name: 'My Custom',
        ),
      );

      final exercises = await dataSource.getAllExercises();
      final ids = exercises.map((e) => e.id).toSet();

      expect(ids, contains('seeded'));
      expect(ids, isNot(contains('user-owned')));
    });

    test('getExerciseById respects owner filter', () async {
      await dataSource.insertExercise(
        buildExercise(
          id: 'theirs',
          ownerUserId: otherUserId,
          name: 'Their Exercise',
        ),
      );
      await dataSource.insertExercise(
        buildExercise(
          id: 'mine',
          ownerUserId: currentUserId,
          name: 'My Exercise',
        ),
      );

      expect(await dataSource.getExerciseById('mine'), isNotNull);
      expect(await dataSource.getExerciseById('theirs'), isNull);
    });

    test('getExerciseByName respects owner filter', () async {
      await dataSource.insertExercise(
        buildExercise(
          id: 'theirs',
          ownerUserId: otherUserId,
          name: 'Deadlift',
        ),
      );

      expect(await dataSource.getExerciseByName('Deadlift'), isNull);
    });

    test('getExercisesForMuscle respects owner filter', () async {
      await dataSource.insertExercise(
        buildExercise(
          id: 'mine',
          ownerUserId: currentUserId,
          name: 'Romanian DL',
          muscleGroups: const <String>['hamstrings'],
        ),
      );
      await dataSource.insertExercise(
        buildExercise(
          id: 'theirs',
          ownerUserId: otherUserId,
          name: 'Nordic Curl',
          muscleGroups: const <String>['hamstrings'],
        ),
      );

      final exercises = await dataSource.getExercisesForMuscle('hamstrings');
      final ids = exercises.map((e) => e.id).toSet();

      expect(ids, contains('mine'));
      expect(ids, isNot(contains('theirs')));
    });
  });

  // ---------------------------------------------------------------------------
  // clearUserOwnedExercises
  // ---------------------------------------------------------------------------

  group('ExerciseLocalDataSourceImpl clearUserOwnedExercises', () {
    test('deletes only rows owned by the given userId', () async {
      await dataSource.insertExercise(
        buildExercise(id: 'seeded', ownerUserId: null, name: 'Squat'),
      );
      await dataSource.insertExercise(
        buildExercise(
          id: 'mine',
          ownerUserId: currentUserId,
          name: 'My Exercise',
        ),
      );
      await dataSource.insertExercise(
        buildExercise(
          id: 'theirs',
          ownerUserId: otherUserId,
          name: 'Their Exercise',
        ),
      );

      await dataSource.clearUserOwnedExercises(currentUserId);

      final rawRows = await database.query(DatabaseTables.exercises);
      final ids = rawRows.map((r) => r[DatabaseTables.exerciseId]).toSet();

      // user-1's exercise is gone; seeded and other-user rows survive
      expect(ids, containsAll(<String>['seeded', 'theirs']));
      expect(ids, isNot(contains('mine')));
    });

    test('is a no-op when the user owns no exercises', () async {
      await dataSource.insertExercise(
        buildExercise(id: 'seeded', ownerUserId: null, name: 'Squat'),
      );

      await dataSource.clearUserOwnedExercises(currentUserId);

      final rawRows = await database.query(DatabaseTables.exercises);
      expect(rawRows, hasLength(1));
    });

    test('never deletes seeded exercises (ownerUserId IS NULL)', () async {
      await dataSource.insertExercise(
        buildExercise(id: 'seeded-1', ownerUserId: null, name: 'Squat'),
      );
      await dataSource.insertExercise(
        buildExercise(id: 'seeded-2', ownerUserId: null, name: 'Bench Press'),
      );
      await dataSource.insertExercise(
        buildExercise(
          id: 'mine',
          ownerUserId: currentUserId,
          name: 'My Custom',
        ),
      );

      await dataSource.clearUserOwnedExercises(currentUserId);

      final rawRows = await database.query(DatabaseTables.exercises);
      final ids = rawRows.map((r) => r[DatabaseTables.exerciseId]).toSet();

      expect(ids, containsAll(<String>['seeded-1', 'seeded-2']));
      expect(ids, isNot(contains('mine')));
    });
  });

  // ---------------------------------------------------------------------------
  // Merge (existing behaviour, unchanged)
  // ---------------------------------------------------------------------------

  group('ExerciseLocalDataSourceImpl mergeRemoteExercises', () {
    test('preserves pending local update over newer remote row', () async {
      final localPendingExercise = buildExercise(
        id: 'exercise-1',
        name: 'Bench Press Local',
        updatedAt: baseDate.add(const Duration(hours: 1)),
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.pendingUpdate,
        ),
      );

      final remoteExercise = buildExercise(
        id: 'exercise-1',
        name: 'Bench Press Remote',
        updatedAt: baseDate.add(const Duration(hours: 2)),
        syncMetadata: const EntitySyncMetadata(status: SyncStatus.synced),
      );

      await dataSource.insertExercise(localPendingExercise);

      await dataSource.mergeRemoteExercises(<ExerciseModel>[remoteExercise]);

      final exercises = await dataSource.getAllExercises();
      expect(exercises, hasLength(1));
      expect(exercises.first.name, 'Bench Press Local');
      expect(exercises.first.syncMetadata.status, SyncStatus.pendingUpdate);
    });

    test(
      'adds remote-only rows while preserving local pending upload',
      () async {
        final localPendingExercise = buildExercise(
          id: 'exercise-1',
          name: 'Bench Press',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingUpload,
          ),
        );

        final remoteExercise = buildExercise(
          id: 'exercise-2',
          name: 'Squat',
          muscleGroups: const <String>['quads', 'glutes'],
          syncMetadata: const EntitySyncMetadata(status: SyncStatus.synced),
        );

        await dataSource.insertExercise(localPendingExercise);

        await dataSource.mergeRemoteExercises(<ExerciseModel>[remoteExercise]);

        final exercises = await dataSource.getAllExercises();
        expect(exercises.map((exercise) => exercise.id).toSet(), <String>{
          'exercise-1',
          'exercise-2',
        });
        expect(
          exercises
              .firstWhere((exercise) => exercise.id == 'exercise-1')
              .syncMetadata
              .status,
          SyncStatus.pendingUpload,
        );
      },
    );

    test(
      'keeps pendingDelete row hidden even if remote still has it',
      () async {
        final localPendingDelete = buildExercise(
          id: 'exercise-1',
          name: 'Bench Press',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        );

        final remoteExercise = buildExercise(
          id: 'exercise-1',
          name: 'Bench Press Remote',
          syncMetadata: const EntitySyncMetadata(status: SyncStatus.synced),
        );

        await dataSource.insertExercise(localPendingDelete);

        await dataSource.mergeRemoteExercises(<ExerciseModel>[remoteExercise]);

        final visibleExercises = await dataSource.getAllExercises();
        expect(visibleExercises, isEmpty);

        final rawRows = await database.query(DatabaseTables.exercises);
        expect(rawRows, hasLength(1));
        expect(
          rawRows.first[DatabaseTables.exerciseSyncStatus],
          SyncStatus.pendingDelete.name,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // State transitions (existing behaviour, unchanged)
  // ---------------------------------------------------------------------------

  group('ExerciseLocalDataSourceImpl state transitions', () {
    test('markAsPendingDelete updates sync status and error', () async {
      await dataSource.insertExercise(
        buildExercise(id: 'exercise-1', name: 'Bench Press'),
      );

      await dataSource.markAsPendingDelete(
        'exercise-1',
        errorMessage: 'delete queued',
      );

      final rawRows = await database.query(
        DatabaseTables.exercises,
        where: '${DatabaseTables.exerciseId} = ?',
        whereArgs: <Object?>['exercise-1'],
      );

      expect(
        rawRows.single[DatabaseTables.exerciseSyncStatus],
        SyncStatus.pendingDelete.name,
      );
      expect(
        rawRows.single[DatabaseTables.exerciseLastSyncError],
        'delete queued',
      );
    });

    test(
      'upsertExercise inserts when missing and updates when present',
      () async {
        final inserted = buildExercise(id: 'exercise-1', name: 'Bench Press');

        await dataSource.upsertExercise(inserted);

        final updated = buildExercise(
          id: 'exercise-1',
          name: 'Bench Press Updated',
          updatedAt: baseDate.add(const Duration(hours: 2)),
        );

        await dataSource.upsertExercise(updated);

        final exercise = await dataSource.getExerciseById('exercise-1');
        expect(exercise, isNotNull);
        expect(exercise!.name, 'Bench Press Updated');
      },
    );

    test('upsertExercise does not revive a pendingDelete row', () async {
      await dataSource.insertExercise(
        buildExercise(
          id: 'exercise-1',
          name: 'Bench Press',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.pendingDelete,
          ),
        ),
      );

      await dataSource.upsertExercise(
        buildExercise(
          id: 'exercise-1',
          name: 'Bench Press Remote',
          syncMetadata: const EntitySyncMetadata(status: SyncStatus.synced),
        ),
      );

      final visibleExercise = await dataSource.getExerciseById('exercise-1');
      expect(visibleExercise, isNull);

      final rawRows = await database.query(
        DatabaseTables.exercises,
        where: '${DatabaseTables.exerciseId} = ?',
        whereArgs: <Object?>['exercise-1'],
      );
      expect(rawRows, hasLength(1));
      expect(
        rawRows.single[DatabaseTables.exerciseSyncStatus],
        SyncStatus.pendingDelete.name,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // prepareForInitialCloudMigration
  // ---------------------------------------------------------------------------

  group('ExerciseLocalDataSourceImpl prepareForInitialCloudMigration', () {
    // System exercises — never claimed or uploaded

    test('leaves system localOnly exercise unchanged', () async {
      await dataSource.insertExercise(
        buildExercise(
          id: 'exercise-1',
          ownerUserId: null,
          name: 'Bench Press',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.localOnly,
          ),
        ),
      );

      await dataSource.prepareForInitialCloudMigration(userId: 'user-1');

      final rawRows = await database.query(
        DatabaseTables.exercises,
        where: '${DatabaseTables.exerciseId} = ?',
        whereArgs: <Object?>['exercise-1'],
      );
      expect(rawRows, hasLength(1));
      expect(rawRows.single[DatabaseTables.ownerUserId], isNull);
      expect(
        rawRows.single[DatabaseTables.exerciseSyncStatus],
        SyncStatus.localOnly.name,
      );
    });

    test('leaves system syncError exercise unchanged', () async {
      await dataSource.insertExercise(
        buildExercise(
          id: 'exercise-1',
          ownerUserId: null,
          name: 'Bench Press',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.syncError,
            lastSyncError: 'prior error',
          ),
        ),
      );

      await dataSource.prepareForInitialCloudMigration(userId: 'user-1');

      final rawRows = await database.query(
        DatabaseTables.exercises,
        where: '${DatabaseTables.exerciseId} = ?',
        whereArgs: <Object?>['exercise-1'],
      );
      expect(rawRows, hasLength(1));
      expect(rawRows.single[DatabaseTables.ownerUserId], isNull);
      expect(
        rawRows.single[DatabaseTables.exerciseSyncStatus],
        SyncStatus.syncError.name,
      );
    });

    // Corruption healing — system exercises incorrectly stuck in pendingUpload
    // or pendingUpdate must be reset to localOnly so they do not block migration.

    test(
      'resets system pendingUpload exercise to localOnly (corruption heal)',
      () async {
        await dataSource.insertExercise(
          buildExercise(
            id: 'exercise-1',
            ownerUserId: null,
            name: 'Bench Press',
            syncMetadata: const EntitySyncMetadata(
              status: SyncStatus.pendingUpload,
              lastSyncError: 'prior error',
            ),
          ),
        );

        await dataSource.prepareForInitialCloudMigration(userId: 'user-1');

        final rawRows = await database.query(
          DatabaseTables.exercises,
          where: '${DatabaseTables.exerciseId} = ?',
          whereArgs: <Object?>['exercise-1'],
        );
        expect(rawRows, hasLength(1));
        expect(rawRows.single[DatabaseTables.ownerUserId], isNull);
        expect(
          rawRows.single[DatabaseTables.exerciseSyncStatus],
          SyncStatus.localOnly.name,
        );
        expect(rawRows.single[DatabaseTables.exerciseLastSyncError], isNull);
      },
    );

    test(
      'resets system pendingUpdate exercise to localOnly (corruption heal)',
      () async {
        await dataSource.insertExercise(
          buildExercise(
            id: 'exercise-1',
            ownerUserId: null,
            name: 'Bench Press',
            syncMetadata: const EntitySyncMetadata(
              status: SyncStatus.pendingUpdate,
              lastSyncError: 'prior error',
            ),
          ),
        );

        await dataSource.prepareForInitialCloudMigration(userId: 'user-1');

        final rawRows = await database.query(
          DatabaseTables.exercises,
          where: '${DatabaseTables.exerciseId} = ?',
          whereArgs: <Object?>['exercise-1'],
        );
        expect(rawRows, hasLength(1));
        expect(rawRows.single[DatabaseTables.ownerUserId], isNull);
        expect(
          rawRows.single[DatabaseTables.exerciseSyncStatus],
          SyncStatus.localOnly.name,
        );
        expect(rawRows.single[DatabaseTables.exerciseLastSyncError], isNull);
      },
    );

    // User-owned exercises — queued for upload

    test('queues user-owned localOnly exercise for upload', () async {
      await dataSource.insertExercise(
        buildExercise(
          id: 'exercise-1',
          ownerUserId: 'user-1',
          name: 'Bench Press',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.localOnly,
            lastSyncError: 'offline',
          ),
        ),
      );

      await dataSource.prepareForInitialCloudMigration(userId: 'user-1');

      final exercise = await dataSource.getExerciseById('exercise-1');
      expect(exercise, isNotNull);
      expect(exercise!.ownerUserId, 'user-1');
      expect(exercise.syncMetadata.status, SyncStatus.pendingUpload);
      expect(exercise.syncMetadata.lastSyncError, isNull);
    });

    test('recovers user-owned syncError exercise into pendingUpload', () async {
      await dataSource.insertExercise(
        buildExercise(
          id: 'exercise-1',
          ownerUserId: 'user-1',
          name: 'Bench Press',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.syncError,
            lastSyncError: 'offline',
          ),
        ),
      );

      await dataSource.prepareForInitialCloudMigration(userId: 'user-1');

      final exercise = await dataSource.getExerciseById('exercise-1');
      expect(exercise, isNotNull);
      expect(exercise!.ownerUserId, 'user-1');
      expect(exercise.syncMetadata.status, SyncStatus.pendingUpload);
      expect(exercise.syncMetadata.lastSyncError, isNull);
    });

    test('leaves user-owned synced exercise unchanged', () async {
      await dataSource.insertExercise(
        buildExercise(
          id: 'exercise-1',
          ownerUserId: 'user-1',
          name: 'Bench Press',
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.synced,
            serverId: 'server-1',
          ),
        ),
      );

      await dataSource.prepareForInitialCloudMigration(userId: 'user-1');

      final exercise = await dataSource.getExerciseById('exercise-1');
      expect(exercise, isNotNull);
      expect(exercise!.syncMetadata.status, SyncStatus.synced);
      expect(exercise.syncMetadata.serverId, 'server-1');
    });
  });

  group('factor preservation during sync', () {
    // Regression: `mergeRemoteExercises` previously did
    // `DELETE FROM exercises` + `INSERT OR REPLACE`, which cascaded via
    // `ON DELETE CASCADE` on `exercise_muscle_factors.exerciseId` and
    // wiped every muscle factor on every sync. The user then saw
    // "Set logged, but we couldn't map it to any muscle group" because
    // stimulus calculation ran before the heal hook reseeded factors.
    Future<void> seedFactor(String exerciseId, String muscle) async {
      await database.insert(DatabaseTables.exerciseMuscleFactors, {
        DatabaseTables.factorId: 'factor-$exerciseId-$muscle',
        DatabaseTables.factorExerciseId: exerciseId,
        DatabaseTables.factorMuscleGroup: muscle,
        DatabaseTables.factorValue: 1.0,
        DatabaseTables.factorCreatedAt: baseDate.toIso8601String(),
      });
    }

    Future<int> factorCountFor(String exerciseId) async {
      final rows = await database.query(
        DatabaseTables.exerciseMuscleFactors,
        where: '${DatabaseTables.factorExerciseId} = ?',
        whereArgs: <Object?>[exerciseId],
      );
      return rows.length;
    }

    test(
      'mergeRemoteExercises preserves factors for unchanged exercises',
      () async {
        await database.insert(
          DatabaseTables.exercises,
          buildExercise(
            id: 'exercise-1',
            name: 'Cable Crossover',
            syncMetadata: const EntitySyncMetadata(
              status: SyncStatus.synced,
              serverId: 'server-1',
            ),
          ).toMap(),
        );
        await seedFactor('exercise-1', 'mid_chest');
        await seedFactor('exercise-1', 'front_delts');

        await dataSource.mergeRemoteExercises(<ExerciseModel>[
          buildExercise(
            id: 'exercise-1',
            name: 'Cable Crossover',
            updatedAt: baseDate.add(const Duration(minutes: 1)),
            syncMetadata: const EntitySyncMetadata(
              status: SyncStatus.synced,
              serverId: 'server-1',
            ),
          ),
        ]);

        expect(await factorCountFor('exercise-1'), 2);
      },
    );

    test(
      'insertExercise throws on duplicate id instead of cascading factors',
      () async {
        await database.insert(
          DatabaseTables.exercises,
          buildExercise(id: 'exercise-1', name: 'Original').toMap(),
        );
        await seedFactor('exercise-1', 'mid_chest');

        await expectLater(
          dataSource.insertExercise(
            buildExercise(id: 'exercise-1', name: 'Duplicate'),
          ),
          throwsA(isA<Object>()),
        );

        expect(await factorCountFor('exercise-1'), 1);
      },
    );
  });
}
