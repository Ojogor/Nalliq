import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

class LocationService {
  static const double _earthRadius = 6371; // Earth's radius in kilometers

  /// Check if location services are enabled and request permissions
  static Future<bool> checkAndRequestLocationPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current user position
  static Future<Position?> getCurrentPosition() async {
    try {
      bool hasPermission = await checkAndRequestLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Calculate distance between two points in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Calculate distance using Haversine formula (more accurate for longer distances)
  static double calculateDistanceHaversine(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  /// Convert location map to readable address string
  static String formatLocationToAddress(Map<String, dynamic>? location) {
    if (location == null) return 'Location not available';

    if (location['address'] != null) {
      return location['address'] as String;
    }

    if (location['lat'] != null && location['lng'] != null) {
      return '${location['lat'].toStringAsFixed(4)}, ${location['lng'].toStringAsFixed(4)}';
    }

    return 'Location not available';
  }

  /// Create location map from coordinates
  static Map<String, dynamic> createLocationMap({
    required double latitude,
    required double longitude,
    String? address,
  }) {
    return {
      'lat': latitude,
      'lng': longitude,
      if (address != null) 'address': address,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Check if a location is within a certain radius (in km)
  static bool isWithinRadius(
    Map<String, dynamic>? itemLocation,
    Map<String, dynamic>? userLocation,
    double radiusKm,
  ) {
    if (itemLocation == null || userLocation == null) return false;

    final itemLat = itemLocation['lat'] as double?;
    final itemLng = itemLocation['lng'] as double?;
    final userLat = userLocation['lat'] as double?;
    final userLng = userLocation['lng'] as double?;

    if (itemLat == null ||
        itemLng == null ||
        userLat == null ||
        userLng == null) {
      return false;
    }

    final distance = calculateDistance(userLat, userLng, itemLat, itemLng);
    return distance <= radiusKm;
  }

  /// Get distance in human-readable format
  static String getDistanceText(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m away';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km away';
    } else {
      return '${distanceKm.round()}km away';
    }
  }

  /// Get location permission status
  static Future<PermissionStatus> getLocationPermissionStatus() async {
    return await Permission.location.status;
  }

  /// Open app settings for location permissions
  static Future<bool> openLocationSettings() async {
    return await openAppSettings();
  }
}
