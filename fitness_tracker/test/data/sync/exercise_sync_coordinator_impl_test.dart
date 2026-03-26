import 'package:fitness_tracker/core/enums/sync_entity_type.dart';
import 'package:fitness_tracker/core/enums/sync_status.dart';
import 'package:fitness_tracker/data/datasources/local/exercise_local_datasource.dart';
import 'package:fitness_tracker/data/datasources/local/pending_sync_delete_local_datasource.dart';
import 'package:fitness_tracker/data/datasources/remote/exercise_remote_datasource.dart';
import 'package:fitness_tracker/data/models/exercise_model.dart';
import 'package:fitness_tracker/data/sync/exercise_sync_coordinator_impl.dart';
import 'package:fitness_tracker/domain/entities/entity_sync_metadata.dart';
import 'package:fitness_tracker/domain/entities/exercise.dart';
import 'package:fitness_tracker/domain/entities/pending_sync_delete.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExerciseLocalDataSource extends Mock
    implements ExerciseLocalDataSource {}

class MockExerciseRemoteDataSource extends Mock
    implements ExerciseRemoteDataSource {}

class MockPendingSyncDeleteLocalDataSource extends Mock
    implements PendingSyncDeleteLocalDataSource {}

void main() {
  late MockExerciseLocalDataSource localDataSource;
  late MockExerciseRemoteDataSource remoteDataSource;
  late MockPendingSyncDeleteLocalDataSource pendingDeleteDataSource;
  late ExerciseSyncCoordinatorImpl coordinator;

  final DateTime baseDate = DateTime(2026, 3, 22, 10, 0);

  setUpAll(() {
    registerFallbackValue(
      PendingSyncDelete(
        id: 'fallback-delete',
        entityType: SyncEntityType.exercise,
        localEntityId: 'fallback-local-id',
        serverEntityId: 'fallback-server-id',
        createdAt: DateTime(2026, 3, 22, 10, 0),
      ),
    );
    registerFallbackValue(
      ExerciseModel(
        id: 'fallback-exercise',
        name: 'Fallback Exercise',
        muscleGroups: const <String>['chest'],
        createdAt: DateTime(2026, 3, 22, 10, 0),
      ),
    );
  });

  Exercise buildExercise({
    required String id,
    SyncStatus status = SyncStatus.synced,
    String? serverId = 'server-1',
  }) {
    return Exercise(
      id: id,
      name: 'Bench Press',
      muscleGroups: const <String>['chest', 'triceps'],
      createdAt: baseDate,
      updatedAt: baseDate,
      syncMetadata: EntitySyncMetadata(
        status: status,
        serverId: serverId,
      ),
    );
  }

  setUp(() {
    localDataSource = MockExerciseLocalDataSource();
    remoteDataSource = MockExerciseRemoteDataSource();
    pendingDeleteDataSource = MockPendingSyncDeleteLocalDataSource();

    coordinator = ExerciseSyncCoordinatorImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      pendingSyncDeleteLocalDataSource: pendingDeleteDataSource,
    );
  });

  test('delete marks synced row as pending delete before remote delete',
      () async {
    final Exercise existing = buildExercise(id: 'exercise-1');

    when(() => remoteDataSource.isConfigured).thenReturn(true);
    when(() => localDataSource.getExerciseById('exercise-1')).thenAnswer(
      (_) async => ExerciseModel.fromEntity(existing),
    );
    when(() => pendingDeleteDataSource.enqueue(any())).thenAnswer((_) async {});
    when(() => localDataSource.markAsPendingDelete('exercise-1')).thenAnswer(
      (_) async {},
    );
    when(
      () => pendingDeleteDataSource.getPendingByEntityType(
        SyncEntityType.exercise,
      ),
    ).thenAnswer(
      (_) async => <PendingSyncDelete>[
        PendingSyncDelete(
          id: 'delete-1',
          entityType: SyncEntityType.exercise,
          localEntityId: 'exercise-1',
          serverEntityId: 'server-1',
          createdAt: DateTime.now(),
        ),
      ],
    );
    when(
      () => remoteDataSource.deleteExercise(
        localId: 'exercise-1',
        serverId: 'server-1',
      ),
    ).thenAnswer((_) async {});
    when(() => pendingDeleteDataSource.remove('delete-1')).thenAnswer(
      (_) async {},
    );
    when(() => localDataSource.deleteExercise('exercise-1')).thenAnswer(
      (_) async {},
    );

    await coordinator.persistDeletedExercise('exercise-1');

    verify(() => localDataSource.markAsPendingDelete('exercise-1')).called(1);
    verify(
      () => remoteDataSource.deleteExercise(
        localId: 'exercise-1',
        serverId: 'server-1',
      ),
    ).called(1);
    verify(() => localDataSource.deleteExercise('exercise-1')).called(1);
  });

  test('delete removes purely local row immediately', () async {
    final Exercise existing = buildExercise(
      id: 'exercise-1',
      status: SyncStatus.localOnly,
      serverId: null,
    );

    when(() => remoteDataSource.isConfigured).thenReturn(false);
    when(() => localDataSource.getExerciseById('exercise-1')).thenAnswer(
      (_) async => ExerciseModel.fromEntity(existing),
    );
    when(() => localDataSource.deleteExercise('exercise-1')).thenAnswer(
      (_) async {},
    );

    await coordinator.persistDeletedExercise('exercise-1');

    verifyNever(() => localDataSource.markAsPendingDelete(any()));
    verify(() => localDataSource.deleteExercise('exercise-1')).called(1);
  });
}
