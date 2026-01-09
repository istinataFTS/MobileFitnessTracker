import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/macro_calculator.dart';
import '../../../domain/entities/meal.dart';
import '../meals/bloc/meal_bloc.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/utils/macro_calculator.dart';
import '../../../../domain/entities/meal.dart';
import '../../meals/bloc/meal_bloc.dart';

/// Meals management tab for the Library page
/// Handles CRUD operations for meal library
class MealsTab extends StatelessWidget {
  const MealsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MealBloc, MealState>(
      listener: (context, state) {
        // Handle success feedback
        if (state is MealOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(20),
            ),
          );
        }

        // Handle errors
        if (state is MealError) {
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
        // Show loading state
        if (state is MealLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryOrange,
            ),
          );
        }

        // Show error state with retry option
        if (state is MealError) {
          return _buildErrorState(context, state.message);
        }

        // Show loaded state (empty or with meals)
        final meals = state is MealsLoaded ? state.meals : <Meal>[];

        return Column(
          children: [
            Expanded(
              child: meals.isEmpty
                  ? _buildEmptyState(context)
                  : _buildMealsList(context, meals),
            ),
            _buildAddButton(context),
          ],
        );
      },
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
                Icons.restaurant_outlined,
                size: 60,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.noMealsYet,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.createMealsDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddMealDialog(context),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addFirstMeal),
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

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
              'Error Loading Meals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<MealBloc>().add(LoadMealsEvent());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsList(BuildContext context, List<Meal> meals) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return _buildMealCard(context, meal);
      },
    );
  }

  Widget _buildMealCard(BuildContext context, Meal meal) {
    final calculatedCalories = MacroCalculator.calculateCalories(
      protein: meal.proteinPerServing,
      carbs: meal.carbsPerServing,
      fats: meal.fatsPerServing,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEditMealDialog(context, meal),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal name and actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meal.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppTheme.textDim),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditMealDialog(context, meal);
                      } else if (value == 'delete') {
                        _confirmDeleteMeal(context, meal);
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
                            Text(AppStrings.delete,
                                style: TextStyle(color: AppTheme.errorRed)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Serving size
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${AppStrings.servingSize}: ${meal.servingSizeGrams}g',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Macros
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroItem(
                    context,
                    label: AppStrings.protein,
                    value: '${meal.proteinPerServing.toStringAsFixed(1)}g',
                    color: Colors.blue,
                  ),
                  _buildMacroItem(
                    context,
                    label: AppStrings.carbs,
                    value: '${meal.carbsPerServing.toStringAsFixed(1)}g',
                    color: Colors.green,
                  ),
                  _buildMacroItem(
                    context,
                    label: AppStrings.fats,
                    value: '${meal.fatsPerServing.toStringAsFixed(1)}g',
                    color: Colors.orange,
                  ),
                  _buildMacroItem(
                    context,
                    label: AppStrings.calories,
                    value: '${calculatedCalories.round()} kcal',
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

  Widget _buildMacroItem(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMedium,
              ),
        ),
      ],
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
            onPressed: () => _showAddMealDialog(context),
            icon: const Icon(Icons.add),
            label: const Text(
              AppStrings.addMeal,
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

  void _showAddMealDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<MealBloc>(),
        child: const _MealDialog(),
      ),
    );
  }

  void _showEditMealDialog(BuildContext context, Meal meal) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<MealBloc>(),
        child: _MealDialog(meal: meal),
      ),
    );
  }

  void _confirmDeleteMeal(BuildContext context, Meal meal) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteMeal),
        content: Text('${AppStrings.deleteMealConfirm}\n\n${meal.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<MealBloc>().add(DeleteMealEvent(meal.id));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

// ==================== Meal Dialog ====================

/// Unified dialog for adding and editing meals
class _MealDialog extends StatefulWidget {
  final Meal? meal; // null for add, non-null for edit

  const _MealDialog({this.meal});

  @override
  State<_MealDialog> createState() => _MealDialogState();
}

class _MealDialogState extends State<_MealDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _servingSizeController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatsController;
  final _uuid = const Uuid();

  bool get isEditing => widget.meal != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meal?.name ?? '');
    _servingSizeController = TextEditingController(
      text: widget.meal?.servingSizeGrams.toString() ?? '100',
    );
    _proteinController = TextEditingController(
      text: widget.meal?.proteinPerServing.toStringAsFixed(1) ?? '',
    );
    _carbsController = TextEditingController(
      text: widget.meal?.carbsPerServing.toStringAsFixed(1) ?? '',
    );
    _fatsController = TextEditingController(
      text: widget.meal?.fatsPerServing.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _servingSizeController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
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
              isEditing ? AppStrings.editMeal : AppStrings.addMeal,
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
          // Meal name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: AppStrings.mealName,
              hintText: AppStrings.mealNameHint,
              prefixIcon: Icon(Icons.restaurant),
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: !isEditing,
          ),
          const SizedBox(height: 20),
          
          // Serving size
          TextField(
            controller: _servingSizeController,
            decoration: const InputDecoration(
              labelText: '${AppStrings.servingSize} (g)',
              hintText: AppStrings.servingSizeHint,
              prefixIcon: Icon(Icons.straighten),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 24),
          
          Text(
            AppStrings.macrosPerServing,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          
          // Protein
          TextField(
            controller: _proteinController,
            decoration: const InputDecoration(
              labelText: AppStrings.proteinGrams,
              hintText: '0.0',
              prefixIcon: Icon(Icons.egg),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
            ],
            onChanged: (_) => setState(() {}), // Trigger calories recalc
          ),
          const SizedBox(height: 12),
          
          // Carbs
          TextField(
            controller: _carbsController,
            decoration: const InputDecoration(
              labelText: AppStrings.carbsGrams,
              hintText: '0.0',
              prefixIcon: Icon(Icons.grain),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
            ],
            onChanged: (_) => setState(() {}), // Trigger calories recalc
          ),
          const SizedBox(height: 12),
          
          // Fats
          TextField(
            controller: _fatsController,
            decoration: const InputDecoration(
              labelText: AppStrings.fatsGrams,
              hintText: '0.0',
              prefixIcon: Icon(Icons.water_drop),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
            ],
            onChanged: (_) => setState(() {}), // Trigger calories recalc
          ),
          const SizedBox(height: 20),
          
          // Calculated calories display
          _buildCaloriesDisplay(context),
        ],
      ),
    );
  }

  Widget _buildCaloriesDisplay(BuildContext context) {
    final protein = double.tryParse(_proteinController.text) ?? 0.0;
    final carbs = double.tryParse(_carbsController.text) ?? 0.0;
    final fats = double.tryParse(_fatsController.text) ?? 0.0;
    
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
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.totalCalories,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${calories.round()} ${AppStrings.kcal}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AppStrings.autocalculated,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final isValid = _nameController.text.trim().isNotEmpty &&
        _servingSizeController.text.trim().isNotEmpty &&
        (double.tryParse(_proteinController.text) ?? 0) >= 0 &&
        (double.tryParse(_carbsController.text) ?? 0) >= 0 &&
        (double.tryParse(_fatsController.text) ?? 0) >= 0;

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
    final servingSize = int.parse(_servingSizeController.text.trim());
    final protein = double.parse(_proteinController.text.trim());
    final carbs = double.parse(_carbsController.text.trim());
    final fats = double.parse(_fatsController.text.trim());

    if (isEditing) {
      // Update existing meal
      final updatedMeal = widget.meal!.copyWith(
        name: name,
        servingSizeGrams: servingSize,
        proteinPerServing: protein,
        carbsPerServing: carbs,
        fatsPerServing: fats,
      );
      context.read<MealBloc>().add(UpdateMealEvent(updatedMeal));
    } else {
      // Create new meal
      final newMeal = Meal(
        id: _uuid.v4(),
        name: name,
        servingSizeGrams: servingSize,
        proteinPerServing: protein,
        carbsPerServing: carbs,
        fatsPerServing: fats,
        createdAt: DateTime.now(),
      );
      context.read<MealBloc>().add(AddMealEvent(newMeal));
    }

    Navigator.pop(context);
  }
}