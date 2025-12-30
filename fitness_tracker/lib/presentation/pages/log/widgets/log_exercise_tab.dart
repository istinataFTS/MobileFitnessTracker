import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/muscle_groups.dart';
import '../../../../core/constants/muscle_stimulus_constants.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../domain/entities/exercise.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../../widgets/intensity_slider_widget.dart';
import '../../exercises/bloc/exercise_bloc.dart';
import '../bloc/workout_bloc.dart';

/// Exercise logging tab for the Log page
class LogExerciseTab extends StatefulWidget {
  const LogExerciseTab({super.key});

  @override
  State<LogExerciseTab> createState() => _LogExerciseTabState();
}

class _LogExerciseTabState extends State<LogExerciseTab> {
  final _uuid = const Uuid();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  
  Exercise? _selectedExercise;
  DateTime _selectedDate = DateTime.now();
  int _selectedIntensity = MuscleStimulus.defaultIntensity; // Default to 3 (moderate)

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkoutBloc, WorkoutState>(
      listener: (context, state) {
        if (state is WorkoutOperationSuccess) {
          // Show success message with affected muscles
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.setLogged,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (state.affectedMuscles.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Training: ${state.affectedMuscles.map((m) => MuscleGroups.getDisplayName(m)).join(", ")}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(20),
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Clear form after successful log
          _clearForm();
        }

        if (state is WorkoutError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(20),
            ),
          );
        }
      },
      builder: (context, workoutState) {
        return BlocBuilder<ExerciseBloc, ExerciseState>(
          builder: (context, exerciseState) {
            if (exerciseState is ExerciseLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryOrange,
                ),
              );
            }

            if (exerciseState is ExerciseError) {
              return _buildErrorState(context);
            }

            final exercises = exerciseState is ExercisesLoaded
                ? exerciseState.exercises
                : <Exercise>[];

            if (exercises.isEmpty) {
              return _buildEmptyExercisesState(context);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Selector
                  _buildExerciseSelector(exercises),
                  const SizedBox(height: 24),

                  // Reps Input
                  _buildRepsInput(),
                  const SizedBox(height: 20),

                  // Weight Input
                  _buildWeightInput(),
                  const SizedBox(height: 24),

                  // Intensity Slider (NEW: Phase 9)
                  IntensitySliderWidget(
                    intensity: _selectedIntensity,
                    onChanged: (value) {
                      setState(() {
                        _selectedIntensity = value;
                      });
                    },
                    enabled: true,
                  ),
                  const SizedBox(height: 24),

                  // Date Picker
                  _buildDatePicker(context),
                  const SizedBox(height: 24),

                  // Muscle Group Info (if exercise selected)
                  if (_selectedExercise != null) _buildMuscleGroupInfo(),
                  if (_selectedExercise != null) const SizedBox(height: 24),

                  // Log Button
                  _buildLogButton(workoutState),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
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
              AppStrings.errorLoadingExercises,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<ExerciseBloc>().add(LoadExercisesEvent());
              },
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSelector(List<Exercise> exercises) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.exercise,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _showExercisePicker(context, exercises),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _selectedExercise != null
                        ? AppTheme.primaryOrange.withOpacity(0.1)
                        : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: _selectedExercise != null
                        ? AppTheme.primaryOrange
                        : AppTheme.textDim,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedExercise?.name ?? AppStrings.selectExercise,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _selectedExercise != null
                              ? AppTheme.textLight
                              : AppTheme.textDim,
                        ),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.textDim,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyExercisesState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.fitness_center_outlined,
            size: 48,
            color: AppTheme.textDim,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.noExercisesAvailable,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.createExercisesFirst,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMedium,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRepsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.reps,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _repsController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '0',
            prefixIcon: const Icon(Icons.repeat),
            suffixText: AppStrings.unitReps,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.weight,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
          ],
          decoration: InputDecoration(
            hintText: '0.0',
            prefixIcon: const Icon(Icons.fitness_center),
            suffixText: AppStrings.unitKg,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.workoutDate,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.textDim,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleGroupInfo() {
    if (_selectedExercise == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryOrange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.primaryOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.setWillCountToward,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedExercise!.muscleGroups.map((mg) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  MuscleGroups.getDisplayName(mg),
                  style: const TextStyle(
                    color: AppTheme.primaryOrange,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogButton(WorkoutState state) {
    final isLoading = state is WorkoutLoading;
    final canLog = _selectedExercise != null &&
        _repsController.text.isNotEmpty &&
        _weightController.text.isNotEmpty;
    // Intensity is always valid (defaults to 3, clamped 0-5)

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (canLog && !isLoading) ? _handleLogSet : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                AppStrings.logSetButton,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showExercisePicker(BuildContext context, List<Exercise> exercises) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.selectExercise,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Exercise list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: exercises.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      final isSelected =
                          _selectedExercise?.id == exercise.id;

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryOrange
                                : AppTheme.primaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.primaryOrange,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          exercise.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          exercise.muscleGroups
                              .map((mg) => MuscleGroups.getDisplayName(mg))
                              .join(', '),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppTheme.textMedium,
                              ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppTheme.primaryOrange,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedExercise = exercise;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryOrange,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceDark,
              onSurface: AppTheme.textLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleLogSet() {
    if (_selectedExercise == null) return;

    final reps = int.parse(_repsController.text);
    final weight = double.parse(_weightController.text);

    final workoutSet = WorkoutSet(
      id: _uuid.v4(),
      exerciseId: _selectedExercise!.id,
      reps: reps,
      weight: weight,
      intensity: _selectedIntensity, // NEW: Include intensity
      date: _selectedDate,
      createdAt: DateTime.now(),
    );

    context.read<WorkoutBloc>().add(AddWorkoutSetEvent(workoutSet));
  }

  void _clearForm() {
    setState(() {
      _selectedExercise = null;
      _repsController.clear();
      _weightController.clear();
      _selectedIntensity = MuscleStimulus.defaultIntensity; // Reset to default
      _selectedDate = DateTime.now();
    });
  }
}