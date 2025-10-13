import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/targets_manager.dart';
import '../../../domain/entities/target.dart';

/// Clean targets management page - now a main tab for quick access
class TargetsPage extends StatelessWidget {
  const TargetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text(AppStrings.targetsTitle),
        automaticallyImplyLeading: false, // No back button - it's a main tab
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: AppStrings.aboutTargets,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: TargetsManager(),
        builder: (context, child) {
          final targetsManager = TargetsManager();
          final targets = targetsManager.targets;

          return Column(
            children: [
              Expanded(
                child: targets.isEmpty
                    ? _buildEmptyState(context)
                    : _buildTargetsList(context, targets),
              ),
              _buildAddButton(context, targetsManager),
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
                        Icon(Icons.delete_outline, size: 20, color: AppTheme.errorRed),
                        SizedBox(width: 12),
                        Text(AppStrings.remove, style: TextStyle(color: AppTheme.errorRed)),
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

  Widget _buildAddButton(
    BuildContext context,
    TargetsManager targetsManager,
  ) {
    final hasAvailableMuscles = targetsManager.availableMuscleGroups.isNotEmpty;

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
    final targetsManager = TargetsManager();
    final availableMuscles = targetsManager.availableMuscleGroups;

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
      builder: (context) => _AddTargetDialog(availableMuscles: availableMuscles),
    );
  }

  void _showEditTargetDialog(BuildContext context, Target target) {
    showDialog(
      context: context,
      builder: (context) => _EditTargetDialog(target: target),
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
              TargetsManager().removeTarget(target.muscleGroup);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$displayName ${AppStrings.targetRemoved}'),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(20),
                ),
              );
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
  int _weeklyGoal = 10;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.addTarget,
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
              const SizedBox(height: 24),
              Text(
                AppStrings.selectMuscleGroup,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedMuscle,
                decoration: InputDecoration(
                  hintText: 'Choose a muscle group',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.weeklyRepGoal,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _weeklyGoal > 1
                        ? () => setState(() => _weeklyGoal--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppTheme.primaryOrange,
                    iconSize: 32,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      '$_weeklyGoal ${AppStrings.sets}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _weeklyGoal++),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppTheme.primaryOrange,
                    iconSize: 32,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
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
                      onPressed: _selectedMuscle != null
                          ? () {
                              TargetsManager().addTarget(_selectedMuscle!, _weeklyGoal);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${MuscleGroups.getDisplayName(_selectedMuscle!)} ${AppStrings.targetAdded}',
                                  ),
                                  backgroundColor: AppTheme.successGreen,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(20),
                                ),
                              );
                            }
                          : null,
                      child: const Text(AppStrings.add),
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

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${AppStrings.edit} $displayName',
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
              const SizedBox(height: 24),
              Text(
                AppStrings.weeklyRepGoal,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _weeklyGoal > 1
                        ? () => setState(() => _weeklyGoal--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppTheme.primaryOrange,
                    iconSize: 32,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      '$_weeklyGoal ${AppStrings.sets}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _weeklyGoal++),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppTheme.primaryOrange,
                    iconSize: 32,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
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
                      onPressed: () {
                        TargetsManager().updateTarget(
                          widget.target.muscleGroup,
                          _weeklyGoal,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$displayName ${AppStrings.targetUpdated}'),
                            backgroundColor: AppTheme.successGreen,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(20),
                          ),
                        );
                      },
                      child: const Text(AppStrings.save),
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
}