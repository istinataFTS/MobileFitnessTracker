import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../pages/home/home_page.dart';
import '../pages/log_set/log_set_page.dart';
import '../pages/history/history_page.dart';
import '../pages/exercises/exercises_page.dart';
import '../pages/targets/targets_page.dart';
import '../pages/profile/profile_page.dart';

/// Main navigation with 6 equal tabs - clean and predictable
/// All major features accessible with one tap
class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _currentIndex = 0;

  // All 6 pages - each equally important and directly accessible
  final List<Widget> _pages = const [
    HomePage(),      // 1. Dashboard with weekly progress overview
    LogSetPage(),    // 2. Main logging interface for workouts
    HistoryPage(),   // 3. Past workout history and filtering
    ExercisesPage(), // 4. Exercise library management
    TargetsPage(),   // 5. Muscle group target setting
    ProfilePage(),   // 6. Personal stats and settings
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.borderDark,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surfaceDark,
          selectedItemColor: AppTheme.primaryOrange,
          unselectedItemColor: AppTheme.textDim,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          // Reduced icon size slightly to fit 6 tabs comfortably
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 22),
              activeIcon: Icon(Icons.home, size: 22),
              label: AppStrings.navHome,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline, size: 22),
              activeIcon: Icon(Icons.add_circle, size: 22),
              label: AppStrings.navLog,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined, size: 22),
              activeIcon: Icon(Icons.history, size: 22),
              label: AppStrings.navHistory,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined, size: 22),
              activeIcon: Icon(Icons.fitness_center, size: 22),
              label: AppStrings.navExercises,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flag_outlined, size: 22),
              activeIcon: Icon(Icons.flag, size: 22),
              label: AppStrings.navTargets,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 22),
              activeIcon: Icon(Icons.person, size: 22),
              label: AppStrings.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}