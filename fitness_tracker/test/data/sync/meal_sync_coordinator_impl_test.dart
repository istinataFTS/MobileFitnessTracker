import 'package:fitness_tracker/core/enums/sync_entity_type.dart';
import 'package:fitness_tracker/core/enums/sync_status.dart';
import 'package:fitness_tracker/data/datasources/local/meal_local_datasource.dart';
import 'package:fitness_tracker/data/datasources/local/pending_sync_delete_local_datasource.dart';
import 'package:fitness_tracker/data/datasources/remote/meal_remote_datasource.dart';
import 'package:fitness_tracker/data/sync/meal_sync_coordinator_impl.dart';
import 'package:fitness_tracker/domain/entities/entity_sync_metadata.dart';
import 'package:fitness_tracker/domain/entities/meal.dart';
import 'package:fitness_tracker/domain/entities/pending_sync_delete.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMealLocalDataSource extends Mock implements MealLocalDataSource {}

class MockMealRemoteDataSource extends Mock implements MealRemoteDataSource {}

class MockPendingSyncDeleteLocalDataSource extends Mock
    implements PendingSyncDeleteLocalDataSource {}

void main() {
  late MockMealLocalDataSource localDataSource;
  late MockMealRemoteDataSource remoteDataSource;
  late MockPendingSyncDeleteLocalDataSource pendingDeleteDataSource;
  late MealSyncCoordinatorImpl coordinator;

  final DateTime baseDate = DateTime(2026, 3, 22, 10, 0);

  Meal buildMeal({
    required String id,
    SyncStatus status = SyncStatus.synced,
    String? serverId = 'server-1',
  }) {
    return Meal(
      id: id,
      name: 'Chicken Bowl',
      servingSizeGrams: 100,
      proteinPer100g: 20,
      carbsPer100g: 30,
      fatPer100g: 10,
      caloriesPer100g: 290,
      createdAt: baseDate,
      updatedAt: baseDate,
      syncMetadata: EntitySyncMetadata(
        status: status,
        serverId: serverId,
      ),
    );
  }

  setUp(() {
    localDataSource = MockMealLocalDataSource();
    remoteDataSource = MockMealRemoteDataSource();
    pendingDeleteDataSource = MockPendingSyncDeleteLocalDataSource();

    coordinator = MealSyncCoordinatorImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      pendingSyncDeleteLocalDataSource: pendingDeleteDataSource,
    );
  });

  test('delete marks synced row as pending delete before remote delete',
      () async {
    final Meal existing = buildMeal(id: 'meal-1');

    when(() => remoteDataSource.isConfigured).thenReturn(true);
    when(() => localDataSource.getMealById('meal-1')).thenAnswer(
      (_) async => existing,
    );
    when(() => pendingDeleteDataSource.enqueue(any())).thenAnswer((_) async {});
    when(() => localDataSource.markAsPendingDelete('meal-1')).thenAnswer(
      (_) async {},
    );
    when(
      () => pendingDeleteDataSource.getPendingByEntityType(
        SyncEntityType.meal,
      ),
    ).thenAnswer(
      (_) async => <PendingSyncDelete>[
        PendingSyncDelete(
          id: 'delete-1',
          entityType: SyncEntityType.meal,
          localEntityId: 'meal-1',
          serverEntityId: 'server-1',
          createdAt: DateTime.now(),
        ),
      ],
    );
    when(
      () => remoteDataSource.deleteMeal(
        localId: 'meal-1',
        serverId: 'server-1',
      ),
    ).thenAnswer((_) async {});
    when(() => pendingDeleteDataSource.remove('delete-1')).thenAnswer(
      (_) async {},
    );
    when(() => localDataSource.deleteMeal('meal-1')).thenAnswer((_) async {});

    await coordinator.persistDeletedMeal('meal-1');

    verify(() => localDataSource.markAsPendingDelete('meal-1')).called(1);
    verify(() => remoteDataSource.deleteMeal(
          localId: 'meal-1',
          serverId: 'server-1',
        )).called(1);
    verify(() => localDataSource.deleteMeal('meal-1')).called(1);
  });

  test('delete removes purely local row immediately', () async {
    final Meal existing = buildMeal(
      id: 'meal-1',
      status: SyncStatus.localOnly,
      serverId: null,
    );

    when(() => remoteDataSource.isConfigured).thenReturn(false);
    when(() => localDataSource.getMealById('meal-1')).thenAnswer(
      (_) async => existing,
    );
    when(() => localDataSource.deleteMeal('meal-1')).thenAnswer((_) async {});

    await coordinator.persistDeletedMeal('meal-1');

    verifyNever(() => localDataSource.markAsPendingDelete(any()));
    verify(() => localDataSource.deleteMeal('meal-1')).called(1);
  });

  test('failed remote delete keeps queued delete for retry', () async {
    final Meal existing = buildMeal(id: 'meal-1');

    when(() => remoteDataSource.isConfigured).thenReturn(true);
    when(() => localDataSource.getMealById('meal-1')).thenAnswer(
      (_) async => existing,
    );
    when(() => pendingDeleteDataSource.enqueue(any())).thenAnswer((_) async {});
    when(() => localDataSource.markAsPendingDelete('meal-1')).thenAnswer(
      (_) async {},
    );
    when(
      () => pendingDeleteDataSource.getPendingByEntityType(
        SyncEntityType.meal,
      ),
    ).thenAnswer(
      (_) async => <PendingSyncDelete>[
        PendingSyncDelete(
          id: 'delete-1',
          entityType: SyncEntityType.meal,
          localEntityId: 'meal-1',
          serverEntityId: 'server-1',
          createdAt: DateTime.now(),
        ),
      ],
    );
    when(
      () => remoteDataSource.deleteMeal(
        localId: 'meal-1',
        serverId: 'server-1',
      ),
    ).thenThrow(StateError('network'));
    when(
      () => pendingDeleteDataSource.markAttempted(
        'delete-1',
        attemptedAt: any(named: 'attemptedAt'),
        errorMessage: 'Bad state: network',
      ),
    ).thenAnswer((_) async {});

    await coordinator.persistDeletedMeal('meal-1');

    verify(() => localDataSource.markAsPendingDelete('meal-1')).called(1);
    verifyNever(() => localDataSource.deleteMeal('meal-1'));
    verify(() => pendingDeleteDataSource.markAttempted(
          'delete-1',
          attemptedAt: any(named: 'attemptedAt'),
          errorMessage: 'Bad state: network',
        )).called(1);
  });
}