import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/target.dart';
import 'bloc/targets_bloc.dart';

class TargetsPage extends StatelessWidget {
  const TargetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Targets'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<TargetsBloc, TargetsState>(
        listener: (context, state) {
          if (state is TargetOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.successGreen,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(20),
              ),
            );
          } else if (state is TargetsError) {
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
        builder: (context, state) {
          if (state is TargetsLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryOrange,
              ),
            );
          }

          if (state is TargetsError) {
            return _buildErrorState(context, state.message);
          }

          final loadedState = state is TargetsLoaded ? state : null;
          final trainingTargets = loadedState?.trainingTargets ?? <Target>[];
          final macroTargets = loadedState?.macroTargets ?? <Target>[];
          final availableMuscles = _getAvailableMuscleGroups(trainingTargets);

          return Column(
            children: [
              Expanded(
                child: (trainingTargets.isEmpty && macroTargets.isEmpty)
                    ? _buildEmptyState(context)
                    : RefreshIndicator(
                        onRefresh: () async {
                          context.read<TargetsBloc>().add(LoadTargetsEvent());
                        },
                        color: AppTheme.primaryOrange,
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            _buildSectionHeader(
                              context,
                              title: 'Training Goals',
                              subtitle: 'Weekly set targets by muscle group',
                              icon: Icons.fitness_center,
                            ),
                            const SizedBox(height: 12),
                            if (trainingTargets.isEmpty)
                              _buildEmptySectionCard(
                                context,
                                title: 'No training goals yet',
                                subtitle:
                                    'Add weekly set goals for the muscle groups you want to prioritize.',
                              )
                            else
                              ...trainingTargets.map(
                                (target) => _buildTrainingTargetCard(
                                  context,
                                  target,
                                ),
                              ),
                            const SizedBox(height: 24),
                            _buildSectionHeader(
                              context,
                              title: 'Nutrition Goals',
                              subtitle: 'Daily macro targets',
                              icon: Icons.restaurant_menu,
                            ),
                            const SizedBox(height: 12),
                            if (macroTargets.isEmpty)
                              _buildEmptySectionCard(
                                context,
                                title: 'No macro goals yet',
                                subtitle:
                                    'Add daily protein, carbs, and fats targets to track nutrition progress.',
                              )
                            else
                              ...macroTargets.map(
                                (target) => _buildMacroTargetCard(
                                  context,
                                  target,
                                ),
                              ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
              ),
              _buildBottomActions(context, availableMuscles),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'Error loading targets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<TargetsBloc>().add(LoadTargetsEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                Icons.flag_outlined,
                size: 60,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No goals yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create weekly training goals and daily macro goals in one place.',
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

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryOrange,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMedium,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: AppTheme.textDim,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMedium,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingTargetCard(BuildContext context, Target target) {
    final displayName = MuscleGroups.getDisplayName(target.categoryKey);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _showEditTrainingTargetDialog(context, target),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.flag,
            color: AppTheme.primaryOrange,
          ),
        ),
        title: Text(
          displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          '${target.weeklyGoal} sets / week',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMedium,
              ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.textDim),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditTrainingTargetDialog(context, target);
            } else if (value == 'delete') {
              _confirmDeleteTarget(context, target, displayName);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: AppTheme.errorRed),
                  SizedBox(width: 12),
                  Text(
                    'Remove',
                    style: TextStyle(color: AppTheme.errorRed),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroTargetCard(BuildContext context, Target target) {
    final displayName = _macroDisplayName(target.categoryKey);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _showEditMacroTargetDialog(context, target),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _macroIcon(target.categoryKey),
            color: AppTheme.primaryOrange,
          ),
        ),
        title: Text(
          displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          '${target.goalValue.toStringAsFixed(0)} g / day',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMedium,
              ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.textDim),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditMacroTargetDialog(context, target);
            } else if (value == 'delete') {
              _confirmDeleteTarget(context, target, displayName);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: AppTheme.errorRed),
                  SizedBox(width: 12),
                  Text(
                    'Remove',
                    style: TextStyle(color: AppTheme.errorRed),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    List<String> availableMuscles,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderDark,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: availableMuscles.isEmpty
                    ? null
                    : () => _showAddTrainingTargetDialog(
                          context,
                          availableMuscles,
                        ),
                icon: const Icon(Icons.fitness_center),
                label: const Text('Add Training Goal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAddMacroTargetDialog(context),
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Add Macro Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getAvailableMuscleGroups(List<Target> trainingTargets) {
    final targetedMuscles = trainingTargets.map((t) => t.categoryKey).toSet();
    return MuscleGroups.all
        .where((muscle) => !targetedMuscles.contains(muscle))
        .toList();
  }

  void _showAddTrainingTargetDialog(
    BuildContext context,
    List<String> availableMuscles,
  ) {
    if (availableMuscles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All muscle groups already have a training goal.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<TargetsBloc>(),
        child: _TrainingTargetDialog(
          availableMuscles: availableMuscles,
        ),
      ),
    );
  }

  void _showEditTrainingTargetDialog(BuildContext context, Target target) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<TargetsBloc>(),
        child: _TrainingTargetDialog(
          existingTarget: target,
          availableMuscles: const [],
        ),
      ),
    );
  }

  void _showAddMacroTargetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<TargetsBloc>(),
        child: const _MacroTargetDialog(),
      ),
    );
  }

  void _showEditMacroTargetDialog(BuildContext context, Target target) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<TargetsBloc>(),
        child: _MacroTargetDialog(
          existingTarget: target,
        ),
      ),
    );
  }

  void _confirmDeleteTarget(
    BuildContext context,
    Target target,
    String displayName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Goal'),
        content: Text('Are you sure you want to remove this goal?\n\n$displayName'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TargetsBloc>().add(DeleteTargetEvent(target.id));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('About Goals'),
        content: const Text(
          'Training goals are weekly set targets by muscle group. '
          'Nutrition goals are daily macro targets for protein, carbs, and fats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _macroDisplayName(String key) {
    switch (key) {
      case 'protein':
        return 'Protein';
      case 'carbs':
        return 'Carbs';
      case 'fats':
        return 'Fats';
      default:
        return key;
    }
  }

  IconData _macroIcon(String key) {
    switch (key) {
      case 'protein':
        return Icons.egg_alt_outlined;
      case 'carbs':
        return Icons.grain;
      case 'fats':
        return Icons.water_drop_outlined;
      default:
        return Icons.restaurant_menu;
    }
  }
}

class _TrainingTargetDialog extends StatefulWidget {
  final List<String> availableMuscles;
  final Target? existingTarget;

  const _TrainingTargetDialog({
    required this.availableMuscles,
    this.existingTarget,
  });

  @override
  State<_TrainingTargetDialog> createState() => _TrainingTargetDialogState();
}

class _TrainingTargetDialogState extends State<_TrainingTargetDialog> {
  String? _selectedMuscle;
  int _weeklyGoal = 12;

  bool get _isEditing => widget.existingTarget != null;

  @override
  void initState() {
    super.initState();
    _selectedMuscle = widget.existingTarget?.categoryKey;
    _weeklyGoal = widget.existingTarget?.weeklyGoal ?? 12;
  }

  @override
  Widget build(BuildContext context) {
    final selectableMuscles = _isEditing
        ? <String>[_selectedMuscle!]
        : widget.availableMuscles;

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Training Goal' : 'Add Training Goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Muscle Group',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedMuscle,
            items: selectableMuscles.map((muscle) {
              return DropdownMenuItem<String>(
                value: muscle,
                child: Text(MuscleGroups.getDisplayName(muscle)),
              );
            }).toList(),
            onChanged: _isEditing
                ? null
                : (value) {
                    setState(() {
                      _selectedMuscle = value;
                    });
                  },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            dropdownColor: AppTheme.surfaceDark,
          ),
          const SizedBox(height: 24),
          Text(
            'Weekly Sets Goal',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _weeklyGoal.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  label: _weeklyGoal.toString(),
                  activeColor: AppTheme.primaryOrange,
                  onChanged: (value) {
                    setState(() {
                      _weeklyGoal = value.toInt();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_weeklyGoal',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedMuscle == null ? null : _submit,
          child: Text(_isEditing ? 'Save Changes' : 'Add'),
        ),
      ],
    );
  }

  void _submit() {
    final target = Target(
      id: widget.existingTarget?.id ?? const Uuid().v4(),
      type: TargetType.muscleSets,
      categoryKey: _selectedMuscle!,
      targetValue: _weeklyGoal.toDouble(),
      unit: 'sets',
      period: TargetPeriod.weekly,
      createdAt: widget.existingTarget?.createdAt ?? DateTime.now(),
    );

    if (_isEditing) {
      context.read<TargetsBloc>().add(UpdateTargetEvent(target));
    } else {
      context.read<TargetsBloc>().add(AddTargetEvent(target));
    }

    Navigator.pop(context);
  }
}

class _MacroTargetDialog extends StatefulWidget {
  final Target? existingTarget;

  const _MacroTargetDialog({
    this.existingTarget,
  });

  @override
  State<_MacroTargetDialog> createState() => _MacroTargetDialogState();
}

class _MacroTargetDialogState extends State<_MacroTargetDialog> {
  late String _selectedMacro;
  late TextEditingController _valueController;

  bool get _isEditing => widget.existingTarget != null;

  @override
  void initState() {
    super.initState();
    _selectedMacro = widget.existingTarget?.categoryKey ?? 'protein';
    _valueController = TextEditingController(
      text: widget.existingTarget?.goalValue.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Macro Goal' : 'Add Macro Goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedMacro,
            items: const [
              DropdownMenuItem(value: 'protein', child: Text('Protein')),
              DropdownMenuItem(value: 'carbs', child: Text('Carbs')),
              DropdownMenuItem(value: 'fats', child: Text('Fats')),
            ],
            onChanged: _isEditing
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedMacro = value;
                    });
                  },
            decoration: const InputDecoration(
              labelText: 'Macro',
              border: OutlineInputBorder(),
            ),
            dropdownColor: AppTheme.surfaceDark,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Target grams per day',
              suffixText: 'g',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Save Changes' : 'Add'),
        ),
      ],
    );
  }

  void _submit() {
    final parsedValue = double.tryParse(_valueController.text.trim());

    if (parsedValue == null || parsedValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid macro target greater than 0.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20),
        ),
      );
      return;
    }

    final target = Target(
      id: widget.existingTarget?.id ?? const Uuid().v4(),
      type: TargetType.macro,
      categoryKey: _selectedMacro,
      targetValue: parsedValue,
      unit: 'g',
      period: TargetPeriod.daily,
      createdAt: widget.existingTarget?.createdAt ?? DateTime.now(),
    );

    if (_isEditing) {
      context.read<TargetsBloc>().add(UpdateTargetEvent(target));
    } else {
      context.read<TargetsBloc>().add(AddTargetEvent(target));
    }

    Navigator.pop(context);
  }
}