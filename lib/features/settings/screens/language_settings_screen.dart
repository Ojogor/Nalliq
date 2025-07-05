import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nalliq/features/settings/providers/settings_provider.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              RadioListTile<String>(
                title: const Text('English'),
                value: 'English',
                groupValue: settings.selectedLanguage,
                onChanged: (String? value) {
                  if (value != null) {
                    settings.updateLanguage(value);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('French'),
                value: 'French',
                groupValue: settings.selectedLanguage,
                onChanged: (String? value) {
                  if (value != null) {
                    settings.updateLanguage(value);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Spanish'),
                value: 'Spanish',
                groupValue: settings.selectedLanguage,
                onChanged: (String? value) {
                  if (value != null) {
                    settings.updateLanguage(value);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
