# Google Maps API Key Setup

## Issue Fixed ✅
The address search was showing "The provided API key is invalid" because the code was using the wrong API key field. This has been fixed by updating the code to use `secret.googleMapApiKey` instead of `secret.webApiKey`.

## Current API Key Configuration
Your `secrets.json` is correctly configured with the Google Maps API key that includes Places API access:
```
google_map_api_key: AIzaSyAvaPjyeIeTsHV9tIzsJRNVYLhcL4aJCRs
```

## Required APIs
For the address search and map functionality to work, you need to enable these APIs in Google Cloud Console:

1. **Maps JavaScript API** - For displaying the map
2. **Places API** - For address autocomplete and search
3. **Geocoding API** - For converting addresses to coordinates
4. **Geolocation API** - For getting user location

## Steps to Fix:

### 1. Go to Google Cloud Console
- Visit https://console.cloud.google.com/
- Select your project or create a new one

### 2. Enable Required APIs
- Go to "APIs & Services" > "Library"
- Search for and enable each of the APIs listed above

### 3. Create/Update API Key
- Go to "APIs & Services" > "Credentials"
- Create a new API key or update existing one
- **Important**: Restrict the API key:
  - Set application restrictions (Android/iOS/HTTP referrers)
  - Set API restrictions to only the APIs you enabled above

### 4. Update secrets.json
Edit `assets/secrets.json` and update the `google_map_api_key` field:

```json
{
  "web_api_key": "your-firebase-web-api-key",
  "android_api_key": "your-firebase-android-api-key", 
  "ios_api_key": "your-firebase-ios-api-key",
  "google_map_api_key": "your-google-maps-api-key-here"
}
```

### 5. Configure API Key for Android
Also add the API key to `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="your-google-maps-api-key-here" />
```

### 6. Test the Implementation
- Clean and rebuild the app
- Try the address search functionality
- Check that map loads correctly
- Verify filter functionality works

## Troubleshooting
- If you still see "API key invalid", check the API restrictions
- Make sure the API key has the correct referrer restrictions
- Verify all required APIs are enabled
- Check quotas and billing in Google Cloud Console

## Current Features Fixed:
✅ Removed whitespace above settings banner
✅ Implemented Help & Support screen
✅ Implemented About Nalliq screen  
✅ Fixed duplicate X buttons in address search
✅ Improved map filter functionality
🔧 API key configuration needed for address search
