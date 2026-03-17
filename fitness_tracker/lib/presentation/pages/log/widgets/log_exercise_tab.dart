import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/muscle_groups.dart';
import '../../../../core/constants/muscle_stimulus_constants.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/utils/weight_unit_utils.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/entities/exercise.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../../../domain/repositories/app_settings_repository.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../exercises/bloc/exercise_bloc.dart';
import '../bloc/workout_bloc.dart';
import 'intensity_slider_widget.dart';

class LogExerciseTab extends StatefulWidget {
  final DateTime? initialDate;
  final bool showSuccessFeedback;
  final ValueChanged<DateTime>? onLoggedSuccess;

  const LogExerciseTab({
    super.key,
    this.initialDate,
    this.showSuccessFeedback = true,
    this.onLoggedSuccess,
  });

  @override
  State<LogExerciseTab> createState() => _LogExerciseTabState();
}

class _LogExerciseTabState extends State<LogExerciseTab> {
  final _uuid = const Uuid();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();

  StreamSubscription<WorkoutUiEffect>? _workoutEffectsSub;

  late final AppSettingsRepository _settingsRepository;
  late Future<AppSettings> _settingsFuture;

  Exercise? _selectedExercise;
  late DateTime _selectedDate;
  int _selectedIntensity = MuscleStimulus.defaultIntensity;

  @override
  void initState() {
    super.initState();

    _settingsRepository = di.sl<AppSettingsRepository>();
    _settingsFuture = _loadSettings();
    _selectedDate = widget.initialDate ?? DateTime.now();

    final workoutBloc = context.read<WorkoutBloc>();
    _workoutEffectsSub = workoutBloc.effects.listen((effect) {
      if (!mounted) {
        return;
      }

      if (effect is WorkoutLoggedEffect) {
        if (widget.showSuccessFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    effect.message,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (effect.affectedMuscles.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Training: ${effect.affectedMuscles.map((m) => MuscleGroups.getDisplayName(m)).join(", ")}',
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
        }

        widget.onLoggedSuccess?.call(_selectedDate);
        _clearForm();
      }
    });
  }

  Future<AppSettings> _loadSettings() async {
    final result = await _settingsRepository.getSettings();
    return result.fold(
      (_) => const AppSettings.defaults(),
      (settings) => settings,
    );
  }

  @override
  void dispose() {
    _workoutEffectsSub?.cancel();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppSettings>(
      future: _settingsFuture,
      builder: (context, settingsSnapshot) {
        final settings =
            settingsSnapshot.data ?? const AppSettings.defaults();

        return BlocConsumer<WorkoutBloc, WorkoutState>(
          listener: (context, state) {
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
                      _buildExerciseSelector(exercises),
                      const SizedBox(height: 24),
                      _buildRepsInput(),
                      const SizedBox(height: 20),
                      _buildWeightInput(settings.weightUnit),
                      const SizedBox(height: 20),
                      IntensitySliderWidget(
                        intensity: _selectedIntensity,
                        onChanged: (value) {
                          setState(() {
                            _selectedIntensity = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildDatePicker(context),
                      const SizedBox(height: 20),
                      _buildMuscleGroupInfo(),
                      const SizedBox(height: 28),
                      _buildLogButton(
                        workoutState,
                        settings.weightUnit,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
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
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedExercise?.name ?? AppStrings.selectExercise,
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

  Widget _buildEmptyExercisesState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
          decoration: const InputDecoration(
            hintText: '0',
            prefixIcon: Icon(Icons.repeat),
            suffixText: AppStrings.unitReps,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightInput(WeightUnit weightUnit) {
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
            labelText: WeightUnitUtils.inputLabel(weightUnit),
            helperText:
                'Stored internally in kg for future sync compatibility',
            prefixIcon: const Icon(Icons.fitness_center),
            suffixText: WeightUnitUtils.unitLabel(weightUnit),
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
    if (_selectedExercise == null) {
      return const SizedBox.shrink();
    }

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

  Widget _buildLogButton(
    WorkoutState state,
    WeightUnit weightUnit,
  ) {
    final isLoading = state is WorkoutLoading;
    final canLog = _selectedExercise != null &&
        _repsController.text.isNotEmpty &&
        _weightController.text.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (!canLog || isLoading)
            ? null
            : () => _handleLogSet(weightUnit),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                AppStrings.logSetButton,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  void _showExercisePicker(BuildContext context, List<Exercise> exercises) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 420,
            child: Column(
              children: [
                Padding(
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
                Expanded(
                  child: ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      final isSelected = _selectedExercise?.id == exercise.id;

                      return ListTile(
                        title: Text(
                          exercise.name,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                        ),
                        subtitle: Text(
                          exercise.muscleGroups
                              .map((mg) => MuscleGroups.getDisplayName(mg))
                              .join(', '),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
            ),
          ),
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

  void _handleLogSet(WeightUnit weightUnit) {
    if (_selectedExercise == null) {
      return;
    }

    final reps = int.tryParse(_repsController.text);
    final enteredWeight = double.tryParse(_weightController.text);

    if (reps == null || enteredWeight == null) {
      return;
    }

    final workoutSet = WorkoutSet(
      id: _uuid.v4(),
      exerciseId: _selectedExercise!.id,
      reps: reps,
      weight: WeightUnitUtils.toStoredKilograms(
        enteredWeight,
        weightUnit,
      ),
      intensity: _selectedIntensity,
      date: _selectedDate,
      createdAt: DateTime.now(),
    );

    context.read<WorkoutBloc>().add(AddWorkoutSetEvent(workoutSet));
  }

  void _clearForm() {
    setState(() {
      _repsController.clear();
      _weightController.clear();
    });
  }
}