import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/utils/macro_calculator.dart';
import '../../../../domain/entities/meal.dart';
import '../../../../domain/entities/nutrition_log.dart';
import '../../meals/bloc/meal_bloc.dart';
import '../../nutrition/bloc/nutrition_log_bloc.dart';

/// Meal logging tab - searchable meal list with grams input
class LogMealTab extends StatefulWidget {
  const LogMealTab({super.key});

  @override
  State<LogMealTab> createState() => _LogMealTabState();
}

class _LogMealTabState extends State<LogMealTab> {
  Meal? _selectedMeal;
  final _gramsController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final _uuid = const Uuid();

  @override
  void dispose() {
    _gramsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NutritionLogBloc, NutritionLogState>(
      listener: (context, state) {
        if (state is NutritionLogOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(20),
            ),
          );
          _clearForm();
        }

        if (state is NutritionLogError) {
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
      builder: (context, nutritionState) {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMealSelector(context),
                    if (_selectedMeal != null) ...[
                      const SizedBox(height: 20),
                      _buildAmountInput(),
                      const SizedBox(height: 24),
                      _buildNutritionPreview(),
                    ],
                  ],
                ),
              ),
            ),
            if (_selectedMeal != null) _buildLogButton(nutritionState),
          ],
        );
      },
    );
  }

  Widget _buildMealSelector(BuildContext context) {
    return BlocBuilder<MealBloc, MealState>(
      builder: (context, state) {
        final allMeals = state is MealsLoaded ? state.meals : <Meal>[];

        if (allMeals.isEmpty) {
          return _buildEmptyMealsState(context);
        }

        // Filter meals based on search query
        final filteredMeals = _searchQuery.isEmpty
            ? allMeals
            : allMeals
                .where((meal) =>
                    meal.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.selectMeal,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchMeals,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Meal list
            if (filteredMeals.isEmpty)
              _buildNoResultsState()
            else
              ...filteredMeals.map((meal) => _buildMealCard(meal)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyMealsState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.restaurant_outlined,
            size: 48,
            color: AppTheme.textDim,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.noMealsInLibrary,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.createMealsInLibrary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMedium,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off,
            size: 48,
            color: AppTheme.textDim,
          ),
          const SizedBox(height: 12),
          Text(
            'No meals found',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMedium,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(Meal meal) {
    final isSelected = _selectedMeal?.id == meal.id;
    final calculatedCalories = MacroCalculator.calculateCalories(
      protein: meal.proteinPerServing,
      carbs: meal.carbsPerServing,
      fats: meal.fatsPerServing,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? AppTheme.primaryOrange.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryOrange : AppTheme.borderDark,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMeal = meal;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meal.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppTheme.primaryOrange : null,
                          ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryOrange,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${AppStrings.per100g}: ${meal.servingSizeGrams}g',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textDim,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroChip(
                    label: AppStrings.protein,
                    value: '${meal.proteinPerServing.toStringAsFixed(1)}g',
                    color: Colors.blue,
                  ),
                  _buildMacroChip(
                    label: AppStrings.carbs,
                    value: '${meal.carbsPerServing.toStringAsFixed(1)}g',
                    color: Colors.green,
                  ),
                  _buildMacroChip(
                    label: AppStrings.fats,
                    value: '${meal.fatsPerServing.toStringAsFixed(1)}g',
                    color: Colors.orange,
                  ),
                  _buildMacroChip(
                    label: AppStrings.kcal,
                    value: calculatedCalories.round().toString(),
                    color: AppTheme.primaryOrange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textDim,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.amountGrams,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _gramsController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: AppStrings.amountGramsHint,
            prefixIcon: const Icon(Icons.straighten),
            suffixText: AppStrings.grams,
          ),
          onChanged: (value) {
            setState(() {}); // Trigger nutrition preview update
          },
        ),
      ],
    );
  }

  Widget _buildNutritionPreview() {
    if (_selectedMeal == null || _gramsController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final grams = int.tryParse(_gramsController.text) ?? 0;
    if (grams <= 0) return const SizedBox.shrink();

    final multiplier = grams / _selectedMeal!.servingSizeGrams;
    final protein = _selectedMeal!.proteinPerServing * multiplier;
    final carbs = _selectedMeal!.carbsPerServing * multiplier;
    final fats = _selectedMeal!.fatsPerServing * multiplier;
    final calories = MacroCalculator.calculateCalories(
      protein: protein,
      carbs: carbs,
      fats: fats,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryOrange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.primaryOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Nutrition for ${grams}g',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutritionItem(
                label: AppStrings.protein,
                value: '${protein.toStringAsFixed(1)}g',
                color: Colors.blue,
              ),
              _buildNutritionItem(
                label: AppStrings.carbs,
                value: '${carbs.toStringAsFixed(1)}g',
                color: Colors.green,
              ),
              _buildNutritionItem(
                label: AppStrings.fats,
                value: '${fats.toStringAsFixed(1)}g',
                color: Colors.orange,
              ),
              _buildNutritionItem(
                label: AppStrings.calories,
                value: '${calories.round()}',
                color: AppTheme.primaryOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMedium,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLogButton(NutritionLogState state) {
    final isLoading = state is NutritionLogLoading;
    final canLog = _selectedMeal != null &&
        _gramsController.text.isNotEmpty &&
        (int.tryParse(_gramsController.text) ?? 0) > 0;

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
          child: ElevatedButton(
            onPressed: (canLog && !isLoading) ? _handleLogMeal : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    AppStrings.logMealButton,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _handleLogMeal() {
    if (_selectedMeal == null) return;

    final grams = int.parse(_gramsController.text);
    final multiplier = grams / _selectedMeal!.servingSizeGrams;

    final nutritionLog = NutritionLog(
      id: _uuid.v4(),
      mealId: _selectedMeal!.id,
      mealName: _selectedMeal!.name,
      gramsConsumed: grams,
      proteinGrams: _selectedMeal!.proteinPerServing * multiplier,
      carbsGrams: _selectedMeal!.carbsPerServing * multiplier,
      fatsGrams: _selectedMeal!.fatsPerServing * multiplier,
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );

    context.read<NutritionLogBloc>().add(AddNutritionLogEvent(nutritionLog));
  }

  void _clearForm() {
    setState(() {
      _selectedMeal = null;
      _gramsController.clear();
      _searchController.clear();
      _searchQuery = '';
    });
  }
}