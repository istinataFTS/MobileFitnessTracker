import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/themes/app_theme.dart';
import '../pages/home/home_page.dart';
import '../pages/log_set/log_set_page.dart';
import '../pages/history/history_page.dart';
import '../pages/library/library_page.dart';
import '../pages/targets/targets_page.dart';
import '../pages/profile/profile_page.dart';

/// Bottom navigation wrapper for main app pages
class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const LogSetPage(),
    const HistoryPage(),
    const LibraryPage(), 
    const TargetsPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
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
              icon: Icon(Icons.library_books_outlined, size: 22),
              activeIcon: Icon(Icons.library_books, size: 22),
              label: AppStrings.navLibrary, // Changed from navExercises
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