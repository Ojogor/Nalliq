import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Secure Firebase configuration loader that reads from JSON file
///
/// This class loads Firebase configuration from a JSON file that should be
/// excluded from version control for security.
class SecureFirebaseOptions {
  static Map<String, dynamic>? _config;

  /// Load configuration from JSON file
  static Future<void> _loadConfig() async {
    if (_config != null) return; // Already loaded

    try {
      // Load from assets for all platforms
      final configString = await rootBundle.loadString(
        'config/firebase_config.json',
      );

      _config = json.decode(configString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception(
        'Failed to load Firebase configuration: $e\n'
        'Make sure config/firebase_config.json exists and is properly formatted.\n'
        'Copy firebase_config.template.json to firebase_config.json and fill in your credentials.',
      );
    }
  }

  /// Get Firebase options for current platform
  static Future<FirebaseOptions> get currentPlatform async {
    await _loadConfig();

    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web {
    final config = _config!['web'] as Map<String, dynamic>;
    return FirebaseOptions(
      apiKey: config['apiKey'] as String,
      appId: config['appId'] as String,
      messagingSenderId: config['messagingSenderId'] as String,
      projectId: config['projectId'] as String,
      authDomain: config['authDomain'] as String,
      storageBucket: config['storageBucket'] as String,
      measurementId: config['measurementId'] as String?,
    );
  }

  static FirebaseOptions get android {
    final config = _config!['android'] as Map<String, dynamic>;
    return FirebaseOptions(
      apiKey: config['apiKey'] as String,
      appId: config['appId'] as String,
      messagingSenderId: config['messagingSenderId'] as String,
      projectId: config['projectId'] as String,
      storageBucket: config['storageBucket'] as String,
    );
  }

  static FirebaseOptions get ios {
    final config = _config!['ios'] as Map<String, dynamic>;
    return FirebaseOptions(
      apiKey: config['apiKey'] as String,
      appId: config['appId'] as String,
      messagingSenderId: config['messagingSenderId'] as String,
      projectId: config['projectId'] as String,
      storageBucket: config['storageBucket'] as String,
      iosBundleId: config['iosBundleId'] as String,
    );
  }

  static FirebaseOptions get macos {
    final config = _config!['macos'] as Map<String, dynamic>;
    return FirebaseOptions(
      apiKey: config['apiKey'] as String,
      appId: config['appId'] as String,
      messagingSenderId: config['messagingSenderId'] as String,
      projectId: config['projectId'] as String,
      storageBucket: config['storageBucket'] as String,
      iosBundleId: config['iosBundleId'] as String,
    );
  }

  static FirebaseOptions get windows {
    final config = _config!['windows'] as Map<String, dynamic>;
    return FirebaseOptions(
      apiKey: config['apiKey'] as String,
      appId: config['appId'] as String,
      messagingSenderId: config['messagingSenderId'] as String,
      projectId: config['projectId'] as String,
      authDomain: config['authDomain'] as String,
      storageBucket: config['storageBucket'] as String,
      measurementId: config['measurementId'] as String?,
    );
  }
}
