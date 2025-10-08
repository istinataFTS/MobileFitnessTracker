import 'package:flutter/material.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/goals_manager.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(              
              context,
              title: 'Weekly Goals',
              children: [
                _buildGoalsCard(context),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'General',
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage workout reminders',
                  onTap: () => _showComingSoon(context),
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.calendar_month_outlined,
                  title: 'Week Start Day',
                  subtitle: 'Monday',
                  onTap: () => _showComingSoon(context),
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.backup_outlined,
                  title: 'Backup & Restore',
                  subtitle: 'Export or import your data',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'About',
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.info_outlined,
                  title: 'App Version',
                  subtitle: '1.0.0',
                  onTap: null,
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Terms & Privacy',
                  onTap: () => _showComingSoon(context),
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.bug_report_outlined,
                  title: 'Report a Bug',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildGoalsCard(BuildContext context) {
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
                  'Muscle Group Goals',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => _showEditGoalsDialog(context),
                  child: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Customize your weekly set targets for each muscle group',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryOrange),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, color: AppTheme.textDim)
            : null,
        onTap: onTap,
      ),
    );
  }

  void _showEditGoalsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return _EditGoalsDialog();
      },
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _EditGoalsDialog extends StatefulWidget {
  @override
  State<_EditGoalsDialog> createState() => _EditGoalsDialogState();
}

class _EditGoalsDialogState extends State<_EditGoalsDialog> {
  late Map<String, int> _goals;
  final _goalsManager = GoalsManager();

  @override
  void initState() {
    super.initState();
    // Load actual goals from GoalsManager
    _goals = Map.from(_goalsManager.goals);
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
                    'Edit Weekly Goals',
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
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(20),
                itemCount: MuscleGroups.all.length,
                itemBuilder: (context, index) {
                  final muscle = MuscleGroups.all[index];
                  final displayName = MuscleGroups.getDisplayName(muscle);
                  final currentGoal = _goals[muscle] ?? 10;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        _buildGoalCounter(muscle, currentGoal),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _goals = Map.from(MuscleGroups.defaultWeeklyGoals);
                        });
                      },
                      child: const Text('Reset to Default'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Save goals to GoalsManager
                        _goalsManager.updateAllGoals(_goals);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Goals updated!'),
                            backgroundColor: AppTheme.successGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Save'),
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

  Widget _buildGoalCounter(String muscle, int currentGoal) {
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
            onPressed: currentGoal > 0
                ? () {
                    setState(() {
                      _goals[muscle] = currentGoal - 1;
                    });
                  }
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              currentGoal.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          _buildCounterButton(
            icon: Icons.add,
            onPressed: () {
              setState(() {
                _goals[muscle] = currentGoal + 1;
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
}