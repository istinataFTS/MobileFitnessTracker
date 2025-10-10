import 'package:flutter/material.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/exercises_manager.dart';
import '../../../domain/entities/exercise.dart';

class ExercisesPage extends StatelessWidget {
  const ExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: ExercisesManager(),
        builder: (context, child) {
          final exercisesManager = ExercisesManager();
          final exercises = exercisesManager.exercises;

          return Column(
            children: [
              Expanded(
                child: exercises.isEmpty
                    ? _buildEmptyState(context)
                    : _buildExercisesList(context, exercises),
              ),
              _buildAddButton(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fitness_center_outlined,
              size: 80,
              color: AppTheme.textDim,
            ),
            const SizedBox(height: 24),
            Text(
              'No Exercises Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create exercises and assign muscle groups to track your workouts',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesList(BuildContext context, List<Exercise> exercises) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _buildExerciseCard(context, exercise);
      },
    );
  }

  Widget _buildExerciseCard(BuildContext context, Exercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.fitness_center,
            color: AppTheme.primaryOrange,
            size: 24,
          ),
        ),
        title: Text(
          exercise.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: exercise.muscleGroups.map((mg) {
            return Chip(
              label: Text(
                MuscleGroups.getDisplayName(mg),
                style: const TextStyle(fontSize: 11),
              ),
              backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
              labelStyle: const TextStyle(
                color: AppTheme.primaryOrange,
                fontSize: 11,
              ),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: AppTheme.primaryOrange,
              onPressed: () => _showEditExerciseDialog(context, exercise),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppTheme.errorRed,
              onPressed: () => _confirmDeleteExercise(context, exercise),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
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
          child: ElevatedButton.icon(
            onPressed: () => _showAddExerciseDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
          ),
        ),
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddExerciseDialog(),
    );
  }

  void _showEditExerciseDialog(BuildContext context, Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => _EditExerciseDialog(exercise: exercise),
    );
  }

  void _confirmDeleteExercise(BuildContext context, Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text('Delete ${exercise.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ExercisesManager().deleteExercise(exercise.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${exercise.name} deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Exercises'),
        content: const Text(
          'Create exercises and assign which muscle groups they work. '
          'When you log a set, it will count toward all assigned muscle groups.\n\n'
          'Example: Bench Press works Chest, Shoulders, and Triceps. '
          'Logging 1 set counts as 1 set for each muscle group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// Add Exercise Dialog
class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog();

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _nameController = TextEditingController();
  final Set<String> _selectedMuscles = {};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Exercise',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Exercise Name',
                        hintText: 'e.g., Bench Press',
                        prefixIcon: Icon(Icons.fitness_center),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Muscle Groups',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MuscleGroups.all.map((muscle) {
                        final isSelected = _selectedMuscles.contains(muscle);
                        return FilterChip(
                          label: Text(MuscleGroups.getDisplayName(muscle)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedMuscles.add(muscle);
                              } else {
                                _selectedMuscles.remove(muscle);
                              }
                            });
                          },
                          selectedColor: AppTheme.primaryOrange.withOpacity(0.3),
                          checkmarkColor: AppTheme.primaryOrange,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nameController.text.isNotEmpty &&
                          _selectedMuscles.isNotEmpty
                      ? () {
                          ExercisesManager().addExercise(
                            _nameController.text.trim(),
                            _selectedMuscles.toList(),
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${_nameController.text} added!'),
                              backgroundColor: AppTheme.successGreen,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : null,
                  child: const Text('Add Exercise'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Edit Exercise Dialog
class _EditExerciseDialog extends StatefulWidget {
  final Exercise exercise;

  const _EditExerciseDialog({required this.exercise});

  @override
  State<_EditExerciseDialog> createState() => _EditExerciseDialogState();
}

class _EditExerciseDialogState extends State<_EditExerciseDialog> {
  late final TextEditingController _nameController;
  late final Set<String> _selectedMuscles;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise.name);
    _selectedMuscles = Set.from(widget.exercise.muscleGroups);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Exercise',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Exercise Name',
                        prefixIcon: Icon(Icons.fitness_center),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Muscle Groups',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MuscleGroups.all.map((muscle) {
                        final isSelected = _selectedMuscles.contains(muscle);
                        return FilterChip(
                          label: Text(MuscleGroups.getDisplayName(muscle)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedMuscles.add(muscle);
                              } else {
                                _selectedMuscles.remove(muscle);
                              }
                            });
                          },
                          selectedColor: AppTheme.primaryOrange.withOpacity(0.3),
                          checkmarkColor: AppTheme.primaryOrange,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nameController.text.isNotEmpty &&
                          _selectedMuscles.isNotEmpty
                      ? () {
                          ExercisesManager().updateExercise(
                            widget.exercise.id,
                            _nameController.text.trim(),
                            _selectedMuscles.toList(),
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${_nameController.text} updated!'),
                              backgroundColor: AppTheme.successGreen,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : null,
                  child: const Text('Save Changes'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}