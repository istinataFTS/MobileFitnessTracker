import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/enums/data_source_preference.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/data/datasources/local/meal_local_datasource.dart';
import 'package:fitness_tracker/data/datasources/remote/meal_remote_datasource.dart';
import 'package:fitness_tracker/data/models/meal_model.dart';
import 'package:fitness_tracker/data/repositories/meal_repository_impl.dart';
import 'package:fitness_tracker/data/sync/meal_sync_coordinator.dart';
import 'package:fitness_tracker/domain/entities/meal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMealLocalDataSource extends Mock implements MealLocalDataSource {}

class MockMealRemoteDataSource extends Mock implements MealRemoteDataSource {}

class MockMealSyncCoordinator extends Mock implements MealSyncCoordinator {}

void main() {
  late MockMealLocalDataSource localDataSource;
  late MockMealRemoteDataSource remoteDataSource;
  late MockMealSyncCoordinator syncCoordinator;
  late MealRepositoryImpl repository;

  final DateTime createdAt = DateTime(2026, 3, 20, 10, 0);

  MealModel buildMealModel({
    required String id,
    required String name,
    double servingSizeGrams = 100,
    double proteinPer100g = 20,
    double carbsPer100g = 30,
    double fatPer100g = 10,
    double caloriesPer100g = 290,
  }) {
    return MealModel(
      id: id,
      name: name,
      servingSizeGrams: servingSizeGrams,
      proteinPer100g: proteinPer100g,
      carbsPer100g: carbsPer100g,
      fatPer100g: fatPer100g,
      caloriesPer100g: caloriesPer100g,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  Meal buildMealEntity({
    required String id,
    required String name,
    double servingSizeGrams = 100,
    double proteinPer100g = 20,
    double carbsPer100g = 30,
    double fatPer100g = 10,
    double caloriesPer100g = 290,
  }) {
    return Meal(
      id: id,
      name: name,
      servingSizeGrams: servingSizeGrams,
      proteinPer100g: proteinPer100g,
      carbsPer100g: carbsPer100g,
      fatPer100g: fatPer100g,
      caloriesPer100g: caloriesPer100g,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  setUp(() {
    localDataSource = MockMealLocalDataSource();
    remoteDataSource = MockMealRemoteDataSource();
    syncCoordinator = MockMealSyncCoordinator();

    repository = MealRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      syncCoordinator: syncCoordinator,
    );

    when(() => remoteDataSource.isConfigured).thenReturn(false);
    when(() => syncCoordinator.isRemoteSyncEnabled).thenReturn(false);
  });

  group('MealRepositoryImpl.getAllMeals', () {
    test('returns local meals for localOnly without touching remote', () async {
      final List<MealModel> localMeals = <MealModel>[
        buildMealModel(id: '1', name: 'Chicken Bowl'),
      ];

      when(() => localDataSource.getAllMeals()).thenAnswer(
        (_) async => localMeals,
      );

      final Either<Failure, List<Meal>> result = await repository.getAllMeals();

      expect(result, Right<Failure, List<Meal>>(localMeals));
      verify(() => localDataSource.getAllMeals()).called(1);
      verifyNever(() => remoteDataSource.getAllMeals());
      verifyNever(() => localDataSource.replaceAllMeals(any()));
    });

    test('returns empty list for remoteOnly when remote is not configured', () async {
      when(() => remoteDataSource.isConfigured).thenReturn(false);

      final Either<Failure, List<Meal>> result = await repository.getAllMeals(
        sourcePreference: DataSourcePreference.remoteOnly,
      );

      expect(result, const Right(<Meal>[]));
      verifyNever(() => remoteDataSource.getAllMeals());
      verifyNever(() => localDataSource.getAllMeals());
    });

    test('returns local data first for localThenRemote when local has items', () async {
      final List<MealModel> localMeals = <MealModel>[
        buildMealModel(id: '1', name: 'Oats'),
      ];

      when(() => localDataSource.getAllMeals()).thenAnswer(
        (_) async => localMeals,
      );
      when(() => remoteDataSource.isConfigured).thenReturn(true);

      final Either<Failure, List<Meal>> result = await repository.getAllMeals(
        sourcePreference: DataSourcePreference.localThenRemote,
      );

      expect(result, Right<Failure, List<Meal>>(localMeals));
      verify(() => localDataSource.getAllMeals()).called(1);
      verifyNever(() => remoteDataSource.getAllMeals());
      verifyNever(() => localDataSource.replaceAllMeals(any()));
    });

    test('hydrates local cache from remote for remoteThenLocal', () async {
      final List<Meal> remoteMeals = <Meal>[
        buildMealEntity(id: '1', name: 'Greek Yogurt'),
        buildMealEntity(id: '2', name: 'Chicken Bowl'),
      ];

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => remoteDataSource.getAllMeals()).thenAnswer(
        (_) async => remoteMeals,
      );
      when(() => localDataSource.replaceAllMeals(any())).thenAnswer(
        (_) async {},
      );

      final Either<Failure, List<Meal>> result = await repository.getAllMeals(
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      expect(result, Right<Failure, List<Meal>>(remoteMeals));
      verify(() => remoteDataSource.getAllMeals()).called(1);
      verify(
        () => localDataSource.replaceAllMeals(
          any(
            that: isA<List<MealModel>>().having(
              (List<MealModel> models) =>
                  models.map((MealModel model) => model.name).toList(),
              'mapped names',
              <String>['Greek Yogurt', 'Chicken Bowl'],
            ),
          ),
        ),
      ).called(1);
      verifyNever(() => localDataSource.getAllMeals());
    });
  });

  group('MealRepositoryImpl.getMealById', () {
    test('falls back to local for remoteThenLocal when remote returns null', () async {
      final MealModel localMeal = buildMealModel(id: 'meal-1', name: 'Oats');

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => remoteDataSource.getMealById('meal-1')).thenAnswer(
        (_) async => null,
      );
      when(() => localDataSource.getMealById('meal-1')).thenAnswer(
        (_) async => localMeal,
      );

      final Either<Failure, Meal?> result = await repository.getMealById(
        'meal-1',
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      expect(result, Right<Failure, Meal?>(localMeal));
      verify(() => remoteDataSource.getMealById('meal-1')).called(1);
      verify(() => localDataSource.getMealById('meal-1')).called(1);
      verifyNever(() => localDataSource.insertMeal(any()));
      verifyNever(() => localDataSource.updateMeal(any()));
    });

    test('inserts remote meal locally when missing during remoteThenLocal', () async {
      final Meal remoteMeal = buildMealEntity(id: 'meal-1', name: 'Chicken Bowl');

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => remoteDataSource.getMealById('meal-1')).thenAnswer(
        (_) async => remoteMeal,
      );
      when(() => localDataSource.getMealById('meal-1')).thenAnswer(
        (_) async => null,
      );
      when(() => localDataSource.insertMeal(any())).thenAnswer((_) async {});

      final Either<Failure, Meal?> result = await repository.getMealById(
        'meal-1',
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      expect(result, Right<Failure, Meal?>(remoteMeal));
      verify(() => remoteDataSource.getMealById('meal-1')).called(1);
      verify(() => localDataSource.getMealById('meal-1')).called(1);
      verify(
        () => localDataSource.insertMeal(
          any(
            that: isA<MealModel>().having(
              (MealModel model) => model.name,
              'name',
              'Chicken Bowl',
            ),
          ),
        ),
      ).called(1);
      verifyNever(() => localDataSource.updateMeal(any()));
    });

    test('updates existing local meal when remoteThenLocal returns newer remote meal', () async {
      final Meal remoteMeal = buildMealEntity(id: 'meal-1', name: 'Updated Bowl');
      final MealModel existingLocal = buildMealModel(id: 'meal-1', name: 'Old Bowl');

      when(() => remoteDataSource.isConfigured).thenReturn(true);
      when(() => remoteDataSource.getMealById('meal-1')).thenAnswer(
        (_) async => remoteMeal,
      );
      when(() => localDataSource.getMealById('meal-1')).thenAnswer(
        (_) async => existingLocal,
      );
      when(() => localDataSource.updateMeal(any())).thenAnswer((_) async {});

      final Either<Failure, Meal?> result = await repository.getMealById(
        'meal-1',
        sourcePreference: DataSourcePreference.remoteThenLocal,
      );

      expect(result, Right<Failure, Meal?>(remoteMeal));
      verify(() => localDataSource.updateMeal(any())).called(1);
      verifyNever(() => localDataSource.insertMeal(any()));
    });
  });

  group('MealRepositoryImpl writes', () {
    test('addMeal delegates to sync coordinator', () async {
      final Meal meal = buildMealEntity(id: 'meal-1', name: 'Chicken Bowl');

      when(() => syncCoordinator.persistAddedMeal(meal)).thenAnswer(
        (_) async {},
      );

      final Either<Failure, void> result = await repository.addMeal(meal);

      expect(result.isRight(), isTrue);
      verify(() => syncCoordinator.persistAddedMeal(meal)).called(1);
    });

    test('updateMeal delegates to sync coordinator', () async {
      final Meal meal = buildMealEntity(id: 'meal-1', name: 'Updated Bowl');

      when(() => syncCoordinator.persistUpdatedMeal(meal)).thenAnswer(
        (_) async {},
      );

      final Either<Failure, void> result = await repository.updateMeal(meal);

      expect(result.isRight(), isTrue);
      verify(() => syncCoordinator.persistUpdatedMeal(meal)).called(1);
    });

    test('deleteMeal delegates to sync coordinator', () async {
      when(() => syncCoordinator.persistDeletedMeal('meal-1')).thenAnswer(
        (_) async {},
      );

      final Either<Failure, void> result = await repository.deleteMeal('meal-1');

      expect(result.isRight(), isTrue);
      verify(() => syncCoordinator.persistDeletedMeal('meal-1')).called(1);
    });
  });
}