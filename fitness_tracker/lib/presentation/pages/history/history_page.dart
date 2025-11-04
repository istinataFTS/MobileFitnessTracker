import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/error_handler.dart';
import '../../../domain/entities/workout_set.dart';
import '../exercises/bloc/exercise_bloc.dart';
import 'bloc/history_bloc.dart';

/// HistoryPage - Displays workout history with BLoC pattern
/// Features:
/// - View all workout sets sorted by date
/// - Filter by muscle group
/// - View detailed workout information
/// - Delete individual sets
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.historyTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<HistoryBloc, HistoryState>(
        listener: (context, state) {
          // Show success/error messages
          if (state is HistoryOperationSuccess) {
            ErrorHandler.showSuccess(context, state.message);
          } else if (state is HistoryError) {
            ErrorHandler.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryOrange,
              ),
            );
          }

          if (state is HistoryError) {
            return _buildErrorState(context, state.message);
          }

          if (state is HistoryLoaded) {
            return Column(
              children: [
                if (state.currentMuscleFilter != null)
                  _buildFilterChip(context, state.currentMuscleFilter!),
                Expanded(
                  child: _buildSetsList(context, state.sets),
                ),
              ],
            );
          }

          // Initial or unknown state
          return const Center(
            child: Text('Loading history...'),
          );
        },
      ),
    );
  }

  /// Build the filter chip showing active muscle group filter
  Widget _buildFilterChip(BuildContext context, String muscleFilter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Chip(
            label: Text(muscleFilter),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () {
              // Clear filter by passing null
              context.read<HistoryBloc>().add(const FilterByMuscleGroupEvent(null));
            },
            backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
            labelStyle: const TextStyle(
              color: AppTheme.primaryOrange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the list of workout sets grouped by date
  Widget _buildSetsList(BuildContext context, List<WorkoutSet> sets) {
    if (sets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: AppTheme.textDim,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noSetsLogged,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.startLoggingSets,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    // Group sets by date
    final grouped = <DateTime, List<WorkoutSet>>{};
    for (final set in sets) {
      final date = DateTime(set.date.year, set.date.month, set.date.day);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(set);
    }

    // Sort dates in descending order (most recent first)
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dateSets = grouped[date]!;
        return _buildDateCard(context, date, dateSets);
      },
    );
  }

  /// Build a card for a specific date with its workout sets
  Widget _buildDateCard(
    BuildContext context,
    DateTime date,
    List<WorkoutSet> sets,
  ) {
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    final totalSets = sets.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDayDetails(context, date, sets),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Date and set count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday
                              ? 'Today'
                              : DateFormat('EEEE, MMM d').format(date),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('h:mm a').format(sets.first.createdAt),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalSets set${totalSets != 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              // Preview of first 3 sets
              ...sets.take(3).map((set) => _buildSetPreview(context, set)),
              // Show more indicator if there are more than 3 sets
              if (sets.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+ ${sets.length - 3} more set${sets.length - 3 != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryOrange,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a preview of a single set
  Widget _buildSetPreview(BuildContext context, WorkoutSet set) {
    return BlocBuilder<ExerciseBloc, ExerciseState>(
      builder: (context, exerciseState) {
        String exerciseName = 'Unknown Exercise';
        
        if (exerciseState is ExercisesLoaded) {
          final exercise = exerciseState.exercises.firstWhere(
            (e) => e.id == set.exerciseId,
            orElse: () => exerciseState.exercises.first, // Fallback
          );
          exerciseName = exercise.name;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryOrange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$exerciseName - ${set.reps} reps @ ${set.weight}kg',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build error state UI
  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<HistoryBloc>().add(RefreshHistoryEvent());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Show filter dialog for muscle group selection
  void _showFilterDialog(BuildContext context) {
    final currentBloc = context.read<HistoryBloc>();
    String? selectedFilter;
    
    if (currentBloc.state is HistoryLoaded) {
      selectedFilter = (currentBloc.state as HistoryLoaded).currentMuscleFilter;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppStrings.filterByMuscleGroup),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "All" option
                ListTile(
                  title: const Text(AppStrings.all),
                  leading: Radio<String?>(
                    value: null,
                    groupValue: selectedFilter,
                    onChanged: (value) {
                      currentBloc.add(FilterByMuscleGroupEvent(value));
                      Navigator.pop(dialogContext);
                    },
                    activeColor: AppTheme.primaryOrange,
                  ),
                ),
                // Muscle group options
                ...MuscleGroups.all.map((muscle) {
                  final displayName = MuscleGroups.getDisplayName(muscle);
                  return ListTile(
                    title: Text(displayName),
                    leading: Radio<String?>(
                      value: displayName,
                      groupValue: selectedFilter,
                      onChanged: (value) {
                        currentBloc.add(FilterByMuscleGroupEvent(value));
                        Navigator.pop(dialogContext);
                      },
                      activeColor: AppTheme.primaryOrange,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show detailed view of workout for a specific day
  void _showDayDetails(
    BuildContext context,
    DateTime date,
    List<WorkoutSet> sets,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.workoutDetails,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(bottomSheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                DateFormat('EEEE, MMMM d, y').format(date),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              // List of all sets for the day
              ...sets.map((set) => _buildSetDetailTile(
                    context,
                    bottomSheetContext,
                    set,
                  )),
            ],
          ),
        );
      },
    );
  }

  /// Build a detailed tile for a single set with delete option
  Widget _buildSetDetailTile(
    BuildContext context,
    BuildContext bottomSheetContext,
    WorkoutSet set,
  ) {
    return BlocBuilder<ExerciseBloc, ExerciseState>(
      builder: (context, exerciseState) {
        String exerciseName = 'Unknown Exercise';
        List<String> muscleGroups = [];

        if (exerciseState is ExercisesLoaded) {
          try {
            final exercise = exerciseState.exercises.firstWhere(
              (e) => e.id == set.exerciseId,
            );
            exerciseName = exercise.name;
            muscleGroups = exercise.muscleGroups
                .map((mg) => MuscleGroups.getDisplayName(mg))
                .toList();
          } catch (_) {
            // Exercise not found
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exerciseName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${set.reps} reps @ ${set.weight}kg',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.primaryOrange,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (muscleGroups.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: muscleGroups
                              .map((mg) => Chip(
                                    label: Text(
                                      mg,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.errorRed),
                  onPressed: () {
                    Navigator.pop(bottomSheetContext);
                    _confirmDeleteSet(context, set);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show confirmation dialog before deleting a set
  Future<void> _confirmDeleteSet(BuildContext context, WorkoutSet set) async {
    final confirmed = await ErrorHandler.showConfirmDialog(
      context,
      title: 'Delete Set',
      message: 'Are you sure you want to delete this set? This cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      context.read<HistoryBloc>().add(DeleteSetEvent(set.id));
    }
  }
}
