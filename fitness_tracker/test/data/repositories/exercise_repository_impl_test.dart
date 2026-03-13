import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fitness_tracker/core/errors/exceptions.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/data/datasources/local/exercise_local_datasource.dart';
import 'package:fitness_tracker/data/models/exercise_model.dart';
import 'package:fitness_tracker/data/repositories/exercise_repository_impl.dart';
import 'package:fitness_tracker/domain/entities/exercise.dart';

class MockExerciseLocalDataSource extends Mock
    implements ExerciseLocalDataSource {}

class FakeExerciseModel extends Fake implements ExerciseModel {}

void main() {
  late ExerciseRepositoryImpl repository;
  late MockExerciseLocalDataSource localDataSource;

  const testExercise = Exercise(
    id: 'exercise-1',
    name: 'Bench Press',
    muscleGroups: ['mid-chest', 'front-delts', 'triceps'],
    createdAt: DateTime(2025, 1, 1),
  );

  const testExerciseModel = ExerciseModel(
    id: 'exercise-1',
    name: 'Bench Press',
    muscleGroups: ['mid-chest', 'front-delts', 'triceps'],
    createdAt: DateTime(2025, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(FakeExerciseModel());
  });

  setUp(() {
    localDataSource = MockExerciseLocalDataSource();
    repository = ExerciseRepositoryImpl(
      localDataSource: localDataSource,
    );
  });

  group('getAllExercises', () {
    test('returns exercises when datasource succeeds', () async {
      when(() => localDataSource.getAllExercises())
          .thenAnswer((_) async => [testExerciseModel]);

      final result = await repository.getAllExercises();

      expect(result, const Right([testExerciseModel]));
      verify(() => localDataSource.getAllExercises()).called(1);
      verifyNoMoreInteractions(localDataSource);
    });

    test('returns DatabaseFailure when datasource throws CacheDatabaseException',
        () async {
      when(() => localDataSource.getAllExercises()).thenThrow(
        const CacheDatabaseException('Failed to load exercises'),
      );

      final result = await repository.getAllExercises();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<DatabaseFailure>());
          expect(failure.message, 'Failed to load exercises');
        },
        (_) => fail('Expected a failure result'),
      );
      verify(() => localDataSource.getAllExercises()).called(1);
    });
  });

  group('addExercise', () {
    test('converts entity to model and inserts it', () async {
      when(() => localDataSource.insertExercise(any()))
          .thenAnswer((_) async {});

      final result = await repository.addExercise(testExercise);

      expect(result, const Right(null));
      verify(
        () => localDataSource.insertExercise(
          const ExerciseModel(
            id: 'exercise-1',
            name: 'Bench Press',
            muscleGroups: ['mid-chest', 'front-delts', 'triceps'],
            createdAt: DateTime(2025, 1, 1),
          ),
        ),
      ).called(1);
      verifyNoMoreInteractions(localDataSource);
    });

    test('returns DatabaseFailure when insert throws CacheDatabaseException',
        () async {
      when(() => localDataSource.insertExercise(any())).thenThrow(
        const CacheDatabaseException('Insert failed'),
      );

      final result = await repository.addExercise(testExercise);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<DatabaseFailure>());
          expect(failure.message, 'Insert failed');
        },
        (_) => fail('Expected a failure result'),
      );
      verify(() => localDataSource.insertExercise(any())).called(1);
    });
  });

  group('deleteExercise', () {
    test('delegates delete to datasource', () async {
      when(() => localDataSource.deleteExercise('exercise-1'))
          .thenAnswer((_) async {});

      final result = await repository.deleteExercise('exercise-1');

      expect(result, const Right(null));
      verify(() => localDataSource.deleteExercise('exercise-1')).called(1);
      verifyNoMoreInteractions(localDataSource);
    });

    test('returns UnexpectedFailure for unknown errors', () async {
      when(() => localDataSource.deleteExercise('exercise-1'))
          .thenThrow(StateError('unexpected delete issue'));

      final result = await repository.deleteExercise('exercise-1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<UnexpectedFailure>());
          expect(
            failure.message,
            'Unexpected error: Bad state: unexpected delete issue',
          );
        },
        (_) => fail('Expected a failure result'),
      );
      verify(() => localDataSource.deleteExercise('exercise-1')).called(1);
    });
  });
}