import 'dart:convert';
import 'package:flutter/services.dart';

class ConfigService {
  static Map<String, dynamic>? _config;

  static Future<void> loadConfig() async {
    try {
      final String configString = await rootBundle.loadString(
        'config/api_keys.json',
      );
      _config = json.decode(configString);
    } catch (e) {
      print('Error loading config: $e');
      _config = {};
    }
  }

  static String? get googleMapsApiKey {
    return _config?['google_maps_api_key'];
  }

  static bool get isConfigLoaded => _config != null;
}
