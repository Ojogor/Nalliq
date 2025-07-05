import 'package:flutter/material.dart';
import 'package:nalliq/core/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:nalliq/features/settings/providers/settings_provider.dart';

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localizations.accessibility)),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              SwitchListTile(
                title: Text(localizations.highContrastMode),
                subtitle: Text(localizations.highContrastModeDescription),
                value: settings.highContrastEnabled,
                onChanged: (bool value) {
                  settings.updateHighContrast(value);
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  localizations.textSize,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Slider(
                value: settings.textScaleFactor,
                min: 0.8,
                max: 2.0,
                divisions: 12,
                label: settings.textScaleFactor.toStringAsFixed(1),
                onChanged: (double value) {
                  settings.updateTextScaleFactor(value);
                },
              ),
              ListTile(
                title: Text(localizations.reducedMotion),
                subtitle: Text(localizations.reducedMotionDescription),
                trailing: Switch(
                  value: settings.reducedMotionEnabled,
                  onChanged: (bool value) {
                    settings.updateReducedMotion(value);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
