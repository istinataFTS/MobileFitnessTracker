import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/enums/sync_trigger.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/core/sync/hooks/muscle_stimulus_rebuild_hook.dart';
import 'package:fitness_tracker/core/sync/post_sync_hook.dart';
import 'package:fitness_tracker/domain/usecases/muscle_stimulus/rebuild_muscle_stimulus_from_workout_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRebuildMuscleStimulus extends Mock
    implements RebuildMuscleStimulusFromWorkoutHistory {}

void main() {
  late _MockRebuildMuscleStimulus rebuild;
  late MuscleStimulusRebuildHook hook;

  PostSyncContext contextFor({
    required String userId,
    required Set<String> pulled,
  }) =>
      PostSyncContext(
        userId: userId,
        pulledFeatures: pulled,
        trigger: SyncTrigger.appLaunch,
      );

  setUp(() {
    rebuild = _MockRebuildMuscleStimulus();
    hook = MuscleStimulusRebuildHook(rebuild: rebuild);
  });

  test('declares itself as triggering on exercises or workout_sets pulls', () {
    expect(
      hook.triggeringFeatures,
      equals(<String>{'exercises', 'workout_sets'}),
    );
  });

  test('rebuilds for the context user — other profiles are never touched',
      () async {
    when(() => rebuild('user-42')).thenAnswer((_) async => const Right(null));

    await hook.run(
      contextFor(userId: 'user-42', pulled: const {'workout_sets'}),
    );

    verify(() => rebuild('user-42')).called(1);
  });

  test('swallows failures so the sync is not downgraded', () async {
    when(() => rebuild(any()))
        .thenAnswer((_) async => const Left(DatabaseFailure('boom')));

    await expectLater(
      hook.run(contextFor(userId: 'user-1', pulled: const {'exercises'})),
      completes,
    );
  });
}
