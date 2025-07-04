import 'package:go_router/go_router.dart';
import '../auth/screens/login_screen.dart';
import '../auth/screens/register_screen.dart';
import '../home/screens/home_screen.dart';
import '../home/screens/store_profile_screen.dart';
import '../items/screens/add_item_screen.dart';
import '../items/screens/item_detail_screen.dart';
import '../cart/screens/cart_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../profile/screens/my_listings_screen.dart';
import '../profile/screens/incoming_requests_screen.dart';
import '../profile/screens/outgoing_requests_screen.dart';
import '../profile/screens/friends_screen.dart';
import '../profile/screens/history_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../navigation/main_navigation.dart';
import '../debug/debug_screen.dart';

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
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
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

      // Profile sub-screens
      GoRoute(
        path: '/my-listings',
        name: 'my-listings',
        builder: (context, state) => const MyListingsScreen(),
      ),
      GoRoute(
        path: '/incoming-requests',
        name: 'incoming-requests',
        builder: (context, state) => const IncomingRequestsScreen(),
      ),
      GoRoute(
        path: '/outgoing-requests',
        name: 'outgoing-requests',
        builder: (context, state) => const OutgoingRequestsScreen(),
      ),
      GoRoute(
        path: '/friends',
        name: 'friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),

      // Store profile route
      GoRoute(
        path: '/store/:storeUserId',
        name: 'store-profile',
        builder: (context, state) {
          final storeUserId = state.pathParameters['storeUserId']!;
          return StoreProfileScreen(storeUserId: storeUserId);
        },
      ),

      // Debug route (only for development)
      GoRoute(
        path: '/debug',
        name: 'debug',
        builder: (context, state) => const DebugScreen(),
      ),
    ],
  );
}
