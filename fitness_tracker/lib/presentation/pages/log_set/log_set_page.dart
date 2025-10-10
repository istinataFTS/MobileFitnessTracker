import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/workout_sets_manager.dart';
import '../../../core/utils/exercises_manager.dart';
import '../../../domain/entities/exercise.dart';
import 'package:intl/intl.dart';

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
      appBar: AppBar(
        title: const Text('Log Set'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildDateSelector(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExerciseDropdown(),
                    if (_selectedExercise != null) ...[
                      const SizedBox(height: 16),
                      _buildMuscleGroupsDisplay(),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildRepsField()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildWeightField()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildSaveButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderDark),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today,
            size: 20,
            color: AppTheme.textMedium,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workout Date',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _selectDate(context),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseDropdown() {
    final exercises = ExercisesManager().exercises;

    if (exercises.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.fitness_center_outlined,
                size: 48,
                color: AppTheme.textDim,
              ),
              const SizedBox(height: 16),
              Text(
                'No Exercises Available',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Create exercises first in the Exercises page',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
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
          'Exercise',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Exercise>(
          value: _selectedExercise,
          decoration: InputDecoration(
            hintText: 'Select exercise',
            prefixIcon: const Icon(Icons.fitness_center),
            filled: true,
            fillColor: AppTheme.surfaceDark,
          ),
          items: exercises.map((exercise) {
            return DropdownMenuItem(
              value: exercise,
              child: Text(exercise.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedExercise = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select an exercise';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMuscleGroupsDisplay() {
    if (_selectedExercise == null) return const SizedBox.shrink();

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
                  size: 18,
                  color: AppTheme.primaryOrange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Muscle Groups Worked',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedExercise!.muscleGroups.map((mg) {
                return Chip(
                  label: Text(MuscleGroups.getDisplayName(mg)),
                  backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
                  labelStyle: const TextStyle(
                    color: AppTheme.primaryOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'This set will count toward all muscle groups above',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reps',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _repsController,
          decoration: const InputDecoration(
            hintText: '12',
            prefixIcon: Icon(Icons.repeat),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            final reps = int.tryParse(value);
            if (reps == null || reps < 1) {
              return 'Invalid';
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
        Text(
          'Weight (kg)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _weightController,
          decoration: const InputDecoration(
            hintText: '75',
            prefixIcon: Icon(Icons.monitor_weight),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            final weight = double.tryParse(value);
            if (weight == null || weight <= 0) {
              return 'Invalid';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveSet,
            child: const Text('Log Set'),
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
          content: Text(
            'Set logged: ${_selectedExercise!.name} - $reps reps @ ${weight}kg\n'
            'Counted for: $muscleGroupsList',
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // Clear form
      setState(() {
        _repsController.clear();
        _weightController.clear();
        _selectedExercise = null;
      });
    }
  }
}