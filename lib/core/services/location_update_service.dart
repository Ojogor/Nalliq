import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/location_service.dart';

class LocationUpdateService {
  static StreamSubscription<Position>? _positionStream;
  static Timer? _updateTimer;
  static LatLng? _lastKnownLocation;
  static bool _isTracking = false;

  // Minimum distance in meters to trigger an update
  static const double _minDistanceForUpdate = 100.0;

  // Update frequency in minutes
  static const int _updateIntervalMinutes = 5;

  /// Start real-time location tracking
  static Future<void> startLocationTracking() async {
    if (_isTracking) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Check if we have location permission
      final hasPermission =
          await LocationService.checkAndRequestLocationPermission();
      if (!hasPermission) {
        print('Location permission denied, cannot start tracking');
        return;
      }

      _isTracking = true;
      print('📍 Starting location tracking...');

      // Set up position stream
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _handleLocationUpdate(position);
        },
        onError: (error) {
          print('Location stream error: $error');
        },
      );

      // Set up periodic updates (backup for when user isn't moving)
      _updateTimer = Timer.periodic(Duration(minutes: _updateIntervalMinutes), (
        timer,
      ) async {
        final position = await LocationService.getCurrentPosition();
        if (position != null) {
          _handleLocationUpdate(position);
        }
      });
    } catch (e) {
      print('Error starting location tracking: $e');
      _isTracking = false;
    }
  }

  /// Stop location tracking
  static void stopLocationTracking() {
    if (!_isTracking) return;

    print('📍 Stopping location tracking...');

    _positionStream?.cancel();
    _updateTimer?.cancel();
    _positionStream = null;
    _updateTimer = null;
    _isTracking = false;
  }

  /// Handle new location update
  static Future<void> _handleLocationUpdate(Position position) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final newLocation = LatLng(position.latitude, position.longitude);

    // Check if we've moved far enough to warrant an update
    if (_lastKnownLocation != null) {
      final distance = Geolocator.distanceBetween(
        _lastKnownLocation!.latitude,
        _lastKnownLocation!.longitude,
        newLocation.latitude,
        newLocation.longitude,
      );

      if (distance < _minDistanceForUpdate) {
        return; // Not moved far enough
      }
    }

    try {
      // Get address for the new location
      String address = 'Unknown location';
      try {
        // You might want to implement reverse geocoding here
        address =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      } catch (e) {
        print('Error getting address: $e');
      }

      // Update user location in Firebase
      final success = await UserService.updateUserLocation(
        userId: currentUser.uid,
        coordinates: newLocation,
        address: address,
        isVisible: true, // You might want to check user preferences here
      );

      if (success) {
        _lastKnownLocation = newLocation;
        print(
          '📍 Location updated: ${newLocation.latitude}, ${newLocation.longitude}',
        );
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  /// Manually update location
  static Future<bool> updateLocationNow() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      await _handleLocationUpdate(position);
      return true;
    }
    return false;
  }

  /// Check if location tracking is active
  static bool get isTracking => _isTracking;

  /// Get last known location
  static LatLng? get lastKnownLocation => _lastKnownLocation;

  /// Update location visibility without changing coordinates
  static Future<bool> updateLocationVisibility(bool isVisible) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    return await UserService.updateLocationVisibility(
      userId: currentUser.uid,
      isVisible: isVisible,
    );
  }

  /// Initialize location tracking on app start
  static Future<void> initializeOnAppStart() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Load user preferences to see if they want location tracking
    final userData = await UserService.getCurrentUser();
    if (userData?.location != null) {
      final isVisible = userData!.location!['isVisible'] as bool? ?? false;
      if (isVisible) {
        // Start tracking if user has enabled location sharing
        await startLocationTracking();
      }
    }
  }

  /// Clean up resources
  static void dispose() {
    stopLocationTracking();
  }
}
