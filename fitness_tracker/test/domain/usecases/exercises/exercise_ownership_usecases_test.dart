import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/domain/entities/app_session.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/domain/entities/exercise.dart';
import 'package:fitness_tracker/domain/repositories/app_session_repository.dart';
import 'package:fitness_tracker/domain/repositories/exercise_repository.dart';
import 'package:fitness_tracker/domain/usecases/exercises/add_exercise.dart';
import 'package:fitness_tracker/domain/usecases/exercises/update_exercise.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExerciseRepository extends Mock implements ExerciseRepository {}

class MockAppSessionRepository extends Mock implements AppSessionRepository {}

void main() {
  late MockExerciseRepository exerciseRepository;
  late MockAppSessionRepository appSessionRepository;

  late AddExercise addExercise;
  late UpdateExercise updateExercise;

  const baseExercise = Exercise(
    id: 'exercise-1',
    name: 'Bench Press',
    muscleGroups: <String>['chest', 'triceps'],
    createdAt: DateTime(2026, 3, 26),
  );

  setUp(() {
    exerciseRepository = MockExerciseRepository();
    appSessionRepository = MockAppSessionRepository();

    addExercise = AddExercise(
      exerciseRepository,
      appSessionRepository: appSessionRepository,
    );

    updateExercise = UpdateExercise(
      exerciseRepository,
      appSessionRepository: appSessionRepository,
    );

    when(() => exerciseRepository.addExercise(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => exerciseRepository.updateExercise(any()))
        .thenAnswer((_) async => const Right(null));
  });

  test('AddExercise attaches authenticated ownerUserId before persisting',
      () async {
    when(() => appSessionRepository.getCurrentSession()).thenAnswer(
      (_) async => const Right(
        AppSession(
          authMode: AuthMode.authenticated,
          user: AppUser(
            id: 'user-1',
            email: 'user@test.com',
          ),
        ),
      ),
    );

    final result = await addExercise(baseExercise);

    expect(result, const Right(null));

    verify(
      () => exerciseRepository.addExercise(
        baseExercise.copyWith(ownerUserId: 'user-1'),
      ),
    ).called(1);
  });

  test('UpdateExercise attaches authenticated ownerUserId before persisting',
      () async {
    when(() => appSessionRepository.getCurrentSession()).thenAnswer(
      (_) async => const Right(
        AppSession(
          authMode: AuthMode.authenticated,
          user: AppUser(
            id: 'user-1',
            email: 'user@test.com',
          ),
        ),
      ),
    );

    final result = await updateExercise(baseExercise);

    expect(result, const Right(null));

    verify(
      () => exerciseRepository.updateExercise(
        baseExercise.copyWith(ownerUserId: 'user-1'),
      ),
    ).called(1);
  });

  test('AddExercise leaves exercise unchanged for guest session', () async {
    when(() => appSessionRepository.getCurrentSession()).thenAnswer(
      (_) async => const Right(AppSession.guest()),
    );

    final result = await addExercise(baseExercise);

    expect(result, const Right(null));

    verify(() => exerciseRepository.addExercise(baseExercise)).called(1);
  });

  test('UpdateExercise leaves exercise unchanged when session lookup fails',
      () async {
    when(() => appSessionRepository.getCurrentSession()).thenAnswer(
      (_) async => const Left(CacheFailure(message: 'session unavailable')),
    );

    final result = await updateExercise(baseExercise);

    expect(result, const Right(null));

    verify(() => exerciseRepository.updateExercise(baseExercise)).called(1);
  });
}
