import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../domain/entities/app_session.dart';
import '../voice_overlay_keys.dart';
import '../voice_overlay_page.dart';

/// Persistent floating action button that opens the voice overlay.
///
/// When [isWakeWordArmed] is true the button pulses to signal that the
/// wake-word engine is listening. Guest users see the button disabled with
/// a tooltip; authenticated users tap to open [VoiceOverlayPage].
class VoiceFab extends StatefulWidget {
  const VoiceFab({
    required this.session,
    this.isWakeWordArmed = false,
    super.key,
  });

  final AppSession session;
  final bool isWakeWordArmed;

  @override
  State<VoiceFab> createState() => _VoiceFabState();
}

class _VoiceFabState extends State<VoiceFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    if (widget.isWakeWordArmed) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWakeWordArmed != oldWidget.isWakeWordArmed) {
      if (widget.isWakeWordArmed) {
        _pulseController.repeat();
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openOverlay() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            VoiceOverlayPage(session: widget.session),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        barrierColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = widget.session.isGuest;
    final String tooltip = isGuest
        ? AppStrings.voiceFabTooltipGuest
        : AppStrings.voiceFabTooltipOpen;

    return Tooltip(
      message: isGuest ? tooltip : '',
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Pulse ring — only visible when armed
          if (widget.isWakeWordArmed)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),
          FloatingActionButton(
            key: VoiceOverlayKeys.fabKey,
            onPressed: isGuest ? null : _openOverlay,
            tooltip: tooltip,
            backgroundColor: isGuest
                ? AppTheme.surfaceMedium
                : AppTheme.primaryOrange,
            foregroundColor: isGuest
                ? AppTheme.textDisabled
                : AppTheme.textLight,
            elevation: 4,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.isWakeWordArmed ? Icons.mic : Icons.mic_none_rounded,
                key: ValueKey<bool>(widget.isWakeWordArmed),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
