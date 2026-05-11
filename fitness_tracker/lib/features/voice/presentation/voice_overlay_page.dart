import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/app_session.dart';
import '../../../injection/injection_container.dart';
import '../application/voice_bloc.dart';
import '../application/voice_settings_cubit.dart';
import 'voice_overlay_keys.dart';
import 'voice_settings_page.dart';
import 'widgets/voice_budget_indicator.dart';
import 'widgets/voice_confirmation_card.dart';
import 'widgets/voice_overlay_status_view.dart';
import 'widgets/voice_transcript_list.dart';
import 'widgets/voice_workout_mode_banner.dart';

/// Full-screen voice overlay.
///
/// Scopes a fresh [VoiceBloc] instance (factory) and fires
/// [VoiceSessionStarted] on first build. The bloc orchestrates
/// STT → chat → TTS; this page is purely presentation.
class VoiceOverlayPage extends StatelessWidget {
  const VoiceOverlayPage({required this.session, super.key});

  final AppSession session;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VoiceBloc>(
      create: (_) => sl<VoiceBloc>()
        ..add(VoiceSessionStarted(session)),
      child: _VoiceOverlayView(session: session),
    );
  }
}

class _VoiceOverlayView extends StatelessWidget {
  const _VoiceOverlayView({required this.session});

  final AppSession session;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceBloc, VoiceState>(
      builder: (context, state) {
        final VoiceBloc bloc = context.read<VoiceBloc>();

        return Scaffold(
          key: VoiceOverlayKeys.overlayPageKey,
          backgroundColor: AppTheme.backgroundDark,
          body: SafeArea(
            child: Column(
              children: <Widget>[
                // ── Workout Mode banner (top, only when active) ──────────
                if (state.isWorkoutModeActive)
                  VoiceWorkoutModeBanner(
                    onToggle: () => bloc.add(
                      const VoiceWorkoutModeToggled(active: false),
                    ),
                  ),

                // ── Header ───────────────────────────────────────────────
                _OverlayHeader(
                  onClose: () => Navigator.of(context).pop(),
                  onSettings: () => _openSettings(context),
                ),

                // ── Budget indicator ─────────────────────────────────────
                const VoiceBudgetIndicator(
                  key: VoiceOverlayKeys.budgetIndicatorKey,
                ),

                // ── Transcript + confirmation card ───────────────────────
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: VoiceTranscriptList(
                          messages: state.messages,
                          liveTranscript: state.status == VoiceStatus.listening
                              ? state.liveTranscript
                              : null,
                        ),
                      ),
                      if (state.pendingConfirmation != null)
                        VoiceConfirmationCard(
                          toolCall: state.pendingConfirmation!,
                          onConfirm: () =>
                              bloc.add(const VoiceConfirmationAccepted()),
                          onEdit: () {
                            // C-5: populate a text field with the summary for editing.
                            // For now, cancel and let the user re-dictate.
                            bloc.add(const VoiceConfirmationCancelled());
                          },
                          onCancel: () =>
                              bloc.add(const VoiceConfirmationCancelled()),
                        ),
                    ],
                  ),
                ),

                // ── Status / action panel ─────────────────────────────────
                VoiceOverlayStatusView(
                  status: state.status,
                  isWorkoutModeActive: state.isWorkoutModeActive,
                  onMicTap: () => state.status == VoiceStatus.idle
                      ? bloc.add(const VoiceListenRequested())
                      : null,
                  onStopListening: () =>
                      bloc.add(const VoiceListenStopRequested()),
                  onInterrupt: () =>
                      bloc.add(const VoiceListenStopRequested()),
                  onRetry: () => bloc.add(const VoiceListenRequested()),
                  onWorkoutModeToggle: () => bloc.add(
                    VoiceWorkoutModeToggled(
                      active: !state.isWorkoutModeActive,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<VoiceSettingsCubit>(
          create: (_) => sl<VoiceSettingsCubit>(),
          child: const VoiceSettingsPage(),
        ),
      ),
    );
  }
}

class _OverlayHeader extends StatelessWidget {
  const _OverlayHeader({
    required this.onClose,
    required this.onSettings,
  });

  final VoidCallback onClose;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: <Widget>[
          IconButton(
            key: VoiceOverlayKeys.closeButtonKey,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            color: AppTheme.textMedium,
            onPressed: onClose,
            tooltip: 'Close',
          ),
          const Expanded(
            child: Text(
              AppStrings.voiceOverlayTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textLight,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            key: VoiceOverlayKeys.settingsButtonKey,
            icon: const Icon(Icons.tune_rounded),
            color: AppTheme.textMedium,
            onPressed: onSettings,
            tooltip: 'Voice settings',
          ),
        ],
      ),
    );
  }
}
