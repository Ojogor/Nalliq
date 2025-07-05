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
        title: Text(localizations.settings),
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[850] : AppColors.white,
        foregroundColor: isDark ? AppColors.white : AppColors.black,
      ),
      body: ListView(
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
            icon: Icons.location_on_outlined,
            title: localizations.manageLocation,
            onTap: () => context.push('/change-location'),
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
              // TODO: Implement help screen
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: localizations.aboutNalliq,
            onTap: () {
              // TODO: Implement about screen
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.gavel_outlined,
            title: localizations.termsAndConditions,
            onTap: () {
              // TODO: Implement terms and conditions screen
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
