import 'package:fitness_tracker/core/constants/database_tables.dart';
import 'package:fitness_tracker/core/enums/sync_status.dart';
import 'package:fitness_tracker/data/datasources/local/database_helper.dart';
import 'package:fitness_tracker/data/datasources/local/exercise_local_datasource.dart';
import 'package:fitness_tracker/data/models/exercise_model.dart';
import 'package:fitness_tracker/domain/entities/entity_sync_metadata.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database database;
  late MockDatabaseHelper databaseHelper;
  late ExerciseLocalDataSourceImpl dataSource;

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

    dataSource = ExerciseLocalDataSourceImpl(databaseHelper: databaseHelper);
  });

  tearDown(() async {
    await database.close();
  });

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
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.synced,
        ),
      );

      await dataSource.insertExercise(localPendingExercise);

      await dataSource.mergeRemoteExercises(<ExerciseModel>[remoteExercise]);

      final exercises = await dataSource.getAllExercises();
      expect(exercises, hasLength(1));
      expect(exercises.first.name, 'Bench Press Local');
      expect(exercises.first.syncMetadata.status, SyncStatus.pendingUpdate);
    });

    test('adds remote-only rows while preserving local pending upload',
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
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.synced,
        ),
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
    });

    test('keeps pendingDelete row hidden even if remote still has it', () async {
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
        syncMetadata: const EntitySyncMetadata(
          status: SyncStatus.synced,
        ),
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
    });
  });

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

    test('upsertExercise inserts when missing and updates when present',
        () async {
      final inserted = buildExercise(
        id: 'exercise-1',
        name: 'Bench Press',
      );

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
    });

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
          syncMetadata: const EntitySyncMetadata(
            status: SyncStatus.synced,
          ),
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
}
