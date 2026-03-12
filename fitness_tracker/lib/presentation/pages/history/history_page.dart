import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/calendar_constants.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/error_handler.dart';
import '../../../domain/entities/nutrition_log.dart';
import '../../../domain/entities/workout_set.dart';
import 'bloc/history_bloc.dart';
import 'widgets/day_details_bottom_sheet.dart';
import 'widgets/history_calendar_widget.dart';
import 'widgets/nutrition_day_details_bottom_sheet.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  StreamSubscription<HistoryUiEffect>? _historyEffectsSub;

  @override
  void initState() {
    super.initState();

    final historyBloc = context.read<HistoryBloc>();

    _historyEffectsSub = historyBloc.effects.listen((effect) {
      if (!mounted) return;

      if (effect is HistorySuccessEffect) {
        ErrorHandler.showSuccess(context, effect.message);
      }
    });

    historyBloc.add(LoadMonthSetsEvent(DateTime.now()));
  }

  @override
  void dispose() {
    _historyEffectsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        elevation: 0,
      ),
      body: BlocConsumer<HistoryBloc, HistoryState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is HistoryLoaded) {
            return _buildLoadedState(context, state);
          }

          return _buildInitialState(context);
        },
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, HistoryLoaded state) {
    final dateCounts = <DateTime, int>{};

    if (state.currentMode == HistoryMode.workouts) {
      for (final entry in state.monthSets.entries) {
        dateCounts[entry.key] = entry.value.length;
      }
    } else {
      for (final entry in state.monthNutritionLogs.entries) {
        dateCounts[entry.key] = entry.value.length;
      }
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! > CalendarConstants.swipeThreshold) {
          _navigateToPreviousMonth(context, state.currentMonth);
        } else if (details.primaryVelocity != null &&
            details.primaryVelocity! < -CalendarConstants.swipeThreshold) {
          _navigateToNextMonth(context, state.currentMonth);
        }
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildModeToggle(context, state.currentMode),
                const SizedBox(height: 20),
                HistoryCalendarWidget(
                  displayedMonth: state.currentMonth,
                  selectedDate: state.selectedDate,
                  today: DateTime.now(),
                  dateSetsCount: dateCounts,
                  onDateSelected: (date) {
                    context.read<HistoryBloc>().add(SelectDateEvent(date));
                  },
                  onPreviousMonth: () {
                    _navigateToPreviousMonth(context, state.currentMonth);
                  },
                  onNextMonth: () {
                    _navigateToNextMonth(context, state.currentMonth);
                  },
                  onTodayTapped: () {
                    context
                        .read<HistoryBloc>()
                        .add(NavigateToMonthEvent(DateTime.now()));
                  },
                ),
                const SizedBox(height: 24),
                _buildInstructions(context, state.currentMode),
              ],
            ),
          ),
          if (state.selectedDate != null)
            _buildBottomSheetOverlay(
              context,
              currentMode: state.currentMode,
              selectedDate: state.selectedDate!,
              selectedDateSets: state.selectedDateSets,
              selectedDateNutritionLogs: state.selectedDateNutritionLogs,
            ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(BuildContext context, HistoryMode currentMode) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          _buildModeButton(
            context,
            label: 'Workouts',
            icon: Icons.fitness_center,
            isSelected: currentMode == HistoryMode.workouts,
            onTap: () {
              context
                  .read<HistoryBloc>()
                  .add(const ChangeHistoryModeEvent(HistoryMode.workouts));
            },
          ),
          _buildModeButton(
            context,
            label: 'Nutrition',
            icon: Icons.restaurant_menu,
            isSelected: currentMode == HistoryMode.nutrition,
            onTap: () {
              context
                  .read<HistoryBloc>()
                  .add(const ChangeHistoryModeEvent(HistoryMode.nutrition));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.textDim,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textDim,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildInstructions(BuildContext context, HistoryMode mode) {
    final title =
        mode == HistoryMode.workouts ? 'How to use' : 'How to use nutrition history';

    final instructions = mode == HistoryMode.workouts
        ? const [
            '• Tap a date to view workout details',
            '• Dates with workouts are highlighted',
            '• Swipe left/right to change months',
            '• Edit or delete past sets from details',
          ]
        : const [
            '• Tap a date to view nutrition details',
            '• Dates with nutrition logs are highlighted',
            '• Swipe left/right to change months',
            '• Edit or delete past nutrition logs from details',
          ];

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
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...instructions.map((item) => _buildInstructionItem(context, item)),
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
    BuildContext context, {
    required HistoryMode currentMode,
    required DateTime selectedDate,
    required List<WorkoutSet> selectedDateSets,
    required List<NutritionLog> selectedDateNutritionLogs,
  }) {
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
              child: currentMode == HistoryMode.workouts
                  ? DayDetailsBottomSheet(
                      date: selectedDate,
                      sets: selectedDateSets,
                    )
                  : NutritionDayDetailsBottomSheet(
                      date: selectedDate,
                      logs: selectedDateNutritionLogs,
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
        'Cannot view data from more than 5 years ago',
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