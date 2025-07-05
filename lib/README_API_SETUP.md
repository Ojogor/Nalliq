# README for the Instructions to Setup Passwords

This document provides step-by-step instructions for setting up API keys required for the Nalliq application.

## Required API Keys

The application requires the following API keys from Google Cloud Platform:

1. **Web API Key** - For web platform Firebase services
2. **Android API Key** - For Android platform Firebase services  
3. **iOS API Key** - For iOS platform Firebase services
4. **Google Maps API Key** - For Maps functionality and Google Places autocomplete

## Setup Instructions

### 1. Google Cloud Platform Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the required APIs:
   - Firebase API
   - Google Maps JavaScript API
   - Google Maps Android API
   - Google Maps iOS API
   - Places API (for address autocomplete)
   - Geocoding API

### 2. Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new Firebase project or use existing one
3. Add your Flutter app to the project:
   - Click "Add app" and select Flutter
   - Follow the setup wizard for each platform (Web, Android, iOS)
4. Download the configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
   - Firebase config for Web

### 3. Generate API Keys

#### Web API Key:
1. In Google Cloud Console, go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "API Key"
3. Restrict the key to "HTTP referrers" and add your domain
4. Enable: Firebase API, Maps JavaScript API, Places API

#### Android API Key:
1. Create another API key in Google Cloud Console
2. Restrict to "Android apps"
3. Add your app's package name and SHA-1 fingerprint
4. Enable: Firebase API, Maps Android API, Places API

#### iOS API Key:
1. Create another API key in Google Cloud Console
2. Restrict to "iOS apps"
3. Add your app's bundle identifier
4. Enable: Firebase API, Maps iOS API, Places API

#### Google Maps API Key:
1. Create a separate API key for Maps functionality
2. Restrict appropriately based on your platform
3. Enable: Maps JavaScript API, Maps Android API, Maps iOS API, Places API, Geocoding API

### 4. Configure secrets.json

1. Navigate to `assets/secrets.json` in your project
2. Replace the placeholder values with your actual API keys:

```json
{
  "web_api_key": "YOUR_WEB_API_KEY_HERE",
  "android_api_key": "YOUR_ANDROID_API_KEY_HERE", 
  "ios_api_key": "YOUR_IOS_API_KEY_HERE",
  "google_map_api_key": "YOUR_GOOGLE_MAPS_API_KEY_HERE"
}
```

### 5. Security Best Practices

1. **Never commit API keys to version control**
   - Add `assets/secrets.json` to your `.gitignore` file
   - Use environment variables in production

2. **Restrict API keys properly**
   - Set application restrictions (HTTP referrers, Android apps, iOS apps)
   - Set API restrictions to only needed services
   - Monitor usage in Google Cloud Console

3. **Use different keys for different environments**
   - Development keys with restricted quotas
   - Production keys with proper monitoring

### 6. Platform-Specific Configuration

#### Android:
1. Place `google-services.json` in `android/app/`
2. Add Google Services plugin to `android/build.gradle`
3. Configure Maps API key in `android/app/src/main/AndroidManifest.xml`

#### iOS:
1. Place `GoogleService-Info.plist` in `ios/Runner/`
2. Configure Maps API key in `ios/Runner/AppDelegate.swift`

#### Web:
1. Add Firebase config to `web/index.html`
2. Configure Maps API key in web configuration

### 7. Testing the Setup

1. Run the application: `flutter run`
2. Test the following features:
   - User authentication (Firebase)
   - Map display (Google Maps)
   - Address search with autocomplete (Places API)
   - Location services

### 8. Troubleshooting

**Common Issues:**

1. **API Key Restrictions**: Ensure keys are properly restricted to your app
2. **Billing**: Enable billing on Google Cloud Platform
3. **Quotas**: Check API quotas and limits
4. **Platform Configuration**: Verify platform-specific setup files

**Error Messages:**
- `API key not valid` - Check key restrictions and enabled APIs
- `Places API not enabled` - Enable Places API in Google Cloud Console
- `Firebase not initialized` - Check Firebase configuration files

### 9. Environment Variables (Production)

For production deployment, use environment variables instead of hardcoded keys:

```bash
export WEB_API_KEY="your_web_api_key"
export ANDROID_API_KEY="your_android_api_key"
export IOS_API_KEY="your_ios_api_key"
export GOOGLE_MAP_API_KEY="your_google_map_api_key"
```

## Support

If you encounter issues with API key setup:
1. Check Google Cloud Console logs
2. Verify API quotas and billing
3. Review Firebase project configuration
4. Test with a simple API call first

## Security Notice

⚠️ **Important**: Keep your API keys secure and never expose them in client-side code or public repositories. Use server-side proxies for sensitive operations in production applications.
