import 'dart:convert';

import 'package:flutter/services.dart';

class Secret {
  final String webApiKey;
  final String androidApiKey;
  final String iosApiKey;
  final String googleMapApiKey;

  Secret({
    required this.webApiKey,
    required this.androidApiKey,
    required this.iosApiKey,
    required this.googleMapApiKey,
  });

  factory Secret.fromJson(Map<String, dynamic> json) {
    return Secret(
      webApiKey: json['web_api_key'],
      androidApiKey: json['android_api_key'],
      iosApiKey: json['ios_api_key'],
      googleMapApiKey: json['google_map_api_key'],
    );
  }
}

class SecretService {
  static Future<Secret> load() async {
    try {
      print('Attempting to load secrets from assets/secrets.json');
      final String jsonString = await rootBundle.loadString(
        'assets/secrets.json',
      );
      print('JSON loaded: ${jsonString.length} characters');

      final jsonResponse = json.decode(jsonString);
      print('JSON parsed successfully');

      final secret = Secret.fromJson(jsonResponse);
      print('Secret object created successfully');

      return secret;
    } catch (e) {
      print('Error loading secrets: $e');
      rethrow;
    }
  }
}
