import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/themes/app_theme.dart';

/// Toggle widget for switching between front and back body views
class BodyViewToggleWidget extends StatelessWidget {
  final bool isFrontView;
  final ValueChanged<bool> onViewChanged;
  final bool enabled;

  const BodyViewToggleWidget({
    super.key,
    required this.isFrontView,
    required this.onViewChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            context,
            isSelected: isFrontView,
            icon: Icons.person_outlined,
            label: AppStringsPhase7.frontView,
            onTap: () => onViewChanged(true),
          ),
          _buildToggleButton(
            context,
            isSelected: !isFrontView,
            icon: Icons.person_outline,
            label: AppStringsPhase7.backView,
            onTap: () => onViewChanged(false),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context, {
    required bool isSelected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : AppTheme.textDim,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textDim,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact icon-only toggle (alternative design)
/// 
/// More compact version without text labels
/// Suitable for space-constrained layouts
class BodyViewIconToggle extends StatelessWidget {
  final bool isFrontView;
  final ValueChanged<bool> onViewChanged;
  final bool enabled;

  const BodyViewIconToggle({
    super.key,
    required this.isFrontView,
    required this.onViewChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIconButton(
          context,
          isSelected: isFrontView,
          icon: Icons.person_outlined,
          tooltip: AppStringsPhase7.frontView,
          onTap: () => onViewChanged(true),
        ),
        const SizedBox(width: 8),
        _buildIconButton(
          context,
          isSelected: !isFrontView,
          icon: Icons.person_outline,
          tooltip: AppStringsPhase7.backView,
          onTap: () => onViewChanged(false),
        ),
      ],
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required bool isSelected,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 48,
      height: 48, // 44x44 touch target + padding
      decoration: BoxDecoration(
        color: isSelected 
            ? AppTheme.primaryOrange 
            : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? AppTheme.primaryOrange 
              : AppTheme.borderDark,
        ),
      ),
      child: IconButton(
        onPressed: enabled ? onTap : null,
        icon: Icon(
          icon,
          color: isSelected ? Colors.white : AppTheme.textDim,
          size: 24,
        ),
        tooltip: tooltip,
      ),
    );
  }
}