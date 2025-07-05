import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/screens/login_screen.dart';
import '../auth/screens/register_screen.dart';
import '../auth/screens/terms_and_conditions_screen.dart';
import '../auth/screens/privacy_policy_screen.dart';
import '../home/screens/home_screen.dart';
import '../home/screens/store_profile_screen.dart';
import '../home/screens/store_list_screen.dart';
import '../items/screens/add_item_screen.dart';
import '../items/screens/enhanced_add_item_screen.dart';
import '../items/screens/item_detail_screen.dart';
import '../cart/screens/cart_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../profile/screens/edit_profile_screen.dart';
import '../profile/screens/my_listings_screen.dart';
import '../profile/screens/incoming_requests_screen.dart';
import '../profile/screens/outgoing_requests_screen.dart';
import '../profile/screens/friends_screen.dart';
import '../profile/screens/history_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../settings/screens/accessibility_settings_screen.dart';
import '../settings/screens/language_settings_screen.dart';
import '../settings/screens/help_support_screen.dart';
import '../settings/screens/about_nalliq_screen.dart';
import '../exchange/screens/barter_detail_screen.dart';
import '../navigation/main_navigation.dart';
import '../debug/debug_screen.dart';
import '../search/screens/search_screen.dart';
import '../profile/screens/manage_location_screen.dart';
import '../location/screens/enhanced_change_location_screen.dart';
import '../map/screens/new_map_screen.dart' as new_map;
import '../profile/screens/improve_trust_score_screen.dart';
import '../trust/screens/trust_score_screen.dart';
import '../trust/screens/id_verification_screen.dart';
import '../trust/screens/certifications_screen.dart';
import '../../core/services/route_guard_service.dart';
import '../auth/providers/auth_provider.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'nalliq_root_nav');
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'nalliq_shell_nav');

  static AuthProvider? _authProvider;

  static void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = _authProvider?.isAuthenticated ?? false;
      final user = _authProvider?.appUser;
      final currentLocation = state.uri.toString();

      // Allow unauthenticated users to access auth routes
      if (!isLoggedIn) {
        if (currentLocation.startsWith('/login') ||
            currentLocation.startsWith('/register')) {
          return null; // Allow access
        }
        return '/login'; // Redirect to login
      }

      // For authenticated users, check if they can access the route
      if (isLoggedIn && user != null) {
        // If trying to access login/register while authenticated, redirect to next step or home
        if (currentLocation.startsWith('/login') ||
            currentLocation.startsWith('/register')) {
          final nextStep = RouteGuardService.getNextRequiredStep(user);
          return nextStep ?? '/home';
        }

        // Check if user can access the current route
        if (!RouteGuardService.canAccessRoute(currentLocation, user)) {
          final nextStep = RouteGuardService.getNextRequiredStep(user);
          if (nextStep != null) {
            return nextStep;
          }
        }
      }

      return null; // No redirect needed
    },
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Page not found: ${state.uri}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Go to Home'),
                ),
              ],
            ),
          ),
        ),
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

      // Terms and Privacy routes
      GoRoute(
        path: '/terms-and-conditions',
        name: 'terms-and-conditions',
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),

      // Main navigation with bottom nav bar
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainNavigation(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
            routes: [
              // Child routes of /home, they will be displayed within the shell
              GoRoute(
                path: 'stores/:type',
                name: 'stores',
                builder: (context, state) {
                  final typeString = state.pathParameters['type']!;
                  final type = StoreListType.values.firstWhere(
                    (e) => e.name == typeString,
                    orElse: () => StoreListType.community,
                  );
                  return StoreListScreen(storeType: type);
                },
              ),
              GoRoute(
                path: 'store/:storeUserId',
                name: 'store-profile',
                builder: (context, state) {
                  final storeUserId = state.pathParameters['storeUserId']!;
                  return StoreProfileScreen(storeUserId: storeUserId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/cart',
            name: 'cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/add-item',
            name: 'add-item',
            builder: (context, state) => const AddItemScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'edit-profile',
                builder: (context, state) => const EditProfileScreen(),
              ),
              GoRoute(
                path: 'listings',
                name: 'profile-listings',
                builder: (context, state) => const MyListingsScreen(),
              ),
              GoRoute(
                path: 'incoming-requests',
                name: 'incoming-requests',
                builder: (context, state) => const IncomingRequestsScreen(),
              ),
              GoRoute(
                path: 'outgoing-requests',
                name: 'outgoing-requests',
                builder: (context, state) => const OutgoingRequestsScreen(),
              ),
              GoRoute(
                path: 'friends',
                name: 'friends',
                builder: (context, state) => const FriendsScreen(),
              ),
              GoRoute(
                path: 'history',
                name: 'history',
                builder: (context, state) => const HistoryScreen(),
              ),
              GoRoute(
                path: 'improve-trust-score',
                name: 'improve-trust-score',
                builder: (context, state) => const ImproveTrustScoreScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'accessibility',
                name: 'accessibility-settings',
                builder:
                    (context, state) => const AccessibilitySettingsScreen(),
              ),
              GoRoute(
                path: 'language',
                name: 'language-settings',
                builder: (context, state) => const LanguageSettingsScreen(),
              ),
              GoRoute(
                path: 'help-support',
                name: 'help-support',
                builder: (context, state) => const HelpSupportScreen(),
              ),
              GoRoute(
                path: 'about-nalliq',
                name: 'about-nalliq',
                builder: (context, state) => const AboutNalliqScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/maps',
            name: 'maps',
            builder: (context, state) => const new_map.MapScreen(),
          ),
          GoRoute(
            path: '/change-location',
            name: 'change-location',
            builder: (context, state) => const ManageLocationScreen(),
          ),
          GoRoute(
            path: '/enhanced-change-location',
            name: 'enhanced-change-location',
            builder: (context, state) => const EnhancedChangeLocationScreen(),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const SearchScreen(),
          ),
        ],
      ),

      // Non-shelled routes
      GoRoute(
        path: '/item/:itemId',
        name: 'item-detail',
        builder: (context, state) {
          final itemId = state.pathParameters['itemId']!;
          return ItemDetailScreen(itemId: itemId);
        },
      ),
      GoRoute(
        path: '/language-settings',
        name: 'language-settings-standalone',
        builder: (context, state) => const LanguageSettingsScreen(),
      ),
      GoRoute(
        path: '/accessibility-settings',
        name: 'accessibility-settings-standalone',
        builder: (context, state) => const AccessibilitySettingsScreen(),
      ),
      GoRoute(
        path: '/add-item-enhanced',
        name: 'enhanced-add-item',
        builder: (context, state) => const EnhancedAddItemScreen(),
      ),
      GoRoute(
        path: '/my-listings',
        name: 'my-listings',
        builder: (context, state) => const MyListingsScreen(),
      ),
      GoRoute(
        path: '/trust-score',
        name: 'trust-score',
        builder: (context, state) => const TrustScoreScreen(),
      ),
      GoRoute(
        path: '/id-verification',
        name: 'id-verification',
        builder: (context, state) => const IDVerificationScreen(),
      ),
      GoRoute(
        path: '/certifications',
        name: 'certifications',
        builder: (context, state) => const CertificationsScreen(),
      ),
      GoRoute(
        path: '/barter-detail/:requestId',
        name: 'barter-detail',
        builder: (context, state) {
          final requestId = state.pathParameters['requestId']!;
          return BarterDetailScreen(requestId: requestId);
        },
      ),
      GoRoute(
        path: '/debug',
        name: 'debug',
        builder: (context, state) => const DebugScreen(),
      ),
    ],
  );
}
