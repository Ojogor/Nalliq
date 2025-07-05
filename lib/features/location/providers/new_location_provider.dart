import 'package:flutter/material.dart';
import '../../../core/models/user_location.dart';
import '../../../core/services/firebase_location_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationProvider extends ChangeNotifier {
  UserLocation? _currentLocation;
  List<MapUser> _nearbyUsers = [];
  bool _isLoading = false;
  String? _error;

  UserLocation? get currentLocation => _currentLocation;
  List<MapUser> get nearbyUsers => _nearbyUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<MapUser>> get nearbyUsersStream =>
      FirebaseLocationService.getNearbyUsersStream();

  // Initialize location provider
  Future<void> initializeLocation() async {
    _setLoading(true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Initialize with default location for new users
        await FirebaseLocationService.initializeUserLocation(user.uid);

        // Load current user location
        await loadCurrentLocation();

        // Load nearby users
        await loadNearbyUsers();
      }
    } catch (e) {
      _setError('Failed to initialize location: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load current user's location
  Future<void> loadCurrentLocation() async {
    try {
      final location = await FirebaseLocationService.getCurrentUserLocation();
      _currentLocation = location ?? UserLocation.defaultLocation;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load current location: $e');
    }
  }

  // Load nearby users
  Future<void> loadNearbyUsers() async {
    try {
      _nearbyUsers = await FirebaseLocationService.getAllUsersWithLocations();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load nearby users: $e');
    }
  }

  // Update user location
  Future<void> updateLocation(UserLocation newLocation) async {
    _setLoading(true);
    try {
      await FirebaseLocationService.updateUserLocation(newLocation);
      _currentLocation = newLocation;

      // Reload nearby users to get updated data
      await loadNearbyUsers();

      _setError(null);
    } catch (e) {
      _setError('Failed to update location: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get distance to another user
  double getDistanceTo(UserLocation otherLocation) {
    if (_currentLocation == null) return 0.0;
    return FirebaseLocationService.calculateDistance(
      _currentLocation!,
      otherLocation,
    );
  }

  // Toggle location visibility
  Future<void> toggleLocationVisibility() async {
    if (_currentLocation == null) return;

    final updatedLocation = _currentLocation!.copyWith(
      isVisible: !_currentLocation!.isVisible,
    );

    await updateLocation(updatedLocation);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
