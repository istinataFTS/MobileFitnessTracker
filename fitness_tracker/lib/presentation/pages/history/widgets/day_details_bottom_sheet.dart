import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/calendar_constants.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../domain/entities/workout_set.dart';
import '../../../domain/entities/exercise.dart';
import '../bloc/history_bloc.dart';
import '../../exercises/bloc/exercise_bloc.dart';
import '../widgets/edit_set_dialog.dart';
import '../../log_set/log_set_page.dart';

/// Bottom sheet displaying workout details for a selected date
class DayDetailsBottomSheet extends StatelessWidget {
  final DateTime date;
  final List<WorkoutSet> sets;

  const DayDetailsBottomSheet({
    super.key,
    required this.date,
    required this.sets,
  });

  @override
  Widget build(BuildContext context) {
    final hasWorkouts = sets.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CalendarConstants.bottomSheetBorderRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          _buildHeader(context, hasWorkouts),
          
          if (hasWorkouts)
            const Divider(height: 1),
          
          // Content
          Flexible(
            child: hasWorkouts
                ? _buildWorkoutsList(context)
                : _buildEmptyState(context),
          ),
        ],
      ),
    );
  }

  /// Build header with date and stats
  Widget _buildHeader(BuildContext context, bool hasWorkouts) {
    final dateStr = DateFormat('EEEE, MMM d').format(date);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (hasWorkouts) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${sets.length} set${sets.length != 1 ? 's' : ''} logged',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMedium,
                        ),
                  ),
                ],
              ],
            ),
          ),
          
          // Close button
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              context.read<HistoryBloc>().add(ClearDateSelectionEvent());
            },
          ),
        ],
      ),
    );
  }

  /// Build list of workouts
  Widget _buildWorkoutsList(BuildContext context) {
    return BlocBuilder<ExerciseBloc, ExerciseState>(
      builder: (context, exerciseState) {
        if (exerciseState is! ExercisesLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        // Create exercise map for quick lookup
        final exerciseMap = <String, Exercise>{
          for (var ex in exerciseState.exercises) ex.id: ex,
        };

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shrinkWrap: true,
          itemCount: sets.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final set = sets[index];
            final exercise = exerciseMap[set.exerciseId];
            
            if (exercise == null) {
              return const SizedBox(); // Skip if exercise not found
            }

            return _buildSetCard(context, set, exercise);
          },
        );
      },
    );
  }

  /// Build individual set card
  Widget _buildSetCard(BuildContext context, WorkoutSet set, Exercise exercise) {
    final muscleGroupsList = exercise.muscleGroups
        .map((mg) => MuscleGroups.getDisplayName(mg))
        .join(', ');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise name and actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditDialog(context, set, exercise),
                  tooltip: 'Edit Set',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(context, set, exercise),
                  tooltip: 'Delete Set',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Set details
            Row(
              children: [
                _buildDetailChip(
                  context,
                  icon: Icons.repeat,
                  label: '${set.reps} reps',
                ),
                const SizedBox(width: 8),
                _buildDetailChip(
                  context,
                  icon: Icons.fitness_center,
                  label: '${set.weight} kg',
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Muscle groups
            Text(
              muscleGroupsList,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build detail chip
  Widget _buildDetailChip(BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryOrange),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 64,
            color: AppTheme.textDim,
          ),
          const SizedBox(height: 16),
          Text(
            'No workouts logged',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textMedium,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Log a workout to start tracking',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Log workout button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close bottom sheet
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LogSetPage(
                    preselectedDate: date,
                  ),
                ),
              ),
            },
            icon: const Icon(Icons.add),
            label: const Text('Log Workout'),
          ),
        ],
      ),
    );
  }

  /// Show edit dialog
  void _showEditDialog(BuildContext context, WorkoutSet set, Exercise exercise) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<HistoryBloc>(),
        child: EditSetDialog(
          workoutSet: set,
          exercise: exercise,
        ),
      ),
    );
  }

  /// Confirm delete
  void _confirmDelete(BuildContext context, WorkoutSet set, Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Delete Set?'),
        content: Text(
          'Remove ${exercise.name} - ${set.reps} reps @ ${set.weight} kg?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<HistoryBloc>().add(DeleteSetEvent(set.id));
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}