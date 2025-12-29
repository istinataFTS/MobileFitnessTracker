import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings_phase7.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../domain/entities/time_period.dart';

/// Period selector dropdown for muscle visualization
class PeriodSelectorWidget extends StatelessWidget {
  final TimePeriod selectedPeriod;
  final ValueChanged<TimePeriod> onPeriodChanged;
  final bool enabled;

  const PeriodSelectorWidget({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderDark,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TimePeriod>(
          value: selectedPeriod,
          onChanged: enabled ? onPeriodChanged : null,
          icon: Icon(
            Icons.arrow_drop_down,
            color: enabled ? AppTheme.textLight : AppTheme.textDim,
          ),
          dropdownColor: AppTheme.surfaceDark,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: enabled ? AppTheme.textLight : AppTheme.textDim,
              ),
          items: [
            _buildMenuItem(
              context,
              value: TimePeriod.today,
              label: AppStringsPhase7.periodToday,
              icon: Icons.today,
            ),
            _buildMenuItem(
              context,
              value: TimePeriod.week,
              label: AppStringsPhase7.periodWeek,
              icon: Icons.date_range,
            ),
            _buildMenuItem(
              context,
              value: TimePeriod.month,
              label: AppStringsPhase7.periodMonth,
              icon: Icons.calendar_month,
            ),
            _buildMenuItem(
              context,
              value: TimePeriod.allTime,
              label: AppStringsPhase7.periodAllTime,
              icon: Icons.all_inclusive,
            ),
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<TimePeriod> _buildMenuItem(
    BuildContext context, {
    required TimePeriod value,
    required String label,
    required IconData icon,
  }) {
    return DropdownMenuItem<TimePeriod>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

/// Compact period selector as a segmented control (alternative design)
/// 
/// Shows period options in a horizontal segmented button layout
/// More compact than dropdown, good for limited space
class PeriodSegmentedControl extends StatelessWidget {
  final TimePeriod selectedPeriod;
  final ValueChanged<TimePeriod> onPeriodChanged;
  final bool enabled;

  const PeriodSegmentedControl({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
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
          _buildSegment(
            context,
            period: TimePeriod.today,
            label: AppStringsPhase7.periodToday,
          ),
          _buildSegment(
            context,
            period: TimePeriod.week,
            label: AppStringsPhase7.periodWeek,
          ),
          _buildSegment(
            context,
            period: TimePeriod.month,
            label: AppStringsPhase7.periodMonth,
          ),
          _buildSegment(
            context,
            period: TimePeriod.allTime,
            label: 'All',
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(
    BuildContext context, {
    required TimePeriod period,
    required String label,
  }) {
    final isSelected = selectedPeriod == period;

    return Expanded(
      child: GestureDetector(
        onTap: enabled ? () => onPeriodChanged(period) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textDim,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}