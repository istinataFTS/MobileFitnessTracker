import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../domain/entities/exercise.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../../../presentation/pages/log/widgets/intensity_slider_widget.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late int _selectedIntensity;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(
      text: widget.workoutSet.reps.toString(),
    );
    _weightController = TextEditingController(
      text: InputValidators.formatWeight(widget.workoutSet.weight),
    );
    _selectedIntensity = widget.workoutSet.validatedIntensity;
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      hintText: 'Enter weight',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: InputValidators.validateWeight,
                  ),
                  const SizedBox(height: 20),
                  IntensitySliderWidget(
                    intensity: _selectedIntensity,
                    onChanged: (int value) {
                      setState(() {
                        _selectedIntensity = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
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
        ),
      ),
    );
  }

  void _handleUpdate() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final WorkoutSet updatedSet = widget.workoutSet.copyWith(
      reps: int.parse(_repsController.text.trim()),
      weight: double.parse(_weightController.text.trim()),
      intensity: _selectedIntensity,
    );

    context.read<HistoryBloc>().add(UpdateSetEvent(updatedSet));
    Navigator.pop(context);
  }
}