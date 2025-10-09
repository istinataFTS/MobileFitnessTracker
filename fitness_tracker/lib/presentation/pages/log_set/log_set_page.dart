import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/workout_sets_manager.dart';
import '../../../core/utils/targets_manager.dart';
import 'package:intl/intl.dart';

class LogSetPage extends StatefulWidget {
  const LogSetPage({super.key});

  @override
  State<LogSetPage> createState() => _LogSetPageState();
}

class _LogSetPageState extends State<LogSetPage> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  
  String? _selectedMuscle;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _exerciseController.dispose();
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
                    _buildMuscleGroupDropdown(),
                    const SizedBox(height: 20),
                    _buildExerciseNameField(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildRepsField()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildWeightField()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTargetProgress(),
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

  Widget _buildMuscleGroupDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Muscle Group',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedMuscle,
          decoration: InputDecoration(
            hintText: 'Select muscle group',
            prefixIcon: const Icon(Icons.fitness_center),
            filled: true,
            fillColor: AppTheme.surfaceDark,
          ),
          items: MuscleGroups.all.map((muscle) {
            return DropdownMenuItem(
              value: muscle,
              child: Text(MuscleGroups.getDisplayName(muscle)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMuscle = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a muscle group';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildExerciseNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercise Name',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _exerciseController,
          decoration: const InputDecoration(
            hintText: 'e.g., Bench Press',
            prefixIcon: Icon(Icons.directions_run),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter exercise name';
            }
            return null;
          },
        ),
      ],
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

  Widget _buildTargetProgress() {
    if (_selectedMuscle == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: Listenable.merge([
        WorkoutSetsManager(),
        TargetsManager(),
      ]),
      builder: (context, child) {
        final target = TargetsManager().getTarget(_selectedMuscle!);
        final currentSets = WorkoutSetsManager().getWeeklySetsForMuscle(_selectedMuscle!);

        if (target == null) {
          return Card(
            color: AppTheme.warningAmber.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.warningAmber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No target set for ${MuscleGroups.getDisplayName(_selectedMuscle!)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final progress = currentSets / target.weeklyGoal;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Progress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$currentSets / ${target.weeklyGoal} sets',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppTheme.borderDark,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    if (_formKey.currentState!.validate()) {
      final reps = int.parse(_repsController.text);
      final weight = double.parse(_weightController.text);

      WorkoutSetsManager().addSet(
        muscleGroup: _selectedMuscle!,
        exerciseName: _exerciseController.text.trim(),
        reps: reps,
        weight: weight,
        date: _selectedDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Set logged: ${_exerciseController.text} - $reps reps @ ${weight}kg',
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Clear form
      setState(() {
        _exerciseController.clear();
        _repsController.clear();
        _weightController.clear();
        _selectedMuscle = null;
      });
    }
  }
}