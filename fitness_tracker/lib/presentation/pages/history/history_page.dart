import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/calendar_constants.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/error_handler.dart';
import '../../../domain/entities/workout_set.dart';
import 'bloc/history_bloc.dart';
import 'widgets/day_details_bottom_sheet.dart';
import 'widgets/history_calendar_widget.dart';

/// Calendar-based history page for viewing past workouts
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(LoadMonthSetsEvent(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        elevation: 0,
      ),
      body: BlocConsumer<HistoryBloc, HistoryState>(
        listener: (context, state) {
          if (state is HistoryError) {
            ErrorHandler.showError(
              context,
              state.message,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  context.read<HistoryBloc>().add(RefreshCurrentMonthEvent());
                },
              ),
            );
          }

          if (state is HistoryOperationSuccess) {
            ErrorHandler.showSuccess(context, state.message);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                context
                    .read<HistoryBloc>()
                    .add(LoadMonthSetsEvent(state.currentMonth));
              }
            });
          }
        },
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is HistoryLoaded || state is HistoryOperationSuccess) {
            final DateTime currentMonth;
            final Map<DateTime, List<WorkoutSet>> monthSets;
            final DateTime? selectedDate;
            final List<WorkoutSet> selectedDateSets;

            if (state is HistoryLoaded) {
              currentMonth = state.currentMonth;
              monthSets = state.monthSets;
              selectedDate = state.selectedDate;
              selectedDateSets = state.selectedDateSets;
            } else {
              final successState = state as HistoryOperationSuccess;
              currentMonth = successState.currentMonth;
              monthSets = successState.monthSets;
              selectedDate = successState.selectedDate;
              selectedDateSets = <WorkoutSet>[];
            }

            final dateCounts = <DateTime, int>{};
            for (final entry in monthSets.entries) {
              dateCounts[entry.key] = entry.value.length;
            }

            return GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! >
                        CalendarConstants.swipeThreshold) {
                  _navigateToPreviousMonth(context, currentMonth);
                } else if (details.primaryVelocity != null &&
                    details.primaryVelocity! <
                        -CalendarConstants.swipeThreshold) {
                  _navigateToNextMonth(context, currentMonth);
                }
              },
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        HistoryCalendarWidget(
                          displayedMonth: currentMonth,
                          selectedDate: selectedDate,
                          today: DateTime.now(),
                          dateSetsCount: dateCounts,
                          onDateSelected: (date) {
                            context.read<HistoryBloc>().add(SelectDateEvent(date));
                          },
                          onPreviousMonth: () {
                            _navigateToPreviousMonth(context, currentMonth);
                          },
                          onNextMonth: () {
                            _navigateToNextMonth(context, currentMonth);
                          },
                          onTodayTapped: () {
                            context
                                .read<HistoryBloc>()
                                .add(NavigateToMonthEvent(DateTime.now()));
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildInstructions(context),
                      ],
                    ),
                  ),
                  if (selectedDate != null)
                    _buildBottomSheetOverlay(
                      context,
                      selectedDate,
                      selectedDateSets,
                    ),
                ],
              ),
            );
          }

          return _buildInitialState(context);
        },
      ),
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_month,
            size: 64,
            color: AppTheme.textDim,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading history...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textMedium,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppTheme.primaryOrange,
                ),
                const SizedBox(width: 8),
                Text(
                  'How to use',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
              context,
              '• Tap a date to view workout details',
            ),
            _buildInstructionItem(
              context,
              '• Dates with workouts are highlighted',
            ),
            _buildInstructionItem(
              context,
              '• Swipe left/right to change months',
            ),
            _buildInstructionItem(
              context,
              '• Edit or delete past sets from details',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMedium,
            ),
      ),
    );
  }

  Widget _buildBottomSheetOverlay(
    BuildContext context,
    DateTime selectedDate,
    List<WorkoutSet> selectedDateSets,
  ) {
    return GestureDetector(
      onTap: () {
        context.read<HistoryBloc>().add(ClearDateSelectionEvent());
      },
      child: Container(
        color: Colors.black54,
        child: DraggableScrollableSheet(
          initialChildSize: CalendarConstants.bottomSheetMinHeight,
          minChildSize: CalendarConstants.bottomSheetMinHeight,
          maxChildSize: CalendarConstants.bottomSheetMaxHeight,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: DayDetailsBottomSheet(
                date: selectedDate,
                sets: selectedDateSets,
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToPreviousMonth(BuildContext context, DateTime currentMonth) {
    final previousMonth = DateTime(
      currentMonth.year,
      currentMonth.month - 1,
    );

    if (previousMonth.isBefore(CalendarConstants.minAllowedDate)) {
      ErrorHandler.showInfo(
        context,
        'Cannot view workouts from more than 5 years ago',
      );
      return;
    }

    context.read<HistoryBloc>().add(NavigateToMonthEvent(previousMonth));
  }

  void _navigateToNextMonth(BuildContext context, DateTime currentMonth) {
    final nextMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
    );

    final now = DateTime.now();
    final currentMonthDate = DateTime(now.year, now.month, 1);
    final nextMonthDate = DateTime(nextMonth.year, nextMonth.month, 1);

    if (nextMonthDate.isAfter(currentMonthDate)) {
      ErrorHandler.showInfo(
        context,
        'Cannot view future months',
      );
      return;
    }

    context.read<HistoryBloc>().add(NavigateToMonthEvent(nextMonth));
  }
}