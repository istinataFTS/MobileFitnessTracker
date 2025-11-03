import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/target.dart';
import 'bloc/targets_bloc.dart';

/// Clean targets management page using BLoC pattern with database persistence
class TargetsPage extends StatelessWidget {
  const TargetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text(AppStrings.targetsTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: AppStrings.aboutTargets,
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
            return Center(
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
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
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
            );
          }

          final targets = state is TargetsLoaded ? state.targets : <Target>[];
          final availableMuscles = _getAvailableMuscleGroups(targets);

          return Column(
            children: [
              Expanded(
                child: targets.isEmpty
                    ? _buildEmptyState(context)
                    : _buildTargetsList(context, targets),
              ),
              _buildAddButton(context, availableMuscles),
            ],
          );
        },
      ),
    );
  }

  List<String> _getAvailableMuscleGroups(List<Target> targets) {
    final targetedMuscles = targets.map((t) => t.muscleGroup).toSet();
    return MuscleGroups.all
        .where((muscle) => !targetedMuscles.contains(muscle))
        .toList();
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
                Icons.flag_outlined,
                size: 60,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.noTargetsYet,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.noTargetsDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddTargetDialog(context),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addFirstTarget),
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

  Widget _buildTargetsList(BuildContext context, List<Target> targets) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: targets.length,
      itemBuilder: (context, index) {
        final target = targets[index];
        return _buildTargetCard(context, target);
      },
    );
  }

  Widget _buildTargetCard(BuildContext context, Target target) {
    final displayName = MuscleGroups.getDisplayName(target.muscleGroup);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEditTargetDialog(context, target),
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
                  Icons.flag,
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
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${target.weeklyGoal} ${AppStrings.setsPerWeek}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textMedium,
                          ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.textDim),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditTargetDialog(context, target);
                  } else if (value == 'delete') {
                    _confirmDeleteTarget(context, target);
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
                        Icon(Icons.delete_outline,
                            size: 20, color: AppTheme.errorRed),
                        SizedBox(width: 12),
                        Text(AppStrings.remove,
                            style: TextStyle(color: AppTheme.errorRed)),
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

  Widget _buildAddButton(BuildContext context, List<String> availableMuscles) {
    final hasAvailableMuscles = availableMuscles.isNotEmpty;

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
            onPressed: hasAvailableMuscles
                ? () => _showAddTargetDialog(context)
                : null,
            icon: const Icon(Icons.add),
            label: Text(
              hasAvailableMuscles
                  ? AppStrings.addTarget
                  : AppStrings.allMuscleGroupsAdded,
              style: const TextStyle(
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

  void _showAddTargetDialog(BuildContext context) {
    final state = context.read<TargetsBloc>().state;
    if (state is! TargetsLoaded) return;

    final availableMuscles = _getAvailableMuscleGroups(state.targets);

    if (availableMuscles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.allMuscleGroupsAdded),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<TargetsBloc>(),
        child: _AddTargetDialog(availableMuscles: availableMuscles),
      ),
    );
  }

  void _showEditTargetDialog(BuildContext context, Target target) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<TargetsBloc>(),
        child: _EditTargetDialog(target: target),
      ),
    );
  }

  void _confirmDeleteTarget(BuildContext context, Target target) {
    final displayName = MuscleGroups.getDisplayName(target.muscleGroup);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.removeTarget),
        content: Text('${AppStrings.removeTargetConfirm}\n\n$displayName'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<TargetsBloc>()
                  .add(DeleteTargetEvent(target.muscleGroup));
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text(AppStrings.remove),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.aboutTargets),
        content: const Text(AppStrings.aboutTargetsDescription),
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

// Add Target Dialog
class _AddTargetDialog extends StatefulWidget {
  final List<String> availableMuscles;

  const _AddTargetDialog({required this.availableMuscles});

  @override
  State<_AddTargetDialog> createState() => _AddTargetDialogState();
}

class _AddTargetDialogState extends State<_AddTargetDialog> {
  String? _selectedMuscle;
  int _weeklyGoal = 12;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppStrings.addTarget,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.selectMuscleGroup,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedMuscle,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: widget.availableMuscles.map((muscle) {
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
            dropdownColor: AppTheme.surfaceDark,
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.weeklyRepGoal,
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
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _selectedMuscle != null ? _handleAddTarget : null,
          child: const Text(AppStrings.add),
        ),
      ],
    );
  }

  void _handleAddTarget() {
    if (_selectedMuscle == null) return;

    final target = Target(
      id: const Uuid().v4(),
      muscleGroup: _selectedMuscle!,
      weeklyGoal: _weeklyGoal,
      createdAt: DateTime.now(),
    );

    context.read<TargetsBloc>().add(AddTargetEvent(target));
    Navigator.pop(context);
  }
}

// Edit Target Dialog
class _EditTargetDialog extends StatefulWidget {
  final Target target;

  const _EditTargetDialog({required this.target});

  @override
  State<_EditTargetDialog> createState() => _EditTargetDialogState();
}

class _EditTargetDialogState extends State<_EditTargetDialog> {
  late int _weeklyGoal;

  @override
  void initState() {
    super.initState();
    _weeklyGoal = widget.target.weeklyGoal;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = MuscleGroups.getDisplayName(widget.target.muscleGroup);

    return AlertDialog(
      title: Text(
        '${AppStrings.editTarget}: $displayName',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.weeklyRepGoal,
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
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _handleUpdateTarget,
          child: const Text(AppStrings.saveChanges),
        ),
      ],
    );
  }

  void _handleUpdateTarget() {
    final updatedTarget = widget.target.copyWith(weeklyGoal: _weeklyGoal);
    context.read<TargetsBloc>().add(UpdateTargetEvent(updatedTarget));
    Navigator.pop(context);
  }
}