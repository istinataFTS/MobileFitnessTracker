import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/enums/sync_trigger.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/core/sync/hooks/account_catalog_provision_hook.dart';
import 'package:fitness_tracker/core/sync/post_sync_hook.dart';
import 'package:fitness_tracker/domain/usecases/exercises/seed_exercises.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSeedExercises extends Mock implements SeedExercises {}

void main() {
  late _MockSeedExercises seed;
  late AccountCatalogProvisionHook hook;

  PostSyncContext contextFor(String userId, [Set<String> pulled = const {}]) =>
      PostSyncContext(
        userId: userId,
        pulledFeatures: pulled,
        trigger: SyncTrigger.initialSignIn,
      );

  setUp(() {
    seed = _MockSeedExercises();
    hook = AccountCatalogProvisionHook(seedExercises: seed);
  });

  test('is an always-run hook (no triggering features)', () {
    expect(hook.triggeringFeatures, isEmpty);
  });

  test('seeds the catalog stamped with the synced account id', () async {
    when(
      () => seed(ownerUserId: 'user-1'),
    ).thenAnswer((_) async => const Right(54));

    await hook.run(contextFor('user-1'));

    verify(() => seed(ownerUserId: 'user-1')).called(1);
  });

  test('swallows failures so the sync is not downgraded', () async {
    when(
      () => seed(ownerUserId: 'user-1'),
    ).thenAnswer((_) async => const Left(DatabaseFailure('boom')));

    await expectLater(hook.run(contextFor('user-1')), completes);
  });

  test('is idempotent — a zero-seed result is a no-op by design', () async {
    when(
      () => seed(ownerUserId: 'user-1'),
    ).thenAnswer((_) async => const Right(0));

    await hook.run(contextFor('user-1'));

    verify(() => seed(ownerUserId: 'user-1')).called(1);
  });
}
