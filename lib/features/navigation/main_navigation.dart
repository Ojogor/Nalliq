import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/user_model.dart';
import '../../features/auth/providers/auth_provider.dart';

class MainNavigation extends StatelessWidget {
  final Widget child;

  const MainNavigation({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isFoodBank = authProvider.appUser?.role == UserRole.foodBank;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF2D2D30) : AppColors.surface,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: isDark ? Colors.white54 : AppColors.grey,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: AppStrings.profile,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton:
          isFoodBank
              ? FloatingActionButton(
                onPressed: () => context.pushNamed('enhanced-add-item'),
                backgroundColor: AppColors.primaryOrange,
                child: const Icon(Icons.add, color: AppColors.white),
                tooltip: 'Add Food Listing',
              )
              : null,
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) {
      return 0;
    }
    if (location.startsWith('/profile')) {
      return 1;
    }
    if (location.startsWith('/settings')) {
      return 2;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed('home');
        break;
      case 1:
        context.goNamed('profile');
        break;
      case 2:
        context.goNamed('settings');
        break;
    }
  }
}
