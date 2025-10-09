import 'package:flutter/material.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/targets_manager.dart';
import '../../../domain/entities/target.dart';

class TargetsPage extends StatelessWidget {
  const TargetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Targets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
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
              if (targets.isEmpty)
                Expanded(child: _buildEmptyState(context))
              else
                Expanded(child: _buildTargetsList(context, targets)),
              _buildAddTargetButton(context, targetsManager),
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
            Icon(
              Icons.flag_outlined,
              size: 80,
              color: AppTheme.textDim,
            ),
            const SizedBox(height: 24),
            Text(
              'No Targets Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add muscle groups you want to focus on and set weekly rep targets for each',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddTargetDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Target'),
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
          displayName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${target.weeklyGoal} sets per week',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: AppTheme.primaryOrange,
              onPressed: () => _showEditTargetDialog(context, target),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppTheme.errorRed,
              onPressed: () => _confirmDeleteTarget(context, target),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTargetButton(
      BuildContext context, TargetsManager targetsManager) {
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
              hasAvailableMuscles ? 'Add Target' : 'All Muscle Groups Added',
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
          content: Text('All muscle groups have been added as targets!'),
          behavior: SnackBarBehavior.floating,
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
        title: const Text('Remove Target'),
        content: Text('Remove $displayName from your targets?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              TargetsManager().removeTarget(target.muscleGroup);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$displayName removed from targets'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Targets'),
        content: const Text(
          'Targets let you focus on specific muscle groups. '
          'Add the muscles you want to train and set weekly rep goals for each. '
          'Track your progress on the home page!',
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
    return AlertDialog(
      title: const Text('Add Target'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Muscle Group',
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
            'Weekly Rep Goal',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: _weeklyGoal > 1
                    ? () => setState(() => _weeklyGoal--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppTheme.primaryOrange,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_weeklyGoal sets',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _weeklyGoal++),
                icon: const Icon(Icons.add_circle_outline),
                color: AppTheme.primaryOrange,
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
          onPressed: _selectedMuscle != null
              ? () {
                  TargetsManager().addTarget(_selectedMuscle!, _weeklyGoal);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${MuscleGroups.getDisplayName(_selectedMuscle!)} added to targets!',
                      ),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              : null,
          child: const Text('Add Target'),
        ),
      ],
    );
  }
}

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
      title: Text('Edit $displayName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Weekly Rep Goal',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: _weeklyGoal > 1
                    ? () => setState(() => _weeklyGoal--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppTheme.primaryOrange,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_weeklyGoal sets',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _weeklyGoal++),
                icon: const Icon(Icons.add_circle_outline),
                color: AppTheme.primaryOrange,
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
          onPressed: () {
            TargetsManager().updateTarget(
              widget.target.muscleGroup,
              _weeklyGoal,
            );
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$displayName updated!'),
                backgroundColor: AppTheme.successGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}