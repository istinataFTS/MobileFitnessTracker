import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/exercises_manager.dart';
import '../../../domain/entities/exercise.dart';

/// Clean exercises management page - main tab for creating/editing exercises
class ExercisesPage extends StatelessWidget {
  const ExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text(AppStrings.exercisesTitle),
        automaticallyImplyLeading: false, // No back button - it's a main tab
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: AppStrings.aboutExercises,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: ExercisesManager(),
        builder: (context, child) {
          final exercises = ExercisesManager().exercises;

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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center_outlined,
                size: 60,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.noExercisesYet,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.createExercisesDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddExerciseDialog(context),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addFirstExercise),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
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
      child: InkWell(
        onTap: () => _showEditExerciseDialog(context, exercise),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                  Icons.fitness_center,
                  color: AppTheme.primaryOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: exercise.muscleGroups.take(3).map((mg) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            MuscleGroups.getDisplayName(mg),
                            style: const TextStyle(
                              color: AppTheme.primaryOrange,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (exercise.muscleGroups.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+${exercise.muscleGroups.length - 3} more',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textDim,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.textDim),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditExerciseDialog(context, exercise);
                  } else if (value == 'delete') {
                    _confirmDeleteExercise(context, exercise);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text(AppStrings.edit),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: AppTheme.errorRed),
                        SizedBox(width: 12),
                        Text(AppStrings.delete, style: TextStyle(color: AppTheme.errorRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            label: const Text(
              AppStrings.addExercise,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _ExerciseDialog(),
    );
  }

  void _showEditExerciseDialog(BuildContext context, Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => _ExerciseDialog(exercise: exercise),
    );
  }

  void _confirmDeleteExercise(BuildContext context, Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteExercise),
        content: Text('${AppStrings.deleteExerciseConfirm}\n\n${exercise.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              ExercisesManager().deleteExercise(exercise.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${exercise.name} ${AppStrings.exerciseDeleted}'),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(20),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.aboutExercises),
        content: const Text(AppStrings.aboutExercisesDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.gotIt),
          ),
        ],
      ),
    );
  }
}

// Unified dialog for adding and editing exercises
class _ExerciseDialog extends StatefulWidget {
  final Exercise? exercise; // null for add, non-null for edit

  const _ExerciseDialog({this.exercise});

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  late final TextEditingController _nameController;
  late final Set<String> _selectedMuscles;

  bool get isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise?.name ?? '');
    _selectedMuscles = Set.from(widget.exercise?.muscleGroups ?? []);
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
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            Flexible(child: _buildContent(context)),
            const Divider(height: 1),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isEditing ? AppStrings.editExercise : AppStrings.addExercise,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: AppStrings.exerciseName,
              hintText: AppStrings.exerciseNameHint,
              prefixIcon: Icon(Icons.fitness_center),
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: !isEditing,
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.muscleGroups,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
                selectedColor: AppTheme.primaryOrange.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryOrange,
                backgroundColor: AppTheme.surfaceDark,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final isValid = _nameController.text.trim().isNotEmpty &&
        _selectedMuscles.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: isValid ? _handleSave : null,
              child: Text(isEditing ? AppStrings.saveChanges : AppStrings.add),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    
    if (isEditing) {
      ExercisesManager().updateExercise(
        widget.exercise!.id,
        name,
        _selectedMuscles.toList(),
      );
    } else {
      ExercisesManager().addExercise(name, _selectedMuscles.toList());
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditing
              ? '$name ${AppStrings.exerciseUpdated}'
              : '$name ${AppStrings.exerciseAdded}',
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
  }
}