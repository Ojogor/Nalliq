import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  Position? _currentPosition;
  Set<Marker> _markers = <Marker>{};
  bool _isLoading = true;
  String? _error;
  bool _locationPermissionGranted = false;
  bool _isInitialized = false;

  // Default location: St. John's, Newfoundland and Labrador, Canada
  static const LatLng _stJohnsNL = LatLng(47.5615, -52.7126);
  static const double _defaultZoom = 12.0;

  @override
  void initState() {
    super.initState();
    print('🗺️ MapScreen initState called');
    _initializeMap();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    if (_isInitialized) return;

    print('🗺️ Starting map initialization...');

    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _isInitialized = true;
      });

      // Step 1: Try to get location permission and current position
      await _handleLocationPermissionAndPosition();

      // Step 2: Add sample markers around the chosen location
      _addSampleMarkers();

      // Step 3: Update UI to show map
      setState(() {
        _isLoading = false;
      });

      print('✅ Map initialization completed successfully');
    } catch (e) {
      print('❌ Map initialization failed: $e');
      setState(() {
        _error = 'Map failed to load. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLocationPermissionAndPosition() async {
    // Always set St. John's as default first
    _setStJohnsAsDefault();

    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('📍 Location services disabled, using St. John\'s, NL');
        return;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // Request permission if needed
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // If permission is granted, try to get current location
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _locationPermissionGranted = true;
        await _getCurrentLocationWithFallback();
      } else {
        print('📍 Location permission denied, using St. John\'s, NL');
      }
    } catch (e) {
      print('❌ Error handling location: $e');
      // Keep St. John's as default - already set above
    }
  }

  void _setStJohnsAsDefault() {
    print('📍 Setting default location to St. John\'s, NL');
    _currentPosition = Position(
      latitude: _stJohnsNL.latitude,
      longitude: _stJohnsNL.longitude,
      timestamp: DateTime.now(),
      accuracy: 100.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  Future<void> _getCurrentLocationWithFallback() async {
    try {
      print('📍 Attempting to get current location...');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ Location request timed out, keeping St. John\'s, NL');
          throw TimeoutException('Location request timed out');
        },
      );

      print(
        '📍 Got current position: ${position.latitude}, ${position.longitude}',
      );

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('❌ Failed to get current location: $e');
      // Keep St. John's as default - already set in _setStJohnsAsDefault()
    }
  }

  void _addSampleMarkers() {
    if (_currentPosition == null) return;

    print(
      '📌 Adding sample markers around location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
    );

    final sampleFoodItems = [
      {
        'id': 'food_1',
        'title': 'Fresh Apples - 2kg',
        'category': 'Fruits & Vegetables',
        'owner': 'Sarah M.',
        'lat': _currentPosition!.latitude + 0.01,
        'lng': _currentPosition!.longitude + 0.008,
        'color': BitmapDescriptor.hueRed,
      },
      {
        'id': 'food_2',
        'title': 'Homemade Bread',
        'category': 'Bakery Items',
        'owner': 'Mike D.',
        'lat': _currentPosition!.latitude - 0.008,
        'lng': _currentPosition!.longitude + 0.012,
        'color': BitmapDescriptor.hueOrange,
      },
      {
        'id': 'food_3',
        'title': 'Canned Vegetables',
        'category': 'Canned Goods',
        'owner': 'Emma L.',
        'lat': _currentPosition!.latitude + 0.005,
        'lng': _currentPosition!.longitude - 0.01,
        'color': BitmapDescriptor.hueGreen,
      },
      {
        'id': 'food_4',
        'title': 'Rice & Pasta Mix',
        'category': 'Grains & Cereals',
        'owner': 'John B.',
        'lat': _currentPosition!.latitude - 0.006,
        'lng': _currentPosition!.longitude - 0.015,
        'color': BitmapDescriptor.hueBlue,
      },
      {
        'id': 'food_5',
        'title': 'Dairy Products',
        'category': 'Dairy',
        'owner': 'Lisa K.',
        'lat': _currentPosition!.latitude + 0.012,
        'lng': _currentPosition!.longitude + 0.005,
        'color': BitmapDescriptor.hueViolet,
      },
    ];

    final newMarkers = <Marker>{};

    // Add user location marker if we have actual location
    if (_locationPermissionGranted && _currentPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    // Add food item markers
    for (var item in sampleFoodItems) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(item['id'] as String),
          position: LatLng(item['lat'] as double, item['lng'] as double),
          infoWindow: InfoWindow(
            title: item['title'] as String,
            snippet: '${item['category']} • By ${item['owner']}',
            onTap: () => _showFoodItemDetails(item),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(item['color'] as double),
          onTap: () => _showFoodItemDetails(item),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });

    print('✅ Added ${newMarkers.length} markers to map');
  }

  void _showFoodItemDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title and category
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['category'] as String,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),

                // Owner
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Shared by ${item['owner']}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Requesting ${item['title']}...'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Request Item'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening chat with owner...'),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Message'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _handleLocationPermissionAndPosition();
    _addSampleMarkers();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Food Map',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLocation,
            tooltip: 'Refresh location',
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? _buildLoadingState()
                : _error != null
                ? _buildErrorState()
                : _buildMapView(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 16),
          Text(
            'Loading map...',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          SizedBox(height: 8),
          Text(
            'Finding food items near you',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isInitialized = false;
                });
                _initializeMap();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        // Google Map
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            print('🗺️ Map created, setting controller');
            _controller = controller;
          },
          initialCameraPosition: CameraPosition(
            target:
                _currentPosition != null
                    ? LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    )
                    : _stJohnsNL,
            zoom: _defaultZoom,
          ),
          markers: _markers,
          myLocationEnabled: _locationPermissionGranted,
          myLocationButtonEnabled: _locationPermissionGranted,
          mapType: MapType.normal,
          zoomControlsEnabled: true,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          tiltGesturesEnabled: true,
          rotateGesturesEnabled: true,
          compassEnabled: true,
          trafficEnabled: false,
          buildingsEnabled: true,
        ),

        // Location info card
        if (!_locationPermissionGranted)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Showing St. John\'s, NL area. Enable location for personalized results.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Food items count
        Positioned(
          bottom: 20,
          left: 20,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${_markers.length - (_locationPermissionGranted ? 1 : 0)} food items',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// TimeoutException class for older Dart versions
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
