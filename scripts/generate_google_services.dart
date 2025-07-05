import 'dart:io';
import 'dart:convert';

/// Script to generate google-services.json from template using secrets.json
Future<void> main() async {
  try {
    print('🔧 Generating google-services.json from template...');

    // Read secrets.json
    final secretsFile = File('assets/secrets.json');
    if (!secretsFile.existsSync()) {
      throw Exception('secrets.json not found at assets/secrets.json');
    }

    final secretsContent = await secretsFile.readAsString();
    final secrets = json.decode(secretsContent) as Map<String, dynamic>;
    final androidApiKey = secrets['android_api_key'] as String?;

    if (androidApiKey == null) {
      throw Exception('android_api_key not found in secrets.json');
    }

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
  } catch (e) {
    print('❌ Error generating google-services.json: $e');
    exit(1);
  }
}
