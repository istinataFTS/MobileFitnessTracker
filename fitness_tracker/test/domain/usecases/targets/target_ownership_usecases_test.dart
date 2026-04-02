import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/domain/entities/app_session.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:fitness_tracker/domain/repositories/app_session_repository.dart';
import 'package:fitness_tracker/domain/repositories/target_repository.dart';
import 'package:fitness_tracker/domain/usecases/targets/add_target.dart';
import 'package:fitness_tracker/domain/usecases/targets/update_target.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTargetRepository extends Mock implements TargetRepository {}

class MockAppSessionRepository extends Mock implements AppSessionRepository {}

void main() {
  late MockTargetRepository targetRepository;
  late MockAppSessionRepository appSessionRepository;

  late AddTarget addTarget;
  late UpdateTarget updateTarget;

  final baseTarget = Target(
    id: 'target-1',
    type: TargetType.macro,
    categoryKey: 'protein',
    targetValue: 180,
    unit: 'g',
    period: TargetPeriod.daily,
    createdAt: DateTime(2026, 3, 26),
  );

  setUp(() {
    targetRepository = MockTargetRepository();
    appSessionRepository = MockAppSessionRepository();

    addTarget = AddTarget(
      targetRepository,
      appSessionRepository: appSessionRepository,
    );

    updateTarget = UpdateTarget(
      targetRepository,
      appSessionRepository: appSessionRepository,
    );

    when(() => targetRepository.addTarget(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => targetRepository.updateTarget(any()))
        .thenAnswer((_) async => const Right(null));
  });

  test('AddTarget attaches authenticated ownerUserId before persisting',
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

    final result = await addTarget(baseTarget);

    expect(result, const Right(null));

    verify(
      () => targetRepository.addTarget(
        baseTarget.copyWith(ownerUserId: 'user-1'),
      ),
    ).called(1);
  });

  test('UpdateTarget attaches authenticated ownerUserId before persisting',
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

    final result = await updateTarget(baseTarget);

    expect(result, const Right(null));

    verify(
      () => targetRepository.updateTarget(
        baseTarget.copyWith(ownerUserId: 'user-1'),
      ),
    ).called(1);
  });

  test('AddTarget leaves target unchanged for guest session', () async {
    when(() => appSessionRepository.getCurrentSession()).thenAnswer(
      (_) async => const Right(AppSession.guest()),
    );

    final result = await addTarget(baseTarget);

    expect(result, const Right(null));

    verify(() => targetRepository.addTarget(baseTarget)).called(1);
  });

  test('UpdateTarget leaves target unchanged when session lookup fails',
      () async {
    when(() => appSessionRepository.getCurrentSession()).thenAnswer(
      (_) async => const Left(CacheFailure('session unavailable')),
    );

    final result = await updateTarget(baseTarget);

    expect(result, const Right(null));

    verify(() => targetRepository.updateTarget(baseTarget)).called(1);
  });
}