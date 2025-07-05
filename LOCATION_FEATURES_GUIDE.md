# Location Features Guide

## Overview
The Nalliq app now includes comprehensive location-based features to help you discover nearby food items and receive alerts for new items in your area.

## Features Implemented

### 1. Google Maps Integration
- **Maps Screen**: View nearby food items on an interactive Google Maps interface
- **Access**: Tap the map icon in the home screen app bar
- **Features**:
  - See all available food items as markers on the map
  - View your current location
  - Filter items by radius and category
  - Tap markers for item details

### 2. Location-Based Filtering
- **Distance Display**: Food item cards show distance from your location
- **Search Filtering**: Search results are filtered by your preferred radius
- **Location Filter Widget**: Adjust search radius and sorting preferences

### 3. Location-Based Alerts & Notifications
- **Automatic Alerts**: Get notified when new food items appear within your preferred radius
- **Customizable Settings**: Set your alert radius and enable/disable notifications
- **Background Monitoring**: App monitors for new items even when closed

### 4. Location Settings 
- **Advanced Settings**: Access via Settings > Advanced Location Settings
- **Control Options**:
  - Enable/disable location services
  - Set search radius (1-50km)
  - Configure alert radius (1-20km)
  - Toggle location-based notifications
  - Distance display preferences

## Setup Instructions

### 1. Google Maps API Configuration
⚠️ **Important**: You need to configure the Google Maps API key before using map features.

#### For Android:
1. Get a Google Maps API key from the Google Cloud Console
2. Open `android/app/src/main/AndroidManifest.xml`
3. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_ACTUAL_API_KEY_HERE" />
   ```

#### For iOS:
1. Add your Google Maps API key to `ios/Runner/AppDelegate.swift`
2. Import GoogleMaps and configure in `application:didFinishLaunchingWithOptions:`

### 2. Permissions
The app automatically requests the following permissions:
- **Location Access**: Required for showing nearby items and maps
- **Notification Access**: Required for location-based alerts

## How to Use

### Using the Maps Feature
1. **Open Maps**: Tap the map icon (📍) in the home screen app bar
2. **Grant Permissions**: Allow location access when prompted
3. **View Items**: See nearby food items as markers on the map
4. **Filter**: Use the filter controls to adjust radius and item types
5. **Get Directions**: Tap on markers for item details and navigation options

### Setting Up Location Alerts
1. **Go to Settings**: Navigate to Settings > Advanced Location Settings
2. **Enable Alerts**: Toggle "Location Alerts" on
3. **Set Radius**: Choose your preferred alert radius (e.g., 5km)
4. **Grant Notification Permission**: Allow notifications when prompted

### Using Location Filtering in Search
1. **Search for Items**: Use the search screen to find food items
2. **Automatic Filtering**: Items are automatically filtered by your set radius
3. **Adjust Radius**: Use the location filter widget to change search radius
4. **Sort by Distance**: Items can be sorted by distance from your location

### Adding Items with Location
1. **Add New Item**: Use the Enhanced Add Item screen
2. **Automatic Location**: Your current location is automatically attached to new items
3. **Privacy**: Location helps others find your items when searching nearby

## Technical Details

### New Files Added
- `lib/core/services/location_service.dart` - Core location functionality
- `lib/features/location/providers/location_provider.dart` - State management
- `lib/features/location/screens/maps_screen.dart` - Google Maps integration
- `lib/features/location/widgets/location_filter_widget.dart` - Filter controls
- `lib/features/location/screens/location_settings_screen.dart` - Settings UI
- `lib/features/location/services/location_notification_service.dart` - Notifications

### Dependencies Added
- `google_maps_flutter: ^2.9.0` - Google Maps integration
- `geolocator: ^13.0.1` - Location services
- `permission_handler: ^11.3.1` - Permission handling
- `flutter_local_notifications: ^18.0.1` - Local notifications

### Permissions Configured
- **Android**: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `INTERNET`
- **iOS**: `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`

## Privacy & Data

### Location Data Storage
- **User Location**: Stored locally and used for filtering/distance calculations
- **Item Locations**: Stored with food items to enable discovery
- **No Tracking**: User location is not continuously tracked or shared

### User Control
- **Opt-in**: All location features are optional
- **Granular Control**: Users can enable/disable specific features
- **Privacy First**: Location data is only used for app functionality

## Troubleshooting

### Maps Not Loading
1. Verify Google Maps API key is correctly configured
2. Check internet connection
3. Ensure location permissions are granted

### No Location-Based Results
1. Check if location services are enabled in Settings
2. Verify device location is turned on
3. Try increasing search radius

### Not Receiving Alerts
1. Check notification permissions
2. Verify location alerts are enabled in settings
3. Ensure app has background app refresh enabled

### Distance Not Showing
1. Enable location services in app settings
2. Grant location permission when prompted
3. Check "Show Distance in Cards" setting

## Future Enhancements

### Planned Features
- **Driving Directions**: Integration with navigation apps
- **Location History**: Track frequently visited areas
- **Geofencing**: More advanced location-based triggers
- **Location Sharing**: Share pickup locations with other users

### Performance Optimizations
- **Caching**: Cache location data for better performance
- **Battery Optimization**: Efficient location updates
- **Background Limits**: Smart background processing

## Support

If you encounter issues with location features:
1. Check this guide for common solutions
2. Verify API keys and permissions are correctly configured
3. Test on a physical device (location features may not work on simulators)
4. Check device location settings

Remember to test location features on physical devices, as simulators may not provide accurate location data.
