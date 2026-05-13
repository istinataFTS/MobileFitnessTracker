import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../domain/entities/voice_tool_call.dart';
import '../voice_overlay_keys.dart';

/// Confirmation card rendered when the LLM proposes a tool action.
///
/// Shows [toolCall.displaySummary] and three buttons: Yes / Edit / Cancel.
/// The caller (VoiceOverlayPage) is responsible for dispatching the
/// appropriate VoiceBloc event when a button is tapped.
class VoiceConfirmationCard extends StatelessWidget {
  const VoiceConfirmationCard({
    required this.toolCall,
    required this.onConfirm,
    required this.onEdit,
    required this.onCancel,
    super.key,
  });

  final VoiceToolCall toolCall;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: VoiceOverlayKeys.confirmationCardKey,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryOrange.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.check_circle_outline_rounded,
                color: AppTheme.primaryOrange,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                AppStrings.voiceConfirmActionLabel,
                style: TextStyle(
                  color: AppTheme.textDim,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            toolCall.displaySummary,
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: FilledButton(
                  key: VoiceOverlayKeys.confirmationYesKey,
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: AppTheme.textLight,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(AppStrings.voiceConfirmYes),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  key: VoiceOverlayKeys.confirmationEditKey,
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textMedium,
                    side: const BorderSide(color: AppTheme.borderMedium),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(AppStrings.voiceConfirmEdit),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  key: VoiceOverlayKeys.confirmationCancelKey,
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textDim,
                    side: const BorderSide(color: AppTheme.borderDark),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(AppStrings.voiceConfirmCancel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
