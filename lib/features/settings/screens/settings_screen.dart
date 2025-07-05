import 'package:nalliq/core/localization/app_localizations.dart';
import 'package:nalliq/features/settings/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:nalliq/core/constants/app_colors.dart';
import 'package:nalliq/features/auth/providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDark = settingsProvider.darkTheme;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[850] : AppColors.white,
        foregroundColor: isDark ? AppColors.white : AppColors.black,
      ),
      body: Column(
        children: [
          // Top banner with "Settings" title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 0,
              bottom: 20.0,
              left: 16.0,
              right: 16.0,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGreen,
                  AppColors.primaryGreen.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your account and preferences',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Settings content
          Expanded(
            child: ListView(
              children: [
                _buildSectionTitle(context, localizations.account),
                _buildSettingsTile(
                  context,
                  icon: Icons.lock_outline,
                  title: localizations.changePassword,
                  onTap: () {
                    context.pushNamed('change-password');
                  },
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.shield_outlined,
                  title: localizations.privacy,
                  onTap: () {
                    // TODO: Implement privacy screen
                  },
                ),
                const Divider(),
                _buildSectionTitle(context, localizations.appearance),
                SwitchListTile(
                  title: Text(localizations.darkMode),
                  value: settingsProvider.darkTheme,
                  onChanged: (value) {
                    settingsProvider.toggleDarkMode();
                  },
                  secondary: Icon(
                    settingsProvider.darkTheme
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                  ),
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.accessibility_new_outlined,
                  title: localizations.accessibility,
                  onTap: () {
                    context.go('/settings/accessibility');
                  },
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.language_outlined,
                  title: localizations.language,
                  onTap: () {
                    context.go('/settings/language');
                  },
                ),
                const Divider(),
                _buildSectionTitle(context, localizations.support),
                _buildSettingsTile(
                  context,
                  icon: Icons.help_outline,
                  title: localizations.helpAndSupport,
                  onTap: () {
                    context.pushNamed('help-support');
                  },
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.info_outline,
                  title: localizations.aboutNalliq,
                  onTap: () {
                    context.pushNamed('about-nalliq');
                  },
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.gavel_outlined,
                  title: localizations.termsAndConditions,
                  onTap: () {
                    context.pushNamed('terms-and-conditions');
                  },
                ),
                const Divider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.logout,
                  title: localizations.logout,
                  onTap: () async {
                    await authProvider.signOut();
                    context.go('/login');
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor = color ?? (isDark ? AppColors.white : AppColors.black);

    return ListTile(
      leading: Icon(icon, color: tileColor),
      title: Text(title, style: TextStyle(color: tileColor)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
