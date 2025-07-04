import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart' as AppAuth;
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, AppAuth.AuthProvider>(
      builder: (context, settingsProvider, authProvider, child) {
        return Scaffold(
          backgroundColor:
              settingsProvider.darkModeEnabled
                  ? const Color(0xFF121212)
                  : AppColors.background,
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.white,
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Section
                  _buildSectionHeader('Account', settingsProvider),
                  _buildSettingsCard(settingsProvider, [
                    _buildSettingsItem(
                      icon: Icons.person,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      onTap: () {
                        // Navigate to edit profile
                      },
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.security,
                      title: 'Identity Verification',
                      subtitle: 'Verify your identity',
                      onTap: () {
                        _showComingSoonSnackBar(
                          context,
                          'Identity verification',
                        );
                      },
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.lock,
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      onTap: () {
                        _showComingSoonSnackBar(context, 'Password change');
                      },
                      settingsProvider: settingsProvider,
                    ),
                  ]),

                  const SizedBox(height: AppDimensions.marginL),

                  // Appearance Section
                  _buildSectionHeader('Appearance', settingsProvider),
                  _buildSettingsCard(settingsProvider, [
                    _buildSwitchItem(
                      icon: Icons.dark_mode,
                      title: 'Dark Mode',
                      subtitle: 'Use dark theme',
                      value: settingsProvider.darkModeEnabled,
                      onChanged: (value) => settingsProvider.toggleDarkMode(),
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: settingsProvider.selectedLanguage,
                      onTap:
                          () => _showLanguageDialog(context, settingsProvider),
                      settingsProvider: settingsProvider,
                    ),
                  ]),

                  const SizedBox(height: AppDimensions.marginL),

                  // Notifications Section
                  _buildSectionHeader('Notifications', settingsProvider),
                  _buildSettingsCard(settingsProvider, [
                    _buildSwitchItem(
                      icon: Icons.notifications,
                      title: 'Push Notifications',
                      subtitle: 'Receive push notifications',
                      value: settingsProvider.pushNotificationsEnabled,
                      onChanged:
                          (value) => settingsProvider.togglePushNotifications(),
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      icon: Icons.chat,
                      title: 'Chat Notifications',
                      subtitle: 'Get notified of new messages',
                      value: settingsProvider.chatNotificationsEnabled,
                      onChanged:
                          (value) => settingsProvider.toggleChatNotifications(),
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      icon: Icons.inventory,
                      title: 'Item Alerts',
                      subtitle: 'Notifications for new items',
                      value: settingsProvider.itemAlertsEnabled,
                      onChanged: (value) => settingsProvider.toggleItemAlerts(),
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      icon: Icons.swap_horiz,
                      title: 'Exchange Notifications',
                      subtitle: 'Updates on exchange requests',
                      value: settingsProvider.exchangeNotificationsEnabled,
                      onChanged:
                          (value) =>
                              settingsProvider.toggleExchangeNotifications(),
                      settingsProvider: settingsProvider,
                    ),
                  ]),

                  const SizedBox(height: AppDimensions.marginL),

                  // Privacy Section
                  _buildSectionHeader('Privacy', settingsProvider),
                  _buildSettingsCard(settingsProvider, [
                    _buildSwitchItem(
                      icon: Icons.visibility,
                      title: 'Show Online Status',
                      subtitle: 'Let others see when you\'re online',
                      value: settingsProvider.showOnlineStatus,
                      onChanged:
                          (value) => settingsProvider.toggleOnlineStatus(),
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      icon: Icons.person,
                      title: 'Profile Visibility',
                      subtitle: 'Make your profile visible to others',
                      value: settingsProvider.profileVisible,
                      onChanged:
                          (value) => settingsProvider.toggleProfileVisibility(),
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      icon: Icons.location_on,
                      title: 'Share Location',
                      subtitle: 'Show your location to other users',
                      value: settingsProvider.showLocationToOthers,
                      onChanged:
                          (value) => settingsProvider.toggleLocationSharing(),
                      settingsProvider: settingsProvider,
                    ),
                  ]),

                  const SizedBox(height: AppDimensions.marginL),

                  // Location Section
                  _buildSectionHeader('Location', settingsProvider),
                  _buildSettingsCard(settingsProvider, [
                    _buildSwitchItem(
                      icon: Icons.location_on,
                      title: 'Location Services',
                      subtitle: 'Enable location-based features',
                      value: settingsProvider.locationEnabled,
                      onChanged: (value) => settingsProvider.toggleLocation(),
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.radar,
                      title: 'Search Radius',
                      subtitle: '${settingsProvider.searchRadius.toInt()} km',
                      onTap:
                          () => _showSearchRadiusDialog(
                            context,
                            settingsProvider,
                          ),
                      settingsProvider: settingsProvider,
                    ),
                  ]),

                  const SizedBox(height: AppDimensions.marginL),

                  // Accessibility Section
                  _buildSectionHeader('Accessibility', settingsProvider),
                  _buildSettingsCard(settingsProvider, [
                    _buildSwitchItem(
                      icon: Icons.contrast,
                      title: 'High Contrast',
                      subtitle: 'Increase contrast for better visibility',
                      value: settingsProvider.highContrastEnabled,
                      onChanged:
                          (value) => settingsProvider.toggleHighContrast(),
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      icon: Icons.text_fields,
                      title: 'Large Text',
                      subtitle: 'Increase text size',
                      value: settingsProvider.largeTextEnabled,
                      onChanged: (value) => settingsProvider.toggleLargeText(),
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.format_size,
                      title: 'Text Scale',
                      subtitle:
                          '${(settingsProvider.textScaleFactor * 100).toInt()}%',
                      onTap:
                          () => _showTextScaleDialog(context, settingsProvider),
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      icon: Icons.record_voice_over,
                      title: 'Screen Reader',
                      subtitle: 'Enable voice assistance',
                      value: settingsProvider.screenReaderEnabled,
                      onChanged:
                          (value) => settingsProvider.toggleScreenReader(),
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      icon: Icons.motion_photos_off,
                      title: 'Reduced Motion',
                      subtitle: 'Minimize animations',
                      value: settingsProvider.reducedMotionEnabled,
                      onChanged:
                          (value) => settingsProvider.toggleReducedMotion(),
                      settingsProvider: settingsProvider,
                    ),
                  ]),

                  const SizedBox(height: AppDimensions.marginL),

                  // Sound Section
                  _buildSectionHeader('Sound', settingsProvider),
                  _buildSettingsCard(settingsProvider, [
                    _buildSwitchItem(
                      icon: Icons.volume_up,
                      title: 'Sound Effects',
                      subtitle: 'Enable app sounds',
                      value: settingsProvider.soundEnabled,
                      onChanged: (value) => settingsProvider.toggleSound(),
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      icon: Icons.vibration,
                      title: 'Vibration',
                      subtitle: 'Enable haptic feedback',
                      value: settingsProvider.vibrationEnabled,
                      onChanged: (value) => settingsProvider.toggleVibration(),
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.volume_down,
                      title: 'Sound Volume',
                      subtitle:
                          '${(settingsProvider.soundVolume * 100).toInt()}%',
                      onTap: () => _showVolumeDialog(context, settingsProvider),
                      settingsProvider: settingsProvider,
                    ),
                  ]),

                  const SizedBox(height: AppDimensions.marginL),

                  // Support Section
                  _buildSectionHeader('Support', settingsProvider),
                  _buildSettingsCard(settingsProvider, [
                    _buildSettingsItem(
                      icon: Icons.help,
                      title: 'Help Center',
                      subtitle: 'Get help and support',
                      onTap: () {
                        _showComingSoonSnackBar(context, 'Help center');
                      },
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.feedback,
                      title: 'Send Feedback',
                      subtitle: 'Share your thoughts with us',
                      onTap: () {
                        _showComingSoonSnackBar(context, 'Feedback');
                      },
                      settingsProvider: settingsProvider,
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.info,
                      title: 'About',
                      subtitle: 'App version and information',
                      onTap: () {
                        _showAboutDialog(context);
                      },
                      settingsProvider: settingsProvider,
                    ),
                  ]),

                  const SizedBox(height: AppDimensions.marginL),

                  // Debug Section (only in development)
                  _buildSectionHeader('Development', settingsProvider),
                  _buildSettingsCard(settingsProvider, [
                    _buildSettingsItem(
                      icon: Icons.bug_report,
                      title: 'Debug Panel',
                      subtitle: 'Developer tools and debugging',
                      onTap: () => context.goNamed('debug'),
                      settingsProvider: settingsProvider,
                    ),
                  ]),

                  const SizedBox(height: AppDimensions.marginL),

                  // Logout Section
                  _buildSettingsCard(settingsProvider, [
                    _buildSettingsItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      textColor: AppColors.error,
                      iconColor: AppColors.error,
                      onTap: () => _handleLogout(context, authProvider),
                      settingsProvider: settingsProvider,
                    ),
                  ]),

                  const SizedBox(height: AppDimensions.marginXL),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, SettingsProvider settingsProvider) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.paddingS,
        bottom: AppDimensions.marginS,
        top: AppDimensions.marginS,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color:
              settingsProvider.darkModeEnabled
                  ? Colors.grey[400]
                  : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    SettingsProvider settingsProvider,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        color:
            settingsProvider.darkModeEnabled
                ? const Color(0xFF1E1E1E)
                : AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color:
                settingsProvider.darkModeEnabled
                    ? Colors.black.withOpacity(0.3)
                    : AppColors.grey.withOpacity(0.1),
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
    required SettingsProvider settingsProvider,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color:
            iconColor ??
            (settingsProvider.darkModeEnabled
                ? Colors.grey[400]
                : AppColors.textSecondary),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color:
              textColor ??
              (settingsProvider.darkModeEnabled
                  ? Colors.white
                  : AppColors.textPrimary),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color:
              settingsProvider.darkModeEnabled
                  ? Colors.grey[400]
                  : AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color:
            settingsProvider.darkModeEnabled
                ? Colors.grey[400]
                : AppColors.grey,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required SettingsProvider settingsProvider,
  }) {
    return SwitchListTile(
      secondary: Icon(
        icon,
        color:
            settingsProvider.darkModeEnabled
                ? Colors.grey[400]
                : AppColors.textSecondary,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color:
              settingsProvider.darkModeEnabled
                  ? Colors.white
                  : AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color:
              settingsProvider.darkModeEnabled
                  ? Colors.grey[400]
                  : AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryGreen,
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

  void _showLanguageDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Choose Language'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  settingsProvider.getAvailableLanguages().map((language) {
                    return RadioListTile<String>(
                      title: Text(language['nativeName']!),
                      value: language['name']!,
                      groupValue: settingsProvider.selectedLanguage,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.updateLanguage(value);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Language changed to $value'),
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }

  void _showSearchRadiusDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Search Radius'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  [5.0, 10.0, 25.0, 50.0, 100.0].map((radius) {
                    return RadioListTile<double>(
                      title: Text('${radius.toInt()} km'),
                      value: radius,
                      groupValue: settingsProvider.searchRadius,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.updateSearchRadius(value);
                          Navigator.pop(context);
                        }
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }

  void _showTextScaleDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Text Scale'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  [0.85, 1.0, 1.15, 1.3, 1.5].map((scale) {
                    return RadioListTile<double>(
                      title: Text('${(scale * 100).toInt()}%'),
                      value: scale,
                      groupValue: settingsProvider.textScaleFactor,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.updateTextScale(value);
                          Navigator.pop(context);
                        }
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }

  void _showVolumeDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sound Volume'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  [0.0, 0.25, 0.5, 0.75, 1.0].map((volume) {
                    return RadioListTile<double>(
                      title: Text('${(volume * 100).toInt()}%'),
                      value: volume,
                      groupValue: settingsProvider.soundVolume,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.updateSoundVolume(value);
                          Navigator.pop(context);
                        }
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }

  void _showComingSoonSnackBar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppColors.primaryGreen,
      ),
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
