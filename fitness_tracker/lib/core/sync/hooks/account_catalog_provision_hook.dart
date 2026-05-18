import '../../../domain/usecases/exercises/seed_exercises.dart';
import '../../logging/app_logger.dart';
import '../post_sync_hook.dart';

/// Ensures the just-synced account owns the full default exercise catalog.
///
/// Under the per-user catalog model every account (guest `''` or a real
/// `uid`) has its own owned catalog — there is no shared NULL-owner bucket.
/// A brand-new user therefore signs in with zero owned exercises (and,
/// before sign-in adoption runs, none pulled either). Without this hook the
/// library and the workout logger would be empty for them.
///
/// [SeedExercises] is per-account idempotent: its "already seeded" check
/// reads `getAllExercises()`, which is owner-scoped, so once the account
/// owns the catalog every subsequent run is a single cheap query that
/// inserts nothing. Running it after every sync is therefore safe.
///
/// Ordering: this hook must run **before** [MuscleFactorHealHook] (factors
/// are keyed by exercise id, so the exercises must exist first) and hence
/// before [MuscleStimulusRebuildHook]. It is registered first in the
/// post-sync hook list.
///
/// Invariant: [SeedExercises] resolves "does this account already have a
/// catalog" from the *current session*, while stamping new rows with the
/// passed owner id. Post-sync hooks only run for an authenticated session
/// ([PostSyncContext.userId] is the signed-in user), so the session-owner
/// and [PostSyncContext.userId] are the same identifier — the check and the
/// stamp always agree.
class AccountCatalogProvisionHook implements PostSyncHook {
  final SeedExercises seedExercises;

  const AccountCatalogProvisionHook({required this.seedExercises});

  @override
  String get name => 'account_catalog_provision';

  /// Always-run: a new account may have pulled no features yet but still
  /// needs its catalog provisioned.
  @override
  Set<String> get triggeringFeatures => const <String>{};

  @override
  Future<void> run(PostSyncContext context) async {
    final result = await seedExercises(ownerUserId: context.userId);

    result.fold(
      (failure) => AppLogger.warning(
        'Post-sync account catalog provisioning failed: ${failure.message}',
        category: 'sync',
      ),
      (seededCount) {
        if (seededCount > 0) {
          AppLogger.info(
            'Post-sync account catalog provisioned $seededCount exercise(s) '
            'for ${context.userId}',
            category: 'sync',
          );
        }
      },
    );
  }
}
