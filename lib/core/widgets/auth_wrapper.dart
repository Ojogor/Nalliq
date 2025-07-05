import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/moderation_service.dart';
import '../widgets/ban_screen.dart';

/// Authentication wrapper that checks for banned users
class AuthWrapper extends StatelessWidget {
  final AppUser? user;
  final Widget authenticatedChild;
  final Widget unauthenticatedChild;

  const AuthWrapper({
    super.key,
    required this.user,
    required this.authenticatedChild,
    required this.unauthenticatedChild,
  });

  @override
  Widget build(BuildContext context) {
    // If no user, show unauthenticated screen
    if (user == null) {
      return unauthenticatedChild;
    }

    // Check if user should be banned
    if (ModerationService.shouldShowBanScreen(user!)) {
      return BanScreen(user: user!);
    }

    // User is authenticated and not banned
    return authenticatedChild;
  }
}

/// Example usage in your main app structure:
///
/// ```dart
/// StreamBuilder<AppUser?>(
///   stream: authService.userStream,
///   builder: (context, snapshot) {
///     return AuthWrapper(
///       user: snapshot.data,
///       authenticatedChild: MainAppScreen(user: snapshot.data!),
///       unauthenticatedChild: LoginScreen(),
///     );
///   },
/// )
/// ```
