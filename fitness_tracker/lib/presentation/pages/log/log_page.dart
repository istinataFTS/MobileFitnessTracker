import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/themes/app_theme.dart';
import 'widgets/log_exercise_tab.dart';
import 'widgets/log_meal_tab.dart';
import 'widgets/log_macros_tab.dart';
import '../../widgets/intensity_slider_widget.dart';

/// Redesigned Log page with three logging modes
/// Exercise | Meal | Macros
class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text(AppStrings.logTitle),
        automaticallyImplyLeading: false, // No back button - it's a main tab
      ),
      body: Column(
        children: [
          _buildSegmentedControl(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          _buildSegmentButton(
            index: 0,
            label: AppStrings.logExerciseTab,
            icon: Icons.fitness_center,
          ),
          _buildSegmentButton(
            index: 1,
            label: AppStrings.logMealTab,
            icon: Icons.restaurant,
          ),
          _buildSegmentButton(
            index: 2,
            label: AppStrings.logMacrosTab,
            icon: Icons.calculate,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.textDim,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textDim,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const LogExerciseTab();
      case 1:
        return const LogMealTab();
      case 2:
        return const LogMacrosTab();
      default:
        return const LogExerciseTab();
    }
  }
}