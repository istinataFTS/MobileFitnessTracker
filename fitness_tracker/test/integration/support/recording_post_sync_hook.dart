import 'package:fitness_tracker/core/sync/post_sync_hook.dart';

/// A [PostSyncHook] decorator that records every invocation into a shared
/// [callLog] before delegating to an optional [inner] hook.
///
/// Integration tests use this to assert the ordering invariant that
/// `MuscleFactorHealHook` runs before `MuscleStimulusRebuildHook` whenever
/// both of their triggering features pulled in the same run, without
/// needing to stub the real hooks' heavy dependencies.
///
/// Entries in [callLog] are `"<hookName>:run"` so the same list used by
/// [RecordingSyncFeature] can capture a single global ordering across
/// push/pull/hook phases.
class RecordingPostSyncHook implements PostSyncHook {
  RecordingPostSyncHook({
    required this.name,
    required this.triggeringFeatures,
    required this.callLog,
    this.inner,
    this.error,
  });

  @override
  final String name;

  @override
  final Set<String> triggeringFeatures;

  /// Shared ordered log of invocations. See [RecordingSyncFeature.callLog].
  final List<String> callLog;

  /// Optional real (or fake) hook to delegate to after recording. Tests that
  /// only care about ordering leave this null; tests that exercise a hook's
  /// side effects pass a real implementation.
  final PostSyncHook? inner;

  /// When non-null, the hook records its call then throws. Used to verify
  /// the orchestrator's contract that a hook failure is non-fatal.
  final Object? error;

  @override
  Future<void> run(PostSyncContext context) async {
    callLog.add('$name:run');
    if (error != null) throw error!;
    if (inner != null) await inner!.run(context);
  }
}
