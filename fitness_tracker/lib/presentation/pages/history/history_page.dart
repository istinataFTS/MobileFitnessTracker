import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';   

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedFilter = 'All';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedFilter != 'All') _buildFilterChip(),
          Expanded(
            child: _buildWorkoutsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Chip(
            label: Text(_selectedFilter),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () {
              setState(() {
                _selectedFilter = 'All';
              });
            },
            backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
            labelStyle: const TextStyle(
              color: AppTheme.primaryOrange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsList() {
    // TODO: Replace with actual data from BLoC
    final mockWorkouts = _generateMockWorkouts();

    if (mockWorkouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No workouts yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging your workouts to see them here',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: mockWorkouts.length,
      itemBuilder: (context, index) {
        final workout = mockWorkouts[index];
        return _buildWorkoutCard(workout);
      },
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    final date = workout['date'] as DateTime;
    final sets = workout['sets'] as Map<String, int>;
    final totalSets = sets.values.fold(0, (sum, count) => sum + count);
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showWorkoutDetails(workout),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday
                              ? 'Today'
                              : DateFormat('EEEE, MMM d').format(date),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('h:mm a').format(date),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalSets sets',
                      style: const TextStyle(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sets.entries.map((entry) {
                  final displayName = MuscleGroups.getDisplayName(entry.key);
                  return Chip(
                    label: Text('$displayName (${entry.value})'),
                    backgroundColor: AppTheme.surfaceDark,
                    side: const BorderSide(color: AppTheme.borderDark),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter by Muscle Group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('All'),
                  leading: Radio<String>(
                    value: 'All',
                    groupValue: _selectedFilter,
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                      Navigator.pop(context);
                    },
                    activeColor: AppTheme.primaryOrange,
                  ),
                ),
                ...MuscleGroups.all.map((muscle) {
                  final displayName = MuscleGroups.getDisplayName(muscle);
                  return ListTile(
                    title: Text(displayName),
                    leading: Radio<String>(
                      value: displayName,
                      groupValue: _selectedFilter,
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value!;
                        });
                        Navigator.pop(context);
                      },
                      activeColor: AppTheme.primaryOrange,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWorkoutDetails(Map<String, dynamic> workout) {
    final date = workout['date'] as DateTime;
    final sets = workout['sets'] as Map<String, int>;
    final totalSets = sets.values.fold(0, (sum, count) => sum + count);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Workout Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(date),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.fitness_center, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$totalSets total sets',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Muscle Groups',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...sets.entries.map((entry) {
                final displayName = MuscleGroups.getDisplayName(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        '${entry.value} sets',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryOrange,
                            ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteWorkout(workout);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                        side: const BorderSide(color: AppTheme.errorRed),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  void _deleteWorkout(Map<String, dynamic> workout) {
    // TODO: Implement delete logic with BLoC
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workout deleted'),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> _generateMockWorkouts() {
    // Mock data for demonstration - replace with actual data from BLoC
    return [
      {
        'date': DateTime.now(),
        'sets': {
          'chest': 4,
          'triceps': 3,
          'shoulder': 2,
        },
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'sets': {
          'lats': 5,
          'biceps': 4,
          'abs': 3,
        },
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'sets': {
          'quads': 4,
          'hamstring': 3,
          'glutes': 3,
        },
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 4)),
        'sets': {
          'shoulder': 5,
          'traps': 3,
          'triceps': 4,
        },
      },
    ];
  }
}