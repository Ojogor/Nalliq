import 'dart:io';
import 'dart:convert';

/// Script to generate config files from templates using secrets.json
Future<void> main() async {
  try {
    print('🔧 Generating config files from templates...');

    // Read secrets.json
    final secretsFile = File('assets/secrets.json');
    if (!secretsFile.existsSync()) {
      throw Exception('secrets.json not found at assets/secrets.json');
    }

    final secretsContent = await secretsFile.readAsString();
    final secrets = json.decode(secretsContent) as Map<String, dynamic>;

    final androidApiKey = secrets['android_api_key'] as String?;
    final googleMapsApiKey = secrets['google_map_api_key'] as String?;

    if (androidApiKey == null) {
      throw Exception('android_api_key not found in secrets.json');
    }
    if (googleMapsApiKey == null) {
      throw Exception('google_map_api_key not found in secrets.json');
    }

    // Generate google-services.json
    await _generateGoogleServices(androidApiKey);

    // Generate api_keys.json
    await _generateApiKeys(googleMapsApiKey);

    print('🎉 All config files generated successfully!');
  } catch (e) {
    print('❌ Error generating config files: $e');
    exit(1);
  }
}

Future<void> _generateGoogleServices(String androidApiKey) async {
  // Read template
  final templateFile = File('android/app/google-services.template.json');
  if (!templateFile.existsSync()) {
    throw Exception('google-services.template.json not found');
  }

  final templateContent = await templateFile.readAsString();

  // Replace placeholder with actual key
  final finalContent = templateContent.replaceAll(
    '{{ANDROID_API_KEY}}',
    androidApiKey,
  );

  // Write to actual google-services.json
  final outputFile = File('android/app/google-services.json');
  await outputFile.writeAsString(finalContent);

  print('✅ google-services.json generated successfully');
  print('🔑 Using Android API key: ${androidApiKey.substring(0, 10)}...');
}

Future<void> _generateApiKeys(String googleMapsApiKey) async {
  // Read template
  final templateFile = File('config/api_keys.template.json');
  if (!templateFile.existsSync()) {
    throw Exception('api_keys.template.json not found');
  }

  final templateContent = await templateFile.readAsString();

  // Replace placeholder with actual key
  final finalContent = templateContent.replaceAll(
    '{{GOOGLE_MAPS_API_KEY}}',
    googleMapsApiKey,
  );

  // Write to actual api_keys.json
  final outputFile = File('config/api_keys.json');
  await outputFile.writeAsString(finalContent);

  print('✅ config/api_keys.json generated successfully');
  print(
    '🔑 Using Google Maps API key: ${googleMapsApiKey.substring(0, 10)}...',
  );
}
