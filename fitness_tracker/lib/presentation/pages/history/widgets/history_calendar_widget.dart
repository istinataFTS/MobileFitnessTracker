import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/calendar_constants.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/constants/calendar_constants.dart';

/// Custom calendar widget for displaying a month with workout indicators
/// Shows dates with workouts in a different color (Option B from requirements)
class HistoryCalendarWidget extends StatelessWidget {
  final DateTime displayedMonth;
  final DateTime? selectedDate;
  final DateTime today;
  final Map<DateTime, int> dateSetsCount; // Date -> number of sets
  final Function(DateTime) onDateSelected;
  final Function() onPreviousMonth;
  final Function() onNextMonth;
  final Function() onTodayTapped;

  const HistoryCalendarWidget({
    super.key,
    required this.displayedMonth,
    required this.selectedDate,
    required this.today,
    required this.dateSetsCount,
    required this.onDateSelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onTodayTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMonthHeader(context),
          const Divider(height: 1),
          _buildWeekdayHeaders(context),
          _buildCalendarGrid(context),
        ],
      ),
    );
  }

  /// Build month header with navigation
  Widget _buildMonthHeader(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(displayedMonth);
    final isCurrentMonth = _isSameMonth(displayedMonth, today);

    return Container(
      height: CalendarConstants.monthNavHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Previous month button
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: _canNavigateToPrevious() ? onPreviousMonth : null,
            tooltip: 'Previous Month',
          ),
          
          // Month and year
          Expanded(
            child: Text(
              monthName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          
          // Today button
          if (!isCurrentMonth)
            TextButton(
              onPressed: onTodayTapped,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Today'),
            ),
          
          // Next month button
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 28),
            onPressed: _canNavigateToNext() ? onNextMonth : null,
            tooltip: 'Next Month',
          ),
        ],
      ),
    );
  }

  /// Build weekday headers (S M T W T F S)
  Widget _buildWeekdayHeaders(BuildContext context) {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    
    return Container(
      height: CalendarConstants.weekdayHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textDim,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build calendar grid with dates
  Widget _buildCalendarGrid(BuildContext context) {
    final firstDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 0);
    
    // Get the weekday of the first day (0 = Monday, 6 = Sunday)
    // Adjust to (0 = Sunday, 6 = Saturday)
    int firstWeekday = firstDayOfMonth.weekday % 7;
    
    // Calculate total cells needed
    final totalDays = lastDayOfMonth.day;
    final totalCells = (firstWeekday + totalDays);
    final rows = (totalCells / 7).ceil();
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: List.generate(rows, (rowIndex) {
          return Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - firstWeekday + 1;
              
              // Check if this cell should show a date
              if (dayNumber < 1 || dayNumber > totalDays) {
                return const Expanded(child: SizedBox());
              }
              
              final date = DateTime(displayedMonth.year, displayedMonth.month, dayNumber);
              return Expanded(
                child: _buildDateCell(context, date),
              );
            }),
          );
        }),
      ),
    );
  }

  /// Build individual date cell
  Widget _buildDateCell(BuildContext context, DateTime date) {
    final isToday = _isSameDay(date, today);
    final isSelected = selectedDate != null && _isSameDay(date, selectedDate!);
    final setsCount = dateSetsCount[date] ?? 0;
    final hasWorkouts = setsCount > 0;
    final isFutureDate = date.isAfter(today);

    // Determine background color
    Color? backgroundColor;
    if (isSelected) {
      backgroundColor = AppTheme.primaryOrange.withOpacity(0.2);
    } else if (hasWorkouts) {
      backgroundColor = AppTheme.primaryOrange.withOpacity(0.1);
    }

    // Determine border color
    Color? borderColor;
    if (isToday) {
      borderColor = AppTheme.primaryOrange;
    } else if (isSelected) {
      borderColor = AppTheme.primaryOrange.withOpacity(0.5);
    }

    return GestureDetector(
      onTap: isFutureDate ? null : () => onDateSelected(date),
      child: Container(
        height: CalendarConstants.dayItemHeight,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: borderColor != null
              ? Border.all(
                  color: borderColor,
                  width: isToday ? CalendarConstants.todayBorderWidth : 1,
                )
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Date number
            Center(
              child: Text(
                '${date.day}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isFutureDate
                          ? AppTheme.textDim
                          : hasWorkouts
                              ? AppTheme.textLight
                              : AppTheme.textMedium,
                      fontWeight: isToday || hasWorkouts
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
              ),
            ),
            
            // Workout indicator dot (if has workouts)
            if (hasWorkouts)
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: CalendarConstants.dateIndicatorSize,
                    height: CalendarConstants.dateIndicatorSize,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Check if can navigate to previous month
  bool _canNavigateToPrevious() {
    final previousMonth = DateTime(displayedMonth.year, displayedMonth.month - 1);
    return previousMonth.isAfter(CalendarConstants.minAllowedDate);
  }

  /// Check if can navigate to next month
  bool _canNavigateToNext() {
    final nextMonth = DateTime(displayedMonth.year, displayedMonth.month + 1);
    final firstDayOfNext = DateTime(nextMonth.year, nextMonth.month, 1);
    return firstDayOfNext.isBefore(CalendarConstants.maxAllowedDate);
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Check if two dates are in the same month
  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }
}