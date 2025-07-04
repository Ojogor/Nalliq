import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart' as AppAuth;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Consumer<AppAuth.AuthProvider>(
          builder: (context, authProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Section
                  _buildSectionHeader('Account'),
                  _buildSettingsCard([
                    _buildSettingsItem(
                      icon: Icons.person,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      onTap: () {
                        // Navigate to edit profile
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.security,
                      title: 'Privacy & Security',
                      subtitle: 'Manage your privacy settings',
                      onTap: () {
                        // Navigate to privacy settings
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.shopping_cart,
                      title: 'Cart',
                      subtitle: 'View and manage your cart items',
                      onTap: () => context.goNamed('cart'),
                    ),
                  ]),

                  const SizedBox(height: AppDimensions.marginL),

                  // Preferences Section
                  _buildSectionHeader('Preferences'),
                  _buildSettingsCard([
                    _buildSettingsItem(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      subtitle: 'Manage notification preferences',
                      onTap: () {
                        // Navigate to notification settings
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.location_on,
                      title: 'Location',
                      subtitle: 'Update your location settings',
                      onTap: () {
                        // Navigate to location settings
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: 'Choose your preferred language',
                      onTap: () {
                        // Navigate to language settings
                      },
                    ),
                  ]),

                  const SizedBox(height: AppDimensions.marginL),

                  // Support Section
                  _buildSectionHeader('Support'),
                  _buildSettingsCard([
                    _buildSettingsItem(
                      icon: Icons.help,
                      title: 'Help Center',
                      subtitle: 'Get help and support',
                      onTap: () {
                        // Navigate to help center
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.feedback,
                      title: 'Send Feedback',
                      subtitle: 'Share your thoughts with us',
                      onTap: () {
                        // Navigate to feedback
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.info,
                      title: 'About',
                      subtitle: 'App version and information',
                      onTap: () {
                        // Show about dialog
                        _showAboutDialog(context);
                      },
                    ),
                  ]),

                  const SizedBox(height: AppDimensions.marginL),

                  // Debug Section (only in development)
                  _buildSectionHeader('Development'),
                  _buildSettingsCard([
                    _buildSettingsItem(
                      icon: Icons.bug_report,
                      title: 'Debug Panel',
                      subtitle: 'Developer tools and debugging',
                      onTap: () => context.goNamed('debug'),
                    ),
                  ]),

                  const SizedBox(height: AppDimensions.marginL),

                  // Logout Section
                  _buildSettingsCard([
                    _buildSettingsItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      textColor: AppColors.error,
                      iconColor: AppColors.error,
                      onTap: () => _handleLogout(context, authProvider),
                    ),
                  ]),

                  const SizedBox(height: AppDimensions.marginXL),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.paddingS,
        bottom: AppDimensions.marginS,
        top: AppDimensions.marginS,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.textSecondary,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.grey,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: AppColors.grey.withOpacity(0.2),
      indent: 56,
      endIndent: 16,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Nalliq',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.restaurant,
        size: 48,
        color: AppColors.primaryGreen,
      ),
      children: [
        const Text(
          'A community food sharing platform that connects neighbors to reduce food waste and build stronger communities.',
        ),
      ],
    );
  }

  void _handleLogout(BuildContext context, AppAuth.AuthProvider authProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  authProvider.signOut();
                  context.goNamed('login');
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }
}
