import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// Shell avec bottom nav 4 onglets : Accueil / Coran / Parcours / Profil.
class StudentShellScreen extends StatelessWidget {
  final Widget child;

  const StudentShellScreen({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/student/quran')) return 1;
    if (location.startsWith('/student/curriculum')) return 2;
    if (location.startsWith('/student/hifz-v2')) return 2;
    if (location.startsWith('/student/profile')) return 3;
    if (location.startsWith('/student/settings')) return 3;
    if (location.startsWith('/student/progress')) return 3;
    if (location.startsWith('/student/agenda')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/student');
            case 1: context.go('/student/quran');
            case 2: context.go('/student/curriculum');
            case 3: context.go('/student/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories_outlined),
            activeIcon: Icon(Icons.auto_stories),
            label: 'Coran',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Parcours',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
