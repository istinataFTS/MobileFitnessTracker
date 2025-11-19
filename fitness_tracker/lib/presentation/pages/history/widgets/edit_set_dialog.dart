import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/input_validators.dart';
import '../../../domain/entities/workout_set.dart';
import '../../../domain/entities/exercise.dart';
import '../bloc/history_bloc.dart';

/// Dialog for editing an existing workout set
class EditSetDialog extends StatefulWidget {
  final WorkoutSet workoutSet;
  final Exercise exercise;

  const EditSetDialog({
    super.key,
    required this.workoutSet,
    required this.exercise,
  });

  @override
  State<EditSetDialog> createState() => _EditSetDialogState();
}

class _EditSetDialogState extends State<EditSetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _repsController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(
      text: widget.workoutSet.reps.toString(),
    );
    _weightController = TextEditingController(
      text: InputValidators.formatWeight(widget.workoutSet.weight),
    );
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Edit Set',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.exercise.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMedium,
                    ),
              ),
              const SizedBox(height: 24),
              
              // Reps Input
              TextFormField(
                controller: _repsController,
                decoration: const InputDecoration(
                  labelText: 'Reps',
                  hintText: 'Enter reps',
                ),
                keyboardType: TextInputType.number,
                validator: InputValidators.validateReps,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              
              // Weight Input
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'Enter weight',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: InputValidators.validateWeight,
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleUpdate,
                    child: const Text('Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleUpdate() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedSet = widget.workoutSet.copyWith(
      reps: int.parse(_repsController.text),
      weight: double.parse(_weightController.text),
    );

    context.read<HistoryBloc>().add(UpdateSetEvent(updatedSet));
    Navigator.pop(context);
  }
}


