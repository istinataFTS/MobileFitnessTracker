import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/workout_sets_manager.dart';
import '../../../core/utils/exercises_manager.dart';
import '../../../domain/entities/exercise.dart';

/// Clean, straightforward logging interface as a main tab
class LogSetPage extends StatefulWidget {
  const LogSetPage({super.key});

  @override
  State<LogSetPage> createState() => _LogSetPageState();
}

class _LogSetPageState extends State<LogSetPage> {
  final _formKey = GlobalKey<FormState>();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  
  Exercise? _selectedExercise;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text(AppStrings.logSetTitle),
        automaticallyImplyLeading: false, // No back button - it's a main tab
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateCard(),
                    const SizedBox(height: 24),
                    _buildExerciseSection(),
                    if (_selectedExercise != null) ...[
                      const SizedBox(height: 20),
                      _buildMuscleGroupsCard(),
                      const SizedBox(height: 24),
                      _buildInputFields(),
                    ],
                  ],
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    return Card(
      child: InkWell(
        onTap: () => _selectDate(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.workoutDate,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isToday
                          ? '${AppStrings.today} - ${DateFormat(AppStrings.dateFormatDate).format(_selectedDate)}'
                          : DateFormat(AppStrings.dateFormatFull).format(_selectedDate),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseSection() {
    final exercises = ExercisesManager().exercises;

    if (exercises.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(
                Icons.fitness_center_outlined,
                size: 64,
                color: AppTheme.textDim,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.noExercisesAvailable,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.createExercisesFirst,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMedium,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.exercise,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<Exercise>(
              value: _selectedExercise,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: AppStrings.selectExercise,
                prefixIcon: Icon(
                  Icons.fitness_center,
                  color: AppTheme.primaryOrange,
                ),
              ),
              items: exercises.map((exercise) {
                return DropdownMenuItem(
                  value: exercise,
                  child: Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedExercise = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return AppStrings.pleaseSelectExercise;
                }
                return null;
              },
              dropdownColor: AppTheme.surfaceDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleGroupsCard() {
    return Card(
      color: AppTheme.primaryOrange.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                  AppStrings.muscleGroupsWorked,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryOrange,
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
                    color: AppTheme.primaryOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    MuscleGroups.getDisplayName(mg),
                    style: const TextStyle(
                      color: AppTheme.primaryOrange,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.setWillCountToward,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildRepsField()),
            const SizedBox(width: 12),
            Expanded(child: _buildWeightField()),
          ],
        ),
      ],
    );
  }

  Widget _buildRepsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            AppStrings.reps,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        TextFormField(
          controller: _repsController,
          decoration: InputDecoration(
            hintText: '12',
            prefixIcon: const Icon(Icons.repeat),
            filled: true,
            fillColor: AppTheme.surfaceDark,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: Theme.of(context).textTheme.titleLarge,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.required;
            }
            final reps = int.tryParse(value);
            if (reps == null || reps < 1) {
              return AppStrings.invalid;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildWeightField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            AppStrings.weight,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        TextFormField(
          controller: _weightController,
          decoration: InputDecoration(
            hintText: '75',
            prefixIcon: const Icon(Icons.monitor_weight),
            filled: true,
            fillColor: AppTheme.surfaceDark,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: Theme.of(context).textTheme.titleLarge,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.required;
            }
            final weight = double.tryParse(value);
            if (weight == null || weight <= 0) {
              return AppStrings.invalid;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: AppTheme.borderDark, width: 1),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedExercise != null ? _saveSet : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              AppStrings.logSetButton,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryOrange,
              surface: AppTheme.surfaceDark,
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

  void _saveSet() {
    if (_formKey.currentState!.validate() && _selectedExercise != null) {
      final reps = int.parse(_repsController.text);
      final weight = double.parse(_weightController.text);

      WorkoutSetsManager().addSet(
        exerciseId: _selectedExercise!.id,
        reps: reps,
        weight: weight,
        date: _selectedDate,
      );

      final muscleGroupsList = _selectedExercise!.muscleGroups
          .map((mg) => MuscleGroups.getDisplayName(mg))
          .join(', ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.setLoggedSuccess,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text('${_selectedExercise!.name} - $reps reps @ ${weight}kg'),
              Text('${AppStrings.countedFor}: $muscleGroupsList'),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(20),
        ),
      );

      // Clear form for next entry
      setState(() {
        _repsController.clear();
        _weightController.clear();
        _selectedExercise = null;
      });
    }
  }
}