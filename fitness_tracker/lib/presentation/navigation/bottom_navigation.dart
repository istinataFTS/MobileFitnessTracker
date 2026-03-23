import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_strings.dart';
import '../../core/themes/app_theme.dart';
import '../../domain/entities/app_settings.dart';
import '../../features/history/history.dart';
import '../../features/home/home.dart';
import '../../features/library/application/exercise_bloc.dart';
import '../../features/library/application/meal_bloc.dart';
import '../../features/library/library.dart';
import '../../features/log/presentation/bloc/workout_bloc.dart';
import '../../features/log/presentation/pages/log_page.dart';
import '../../features/profile/profile.dart';
import '../../features/settings/application/app_settings_cubit.dart';
import '../pages/nutrition_log/bloc/nutrition_log_bloc.dart';
import '../pages/targets/bloc/targets_bloc.dart';
import '../pages/targets/targets_page.dart';

/// Bottom navigation wrapper for main app pages
class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  static const int _homeTabIndex = 0;
  static const int _logTabIndex = 1;
  static const int _historyTabIndex = 2;
  static const int _libraryTabIndex = 3;
  static const int _targetsTabIndex = 4;
  static const int _profileTabIndex = 5;
  static const int _tabCount = 6;

  int _selectedIndex = _homeTabIndex;

  final Set<int> _visitedTabs = <int>{_homeTabIndex};

  bool _didRequestExerciseData = false;
  bool _didRequestMealData = false;
  bool _didRequestNutritionLogData = false;
  bool _didRequestTargetsData = false;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      return;
    }

    _initializeTabIfNeeded(index);

    setState(() {
      _selectedIndex = index;
      _visitedTabs.add(index);
    });
  }

  void _initializeTabIfNeeded(int index) {
    final bool isFirstVisit = !_visitedTabs.contains(index);
    if (!isFirstVisit) {
      return;
    }

    switch (index) {
      case _logTabIndex:
        _ensureExerciseDataLoaded();
        _ensureMealDataLoaded();
        _ensureNutritionLogDataLoaded();
        break;
      case _historyTabIndex:
        break;
      case _libraryTabIndex:
        _ensureExerciseDataLoaded();
        _ensureMealDataLoaded();
        break;
      case _targetsTabIndex:
        _ensureTargetsDataLoaded();
        break;
      case _homeTabIndex:
      case _profileTabIndex:
        break;
    }
  }

  void _ensureExerciseDataLoaded() {
    if (_didRequestExerciseData) {
      return;
    }

    _didRequestExerciseData = true;
    context.read<ExerciseBloc>().add(LoadExercisesEvent());
  }

  void _ensureMealDataLoaded() {
    if (_didRequestMealData) {
      return;
    }

    _didRequestMealData = true;
    context.read<MealBloc>().add(LoadMealsEvent());
  }

  void _ensureNutritionLogDataLoaded() {
    if (_didRequestNutritionLogData) {
      return;
    }

    _didRequestNutritionLogData = true;
    context.read<NutritionLogBloc>().add(
          LoadDailyLogsEvent(DateTime.now()),
        );
  }

  void _ensureTargetsDataLoaded() {
    if (_didRequestTargetsData) {
      return;
    }

    _didRequestTargetsData = true;
    context.read<TargetsBloc>().add(LoadTargetsEvent());
  }

  Widget _buildPageForIndex(int index) {
    if (!_visitedTabs.contains(index)) {
      return const SizedBox.shrink();
    }

    switch (index) {
      case _homeTabIndex:
        return BlocSelector<AppSettingsCubit, AppSettingsState, AppSettings>(
          selector: (AppSettingsState state) => state.settings,
          builder: (BuildContext context, AppSettings settings) {
            return HomePage(settings: settings);
          },
        );
      case _logTabIndex:
        return const LogPage();
      case _historyTabIndex:
        return const HistoryPage();
      case _libraryTabIndex:
        return const LibraryPage();
      case _targetsTabIndex:
        return const TargetsPage();
      case _profileTabIndex:
        return const ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: List<Widget>.generate(
          _tabCount,
          _buildPageForIndex,
        ),
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
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surfaceDark,
          selectedItemColor: AppTheme.primaryOrange,
          unselectedItemColor: AppTheme.textDim,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          items: const <BottomNavigationBarItem>[
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
              icon: Icon(Icons.library_books_outlined, size: 22),
              activeIcon: Icon(Icons.library_books, size: 22),
              label: AppStrings.navLibrary,
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