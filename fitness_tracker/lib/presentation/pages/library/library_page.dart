import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/themes/app_theme.dart';
import 'widgets/exercises_tab.dart';
import 'widgets/meals_tab.dart';

/// Unified Library page with tabs for Exercises and Meals
/// Replaces the old standalone ExercisesPage
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: const Text(AppStrings.libraryTitle),
          automaticallyImplyLeading: false, // No back button - it's a main tab
          bottom: TabBar(
            indicatorColor: AppTheme.primaryOrange,
            labelColor: AppTheme.primaryOrange,
            unselectedLabelColor: AppTheme.textDim,
            tabs: const [
              Tab(
                icon: Icon(Icons.fitness_center),
                text: AppStrings.exercisesTab,
              ),
              Tab(
                icon: Icon(Icons.restaurant),
                text: AppStrings.mealsTab,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showInfoDialog(context),
              tooltip: 'About Library',
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            ExercisesTab(),
            MealsTab(),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Library'),
        content: const Text(
          'Manage your workout exercises and meal library here.\n\n'
          'Exercises tab: Create custom exercises and assign them to muscle groups.\n\n'
          'Meals tab: Create meals with their nutritional information for quick logging.',
        ),
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