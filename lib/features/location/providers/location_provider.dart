import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/location_service.dart';
import '../../../core/models/food_item_model.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  Map<String, dynamic>? _currentLocationMap;
  bool _isLocationEnabled = true;
  bool _isLoading = false;
  String? _error;

  // Filter settings
  double _searchRadius = 10.0; // Default 10km radius
  bool _showDistanceInCards = true;
  bool _sortByDistance = true;

  // Location alerts
  bool _locationAlertsEnabled = true;
  double _alertRadius = 5.0; // Default 5km for alerts

  // Getters
  Position? get currentPosition => _currentPosition;
  Map<String, dynamic>? get currentLocationMap => _currentLocationMap;
  bool get isLocationEnabled => _isLocationEnabled;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get searchRadius => _searchRadius;
  bool get showDistanceInCards => _showDistanceInCards;
  bool get sortByDistance => _sortByDistance;
  bool get locationAlertsEnabled => _locationAlertsEnabled;
  double get alertRadius => _alertRadius;

  bool get hasLocation => _currentPosition != null;

  /// Initialize location services and load settings
  Future<void> initializeLocation() async {
    await _loadSettings();
    if (_isLocationEnabled) {
      await updateCurrentLocation();
    }
  }

  /// Update current location
  Future<void> updateCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        _currentPosition = position;
        _currentLocationMap = LocationService.createLocationMap(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _error = null;
      } else {
        _error = 'Unable to get location. Please check permissions.';
      }
    } catch (e) {
      _error = 'Location error: $e';
      _currentPosition = null;
      _currentLocationMap = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filter items by location within search radius
  List<FoodItem> filterItemsByLocation(List<FoodItem> items) {
    if (!_isLocationEnabled || _currentLocationMap == null) {
      return items;
    }

    final filteredItems =
        items.where((item) {
          if (item.location == null) return false;

          return LocationService.isWithinRadius(
            item.location,
            _currentLocationMap,
            _searchRadius,
          );
        }).toList();

    // Sort by distance if enabled
    if (_sortByDistance && _currentLocationMap != null) {
      filteredItems.sort((a, b) {
        final distanceA = _getItemDistance(a);
        final distanceB = _getItemDistance(b);
        return distanceA.compareTo(distanceB);
      });
    }

    return filteredItems;
  }

  /// Get distance to an item in kilometers
  double _getItemDistance(FoodItem item) {
    if (item.location == null || _currentLocationMap == null) {
      return double.infinity;
    }

    final itemLat = item.location!['lat'] as double?;
    final itemLng = item.location!['lng'] as double?;
    final userLat = _currentLocationMap!['lat'] as double?;
    final userLng = _currentLocationMap!['lng'] as double?;

    if (itemLat == null ||
        itemLng == null ||
        userLat == null ||
        userLng == null) {
      return double.infinity;
    }

    return LocationService.calculateDistance(
      userLat,
      userLng,
      itemLat,
      itemLng,
    );
  }

  /// Get formatted distance text for an item
  String getItemDistanceText(FoodItem item) {
    if (!_showDistanceInCards || !_isLocationEnabled) return '';

    final distance = _getItemDistance(item);
    if (distance == double.infinity) return '';

    return LocationService.getDistanceText(distance);
  }

  /// Check if new item should trigger location alert
  bool shouldTriggerLocationAlert(FoodItem newItem) {
    if (!_locationAlertsEnabled ||
        _currentLocationMap == null ||
        newItem.location == null) {
      return false;
    }

    return LocationService.isWithinRadius(
      newItem.location,
      _currentLocationMap,
      _alertRadius,
    );
  }

  /// Update search radius
  Future<void> updateSearchRadius(double radius) async {
    _searchRadius = radius;
    await _saveSettings();
    notifyListeners();
  }

  /// Update alert radius
  Future<void> updateAlertRadius(double radius) async {
    _alertRadius = radius;
    await _saveSettings();
    notifyListeners();
  }

  /// Toggle location services
  Future<void> toggleLocationEnabled() async {
    _isLocationEnabled = !_isLocationEnabled;

    if (_isLocationEnabled) {
      await updateCurrentLocation();
    } else {
      _currentPosition = null;
      _currentLocationMap = null;
    }

    await _saveSettings();
    notifyListeners();
  }

  /// Toggle distance display in cards
  Future<void> toggleShowDistanceInCards() async {
    _showDistanceInCards = !_showDistanceInCards;
    await _saveSettings();
    notifyListeners();
  }

  /// Toggle sort by distance
  Future<void> toggleSortByDistance() async {
    _sortByDistance = !_sortByDistance;
    await _saveSettings();
    notifyListeners();
  }

  /// Toggle location alerts
  Future<void> toggleLocationAlerts() async {
    _locationAlertsEnabled = !_locationAlertsEnabled;
    await _saveSettings();
    notifyListeners();
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _isLocationEnabled = prefs.getBool('location_enabled') ?? true;
    _searchRadius = prefs.getDouble('search_radius') ?? 10.0;
    _showDistanceInCards = prefs.getBool('show_distance_in_cards') ?? true;
    _sortByDistance = prefs.getBool('sort_by_distance') ?? true;
    _locationAlertsEnabled = prefs.getBool('location_alerts_enabled') ?? true;
    _alertRadius = prefs.getDouble('alert_radius') ?? 5.0;

    notifyListeners();
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('location_enabled', _isLocationEnabled);
    await prefs.setDouble('search_radius', _searchRadius);
    await prefs.setBool('show_distance_in_cards', _showDistanceInCards);
    await prefs.setBool('sort_by_distance', _sortByDistance);
    await prefs.setBool('location_alerts_enabled', _locationAlertsEnabled);
    await prefs.setDouble('alert_radius', _alertRadius);
  }

  /// Get available radius options for dropdowns
  List<double> get radiusOptions => [1, 2, 5, 10, 15, 25, 50, 100];

  /// Get radius text for display
  String getRadiusText(double radius) {
    if (radius < 1) {
      return '${(radius * 1000).round()}m';
    } else {
      return '${radius.round()}km';
    }
  }
}
