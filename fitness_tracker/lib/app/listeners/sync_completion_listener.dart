import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/sync/sync_orchestrator.dart';
import '../../features/history/history.dart';
import '../../features/home/application/home_bloc.dart';
import '../../features/home/application/muscle_visual_bloc.dart';
import '../../features/log/log.dart';
import '../../injection/injection_container.dart' as di;

/// Refreshes sync-derived UI state the instant a background sync finishes.
///
/// Sync runs in the background ([AppBootstrapper] launches it unawaited), and
/// its post-sync hooks regenerate the local `muscle_stimulus` projection.
/// Without this listener the muscle map keeps showing whatever it cached
/// before the rebuild until the user manually interacts with it. Subscribing
/// to [SyncOrchestrator.onSyncCompleted] and re-dispatching the same refresh
/// events used after a local log keeps every sync-derived widget current.
///
/// Mounted inside the navigator (descendant of the user-scoped
/// [MultiBlocProvider]) and recreated per session, mirroring
/// [AppDomainEffectsListener].
class SyncCompletionListener extends StatefulWidget {
  const SyncCompletionListener({required this.child, super.key});

  final Widget child;

  @override
  State<SyncCompletionListener> createState() => _SyncCompletionListenerState();
}

class _SyncCompletionListenerState extends State<SyncCompletionListener> {
  StreamSubscription<SyncRunResult>? _syncSub;

  @override
  void initState() {
    super.initState();

    _syncSub = di.sl<SyncOrchestrator>().onSyncCompleted.listen((_) {
      if (!mounted) {
        return;
      }

      // ClearCacheEvent drops every cached period and reloads the current
      // one, so the map reflects the freshly-rebuilt projection regardless
      // of which period/mode is selected.
      context.read<MuscleVisualBloc>().add(const ClearCacheEvent());
      context.read<HomeBloc>().add(const RefreshHomeDataEvent());
      context.read<HistoryBloc>().add(const RefreshCurrentMonthEvent());
      context.read<WorkoutBloc>().add(const RefreshWeeklySetsEvent());
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
