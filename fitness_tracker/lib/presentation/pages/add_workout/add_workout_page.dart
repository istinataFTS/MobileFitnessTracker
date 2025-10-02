import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';

class AddWorkoutPage extends StatefulWidget {
  const AddWorkoutPage({super.key});

  @override
  State<AddWorkoutPage> createState() => _AddWorkoutPageState();
}

class _AddWorkoutPageState extends State<AddWorkoutPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  final Map<String, int> _muscleSets = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Workout'),
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
                    Text(
                      'Enter sets for each muscle group',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textMedium,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildMuscleGroupInputs(),
                  ],
                ),
              ),
            ),
            _buildBottomActions(context),
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

  Widget _buildMuscleGroupInputs() {
    return Column(
      children: MuscleGroups.all.map((muscle) {
        return _buildMuscleGroupInput(muscle);
      }).toList(),
    );
  }

  Widget _buildMuscleGroupInput(String muscleGroup) {
    final displayName = MuscleGroups.getDisplayName(muscleGroup);
    final currentValue = _muscleSets[muscleGroup] ?? 0;

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
                    displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Goal: ${MuscleGroups.getDefaultGoal(muscleGroup)} sets/week',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildCounterControls(muscleGroup, currentValue),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterControls(String muscleGroup, int currentValue) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderDark),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCounterButton(
            icon: Icons.remove,
            onPressed: currentValue > 0
                ? () {
                    setState(() {
                      _muscleSets[muscleGroup] = currentValue - 1;
                      if (_muscleSets[muscleGroup] == 0) {
                        _muscleSets.remove(muscleGroup);
                      }
                    });
                  }
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              currentValue.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          _buildCounterButton(
            icon: Icons.add,
            onPressed: () {
              setState(() {
                _muscleSets[muscleGroup] = currentValue + 1;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 20,
          color: onPressed != null ? AppTheme.primaryOrange : AppTheme.textLight,
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final totalSets = _muscleSets.values.fold(0, (sum, sets) => sum + sets);

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (totalSets > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Sets',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    totalSets.toString(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryOrange,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: totalSets > 0 ? _saveWorkout : null,
                child: const Text('Save Workout'),
              ),
            ),
          ],
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
            colorScheme: const ColorScheme.light(
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

  void _saveWorkout() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement save workout logic with BLoC
      final totalSets = _muscleSets.values.fold(0, (sum, sets) => sum + sets);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Workout saved! Total: $totalSets sets'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Clear form
      setState(() {
        _muscleSets.clear();
      });
    }
  }
}