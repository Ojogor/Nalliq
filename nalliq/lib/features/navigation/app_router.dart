import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/screens/login_screen.dart';
import '../auth/screens/register_screen.dart';
import '../home/screens/home_screen.dart';
import '../items/screens/add_item_screen.dart';
import '../items/screens/item_detail_screen.dart';
import '../cart/screens/cart_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../navigation/main_navigation.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main navigation with bottom nav bar
      ShellRoute(
        builder: (context, state, child) => MainNavigation(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/cart',
            name: 'cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Item management routes
      GoRoute(
        path: '/add-item',
        name: 'add-item',
        builder: (context, state) => const AddItemScreen(),
      ),
      GoRoute(
        path: '/item/:itemId',
        name: 'item-detail',
        builder: (context, state) {
          final itemId = state.pathParameters['itemId']!;
          return ItemDetailScreen(itemId: itemId);
        },
      ),
    ],
  );
}
