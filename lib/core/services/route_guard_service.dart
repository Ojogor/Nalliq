import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';

class RouteGuardService {
  /// Check if user has completed all mandatory onboarding steps
  static bool hasCompletedMandatorySteps(AppUser? user) {
    if (user == null) return false;

    // Only terms and conditions are mandatory for registration
    return user.termsAccepted;
  }

  /// Get the next required onboarding step
  static String? getNextRequiredStep(AppUser? user) {
    if (user == null) return null;

    if (!user.termsAccepted) {
      return '/terms-and-conditions';
    }

    // ID verification and certifications are optional for trust score points
    return null;
  }

  /// Redirect user to next required step if needed
  static void enforceOnboarding(BuildContext context, AppUser? user) {
    if (hasCompletedMandatorySteps(user)) return;

    final nextStep = getNextRequiredStep(user);
    if (nextStep != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(nextStep);
      });
    }
  }

  /// Check if route is protected and user can access it
  static bool canAccessRoute(String route, AppUser? user) {
    // Allow access to auth routes and mandatory onboarding routes
    if (_isPublicRoute(route)) return true;

    // Check if user has completed mandatory steps for protected routes
    return hasCompletedMandatorySteps(user);
  }

  /// Check if a route is public (doesn't require onboarding completion)
  static bool _isPublicRoute(String route) {
    const publicRoutes = [
      '/login',
      '/register',
      '/terms-and-conditions',
      '/privacy-policy',
      '/id-verification',
      '/certifications',
    ];

    return publicRoutes.any((publicRoute) => route.startsWith(publicRoute));
  }
}
