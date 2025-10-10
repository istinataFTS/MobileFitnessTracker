import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/workout_sets_manager.dart';
import '../../../core/utils/exercises_manager.dart';
import '../../../domain/entities/workout_set.dart';

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
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          WorkoutSetsManager(),
          ExercisesManager(),
        ]),
        builder: (context, child) {
          return Column(
            children: [
              if (_selectedFilter != 'All') _buildFilterChip(),
              Expanded(
                child: _buildSetsList(),
              ),
            ],
          );
        },
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

  Widget _buildSetsList() {
    final setsManager = WorkoutSetsManager();
    final exercisesManager = ExercisesManager();
    final allSets = setsManager.allSets;
    
    // Filter sets based on muscle group
    final filteredSets = _selectedFilter == 'All'
        ? allSets
        : allSets.where((set) {
            final exercise = exercisesManager.getExerciseById(set.exerciseId);
            if (exercise == null) return false;
            
            return exercise.muscleGroups.any((mg) =>
                MuscleGroups.getDisplayName(mg) == _selectedFilter);
          }).toList();

    if (filteredSets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: AppTheme.textDim,
            ),
            const SizedBox(height: 16),
            Text(
              'No sets logged yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging sets to see them here',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    // Group by date
    final grouped = <DateTime, List<WorkoutSet>>{};
    for (final set in filteredSets) {
      final date = DateTime(set.date.year, set.date.month, set.date.day);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(set);
    }

    // Sort dates descending
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final sets = grouped[date]!;
        return _buildDateCard(date, sets);
      },
    );
  }

  Widget _buildDateCard(DateTime date, List<WorkoutSet> sets) {
    final exercisesManager = ExercisesManager();
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    final totalSets = sets.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDayDetails(date, sets),
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
                          DateFormat('h:mm a').format(sets.first.createdAt),
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
                      '$totalSets set${totalSets != 1 ? 's' : ''}',
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
              ...sets.take(3).map((set) {
                final exercise = exercisesManager.getExerciseById(set.exerciseId);
                final exerciseName = exercise?.name ?? 'Unknown Exercise';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$exerciseName - ${set.reps} reps @ ${set.weight}kg',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (sets.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+ ${sets.length - 3} more set${sets.length - 3 != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryOrange,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
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

  void _showDayDetails(DateTime date, List<WorkoutSet> sets) {
    final exercisesManager = ExercisesManager();
    
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
              Text(
                DateFormat('EEEE, MMMM d, y').format(date),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              ...sets.map((set) {
                final exercise = exercisesManager.getExerciseById(set.exerciseId);
                final exerciseName = exercise?.name ?? 'Unknown Exercise';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              exerciseName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (exercise != null)
                            Wrap(
                              spacing: 4,
                              children: exercise.muscleGroups.take(2).map((mg) {
                                return Chip(
                                  label: Text(
                                    MuscleGroups.getDisplayName(mg),
                                  ),
                                  backgroundColor:
                                      AppTheme.primaryOrange.withOpacity(0.1),
                                  labelStyle: const TextStyle(
                                    color: AppTheme.primaryOrange,
                                    fontSize: 10,
                                  ),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.repeat, size: 16),
                          const SizedBox(width: 4),
                          Text('${set.reps} reps'),
                          const SizedBox(width: 16),
                          const Icon(Icons.monitor_weight, size: 16),
                          const SizedBox(width: 4),
                          Text('${set.weight}kg'),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }
}