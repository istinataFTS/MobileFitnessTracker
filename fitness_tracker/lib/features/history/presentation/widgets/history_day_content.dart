import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/muscle_groups.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/entities/exercise.dart';
import '../../../../domain/entities/nutrition_log.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../../../presentation/pages/exercises/bloc/exercise_bloc.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import 'edit_nutrition_log_dialog.dart';
import 'edit_set_dialog.dart';
import 'history_log_bottom_sheets.dart';

class HistoryDayContent extends StatefulWidget {
  final DateTime? selectedDate;
  final List<WorkoutSet> workoutSets;
  final List<NutritionLog> nutritionLogs;
  final WeightUnit weightUnit;
  final VoidCallback onClearSelection;
  final int highlightVersion;

  const HistoryDayContent({
    super.key,
    required this.selectedDate,
    required this.workoutSets,
    required this.nutritionLogs,
    required this.weightUnit,
    required this.onClearSelection,
    this.highlightVersion = 0,
  });

  @override
  State<HistoryDayContent> createState() => _HistoryDayContentState();
}

class _HistoryDayContentState extends State<HistoryDayContent> {
  bool _isHighlighted = false;
  Timer? _highlightResetTimer;

  @override
  void didUpdateWidget(covariant HistoryDayContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool shouldTriggerHighlight =
        widget.highlightVersion != oldWidget.highlightVersion &&
            widget.selectedDate != null;

    if (shouldTriggerHighlight) {
      _triggerHighlight();
    }
  }

  @override
  void dispose() {
    _highlightResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedDate == null) {
      return const _SelectionHint(
        icon: Icons.touch_app_outlined,
        message: 'Select a day to view workouts and nutrition history.',
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _isHighlighted
            ? AppTheme.primaryOrange.withOpacity(0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isHighlighted
              ? AppTheme.primaryOrange.withOpacity(0.35)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SelectedDayHeader(
            date: widget.selectedDate!,
            workoutCount: widget.workoutSets.length,
            nutritionCount: widget.nutritionLogs.length,
            onClearSelection: widget.onClearSelection,
          ),
          const SizedBox(height: 16),
          _WorkoutHistorySection(
            date: widget.selectedDate!,
            sets: widget.workoutSets,
            weightUnit: widget.weightUnit,
          ),
          const SizedBox(height: 16),
          _NutritionHistorySection(
            date: widget.selectedDate!,
            logs: widget.nutritionLogs,
          ),
        ],
      ),
    );
  }

  void _triggerHighlight() {
    _highlightResetTimer?.cancel();

    setState(() {
      _isHighlighted = true;
    });

    _highlightResetTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _isHighlighted = false;
      });
    });
  }
}

class _SelectedDayHeader extends StatelessWidget {
  final DateTime date;
  final int workoutCount;
  final int nutritionCount;
  final VoidCallback onClearSelection;

  const _SelectedDayHeader({
    required this.date,
    required this.workoutCount,
    required this.nutritionCount,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('EEEE, MMM d').format(date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _CountChip(
                      icon: Icons.fitness_center,
                      label:
                          '$workoutCount workout${workoutCount == 1 ? '' : 's'}',
                    ),
                    _CountChip(
                      icon: Icons.restaurant_menu,
                      label:
                          '$nutritionCount entr${nutritionCount == 1 ? 'y' : 'ies'}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClearSelection,
            icon: const Icon(Icons.close),
            tooltip: 'Clear selected day',
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CountChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppTheme.primaryOrange),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutHistorySection extends StatelessWidget {
  final DateTime date;
  final List<WorkoutSet> sets;
  final WeightUnit weightUnit;

  const _WorkoutHistorySection({
    required this.date,
    required this.sets,
    required this.weightUnit,
  });

  @override
  Widget build(BuildContext context) {
    return _HistorySectionCard(
      icon: Icons.fitness_center,
      title: 'Workout history',
      subtitle: '${sets.length} set${sets.length == 1 ? '' : 's'} logged',
      onAddPressed: () => showHistoryWorkoutLogBottomSheet(
        context,
        selectedDate: date,
      ),
      addTooltip: 'Add workout set',
      child: sets.isEmpty
          ? _InlineEmptyHint(
              icon: Icons.fitness_center_outlined,
              title: 'No workouts on this day',
              message: 'Try another date or add a workout for this day.',
              ctaLabel: 'Log workout for ${DateFormat('MMM d').format(date)}',
              onPressed: () => showHistoryWorkoutLogBottomSheet(
                context,
                selectedDate: date,
              ),
            )
          : BlocBuilder<ExerciseBloc, ExerciseState>(
              builder: (BuildContext context, ExerciseState exerciseState) {
                if (exerciseState is! ExercisesLoaded) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final Map<String, Exercise> exerciseMap = <String, Exercise>{
                  for (final Exercise exercise in exerciseState.exercises)
                    exercise.id: exercise,
                };

                final List<WorkoutSet> visibleSets = sets
                    .where((WorkoutSet set) =>
                        exerciseMap.containsKey(set.exerciseId))
                    .toList();

                if (visibleSets.isEmpty) {
                  return const _InlineEmptyHint(
                    icon: Icons.search_off,
                    title: 'Workout details unavailable',
                    message:
                        'The exercise metadata for these sets could not be loaded.',
                  );
                }

                return Column(
                  children: <Widget>[
                    for (int index = 0;
                        index < visibleSets.length;
                        index++) ...<Widget>[
                      _WorkoutSetCard(
                        set: visibleSets[index],
                        exercise: exerciseMap[visibleSets[index].exerciseId]!,
                        weightUnit: weightUnit,
                      ),
                      if (index < visibleSets.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
    );
  }
}

class _WorkoutSetCard extends StatelessWidget {
  final WorkoutSet set;
  final Exercise exercise;
  final WeightUnit weightUnit;

  const _WorkoutSetCard({
    required this.set,
    required this.exercise,
    required this.weightUnit,
  });

  @override
  Widget build(BuildContext context) {
    final String muscleGroups = exercise.muscleGroups
        .map(MuscleGroups.getDisplayName)
        .join(', ');

    final String displayWeight = _formatWeight(
      set.weight,
      weightUnit,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditDialog(context),
                  tooltip: 'Edit set',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(context),
                  tooltip: 'Delete set',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _MetricChip(icon: Icons.repeat, label: '${set.reps} reps'),
                _MetricChip(
                  icon: Icons.fitness_center,
                  label: displayWeight,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              muscleGroups,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => BlocProvider.value(
        value: context.read<HistoryBloc>(),
        child: EditSetDialog(
          workoutSet: set,
          exercise: exercise,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final String displayWeight = _formatWeight(
      set.weight,
      weightUnit,
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Delete Set?'),
        content: Text(
          'Remove ${exercise.name} - ${set.reps} reps @ $displayWeight?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<HistoryBloc>().add(DeleteSetEvent(set.id));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatWeight(double weightKg, WeightUnit unit) {
    switch (unit) {
      case WeightUnit.kilograms:
        return '${_formatNumber(weightKg)} kg';
      case WeightUnit.pounds:
        final pounds = weightKg * 2.2046226218;
        return '${_formatNumber(pounds)} lb';
    }
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _NutritionHistorySection extends StatelessWidget {
  final DateTime date;
  final List<NutritionLog> logs;

  const _NutritionHistorySection({
    required this.date,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final _NutritionTotals totals = _NutritionTotals.fromLogs(logs);

    return _HistorySectionCard(
      icon: Icons.restaurant_menu,
      title: 'Nutrition history',
      subtitle: '${logs.length} entr${logs.length == 1 ? 'y' : 'ies'} logged',
      onAddPressed: () => showHistoryNutritionTypeBottomSheet(
        context,
        selectedDate: date,
      ),
      addTooltip: 'Add nutrition entry',
      headerTrailing: logs.isEmpty
          ? null
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _SummaryChip(
                  label: 'Protein',
                  value: '${totals.protein.toStringAsFixed(0)}g',
                ),
                _SummaryChip(
                  label: 'Carbs',
                  value: '${totals.carbs.toStringAsFixed(0)}g',
                ),
                _SummaryChip(
                  label: 'Fats',
                  value: '${totals.fats.toStringAsFixed(0)}g',
                ),
                _SummaryChip(
                  label: 'Calories',
                  value: '${totals.calories.round()} kcal',
                ),
              ],
            ),
      child: logs.isEmpty
          ? _InlineEmptyHint(
              icon: Icons.restaurant_outlined,
              title: 'No nutrition on this day',
              message: 'Try another date or add nutrition for this day.',
              ctaLabel: 'Log nutrition for ${DateFormat('MMM d').format(date)}',
              onPressed: () => showHistoryNutritionTypeBottomSheet(
                context,
                selectedDate: date,
              ),
            )
          : Column(
              children: <Widget>[
                for (int index = 0; index < logs.length; index++) ...<Widget>[
                  _NutritionLogCard(log: logs[index]),
                  if (index < logs.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _NutritionLogCard extends StatelessWidget {
  final NutritionLog log;

  const _NutritionLogCard({
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    final String time = DateFormat('HH:mm').format(log.loggedAt);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  log.isMealLog ? Icons.restaurant : Icons.calculate,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    log.mealName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textDim,
                      ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditDialog(context),
                  tooltip: 'Edit nutrition log',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(context),
                  tooltip: 'Delete nutrition log',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (log.gramsConsumed != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${log.gramsConsumed!.toStringAsFixed(0)} g consumed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _MacroChip(
                  label: 'P',
                  value: '${log.proteinGrams.toStringAsFixed(0)}g',
                ),
                _MacroChip(
                  label: 'C',
                  value: '${log.carbsGrams.toStringAsFixed(0)}g',
                ),
                _MacroChip(
                  label: 'F',
                  value: '${log.fatGrams.toStringAsFixed(0)}g',
                ),
                _MacroChip(
                  label: 'Kcal',
                  value: '${log.calories.round()}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => BlocProvider.value(
        value: context.read<HistoryBloc>(),
        child: EditNutritionLogDialog(log: log),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Delete Nutrition Log?'),
        content: Text('Remove "${log.mealName}" from history?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<HistoryBloc>()
                  .add(DeleteNutritionHistoryLogEvent(log.id));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _HistorySectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? headerTrailing;
  final VoidCallback? onAddPressed;
  final String? addTooltip;

  const _HistorySectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.headerTrailing,
    this.onAddPressed,
    this.addTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (onAddPressed != null)
                IconButton(
                  onPressed: onAddPressed,
                  icon: const Icon(Icons.add),
                  tooltip: addTooltip ?? 'Add',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMedium,
                ),
          ),
          if (headerTrailing != null) ...<Widget>[
            const SizedBox(height: 12),
            headerTrailing!,
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppTheme.primaryOrange),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          children: <InlineSpan>[
            const TextSpan(
              text: '',
            ),
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppTheme.textMedium,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppTheme.primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;

  const _MacroChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppTheme.primaryOrange,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SelectionHint extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SelectionHint({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _HintCard(
      icon: icon,
      title: 'No day selected',
      message: message,
    );
  }
}

class _InlineEmptyHint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onPressed;

  const _InlineEmptyHint({
    required this.icon,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _HintCard(
      icon: icon,
      title: title,
      message: message,
      ctaLabel: ctaLabel,
      onPressed: onPressed,
    );
  }
}

class _HintCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onPressed;

  const _HintCard({
    required this.icon,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppTheme.textDim),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                ),
                if (ctaLabel != null && onPressed != null) ...<Widget>[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.add),
                    label: Text(ctaLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionTotals {
  final double protein;
  final double carbs;
  final double fats;
  final double calories;

  const _NutritionTotals({
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.calories,
  });

  factory _NutritionTotals.fromLogs(List<NutritionLog> logs) {
    double protein = 0;
    double carbs = 0;
    double fats = 0;
    double calories = 0;

    for (final NutritionLog log in logs) {
      protein += log.proteinGrams;
      carbs += log.carbsGrams;
      fats += log.fatGrams;
      calories += log.calories;
    }

    return _NutritionTotals(
      protein: protein,
      carbs: carbs,
      fats: fats,
      calories: calories,
    );
  }
}