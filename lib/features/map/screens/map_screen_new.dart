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

  // Default location: St. John's, NL, Canada
  static const LatLng _defaultLocation = LatLng(47.5615, -52.7126);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    print('🗺️ Starting map initialization...');

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Step 1: Check and request location permission
      final permissionGranted = await _requestLocationPermission();
      print('📍 Location permission granted: $permissionGranted');

      // Step 2: Get current location (or use default)
      await _getCurrentLocation();

      // Step 3: Add sample markers
      _addSampleMarkers();

      // Step 4: Update UI
      setState(() {
        _isLoading = false;
        _locationPermissionGranted = permissionGranted;
      });

      print('✅ Map initialization completed successfully');
    } catch (e) {
      print('❌ Map initialization failed: $e');
      setState(() {
        _error = 'Failed to initialize map: $e';
        _isLoading = false;
      });
    }
  }

  Future<bool> _requestLocationPermission() async {
    try {
      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      print('🔒 Current permission status: $permission');

      // If permission is denied, request it
      if (permission == LocationPermission.denied) {
        print('🔒 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('🔒 Permission request result: $permission');
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 Location services enabled: $serviceEnabled');

      final isGranted =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      return isGranted && serviceEnabled;
    } catch (e) {
      print('❌ Error requesting location permission: $e');
      return false;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      print('📍 Attempting to get current location...');

      if (!_locationPermissionGranted) {
        print(
          '📍 Permission not granted, using default location (St. John\'s, NL)',
        );
        _setDefaultPosition();
        return;
      }

      // Try to get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏱️ Location request timed out, using default location');
          throw Exception('Location request timed out');
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
      _setDefaultPosition();
    }
  }

  void _setDefaultPosition() {
    print('📍 Setting default position to St. John\'s, NL');
    setState(() {
      _currentPosition = Position(
        latitude: _defaultLocation.latitude,
        longitude: _defaultLocation.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    });
  }

  void _addSampleMarkers() {
    if (_currentPosition == null) return;

    print('📌 Adding sample markers around current location');

    final sampleFoodItems = [
      {
        'id': 'food_1',
        'title': 'Fresh Apples',
        'category': 'Fruits',
        'lat': _currentPosition!.latitude + 0.01,
        'lng': _currentPosition!.longitude + 0.01,
        'color': BitmapDescriptor.hueRed,
      },
      {
        'id': 'food_2',
        'title': 'Homemade Bread',
        'category': 'Bakery',
        'lat': _currentPosition!.latitude - 0.008,
        'lng': _currentPosition!.longitude + 0.015,
        'color': BitmapDescriptor.hueOrange,
      },
      {
        'id': 'food_3',
        'title': 'Canned Vegetables',
        'category': 'Canned',
        'lat': _currentPosition!.latitude + 0.012,
        'lng': _currentPosition!.longitude - 0.01,
        'color': BitmapDescriptor.hueGreen,
      },
      {
        'id': 'food_4',
        'title': 'Rice & Pasta',
        'category': 'Grains',
        'lat': _currentPosition!.latitude - 0.005,
        'lng': _currentPosition!.longitude - 0.012,
        'color': BitmapDescriptor.hueBlue,
      },
    ];

    final newMarkers = <Marker>{};
    for (var item in sampleFoodItems) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(item['id'] as String),
          position: LatLng(item['lat'] as double, item['lng'] as double),
          infoWindow: InfoWindow(
            title: item['title'] as String,
            snippet: '${item['category']} • Tap for details',
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

    print('📌 Added ${_markers.length} markers to map');
  }

  void _showFoodItemDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle bar
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
                        const SizedBox(height: 20),

                        // Food item image placeholder
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.fastfood,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Category
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item['category'] as String,
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          'Fresh and healthy ${(item['title'] as String).toLowerCase()} available for sharing. Great condition, perfect for immediate consumption or cooking.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Opening food item details...',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.info_outline),
                                label: const Text('View Details'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Opening chat with owner...',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text('Contact'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void _centerOnCurrentLocation() {
    if (_controller != null && _currentPosition != null) {
      _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Food Items'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_currentPosition != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _centerOnCurrentLocation,
              tooltip: 'Go to my location',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeMap,
            tooltip: 'Refresh map',
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      SizedBox(height: 16),
                      Text('Loading map...', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                )
                : _error != null
                ? _buildErrorView()
                : _buildMapView(),
      ),
      floatingActionButton:
          _currentPosition != null && !_isLoading
              ? FloatingActionButton(
                heroTag: "map_screen_new_fab",
                onPressed: _centerOnCurrentLocation,
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                child: const Icon(Icons.my_location),
              )
              : null,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 20),
            Text(
              'Unable to load map',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _initializeMap,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    final cameraPosition = CameraPosition(
      target:
          _currentPosition != null
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : _defaultLocation,
      zoom: 14.0,
    );

    return Column(
      children: [
        // Info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.green[50],
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _locationPermissionGranted
                      ? (_currentPosition != null
                          ? 'Showing food items near your location'
                          : 'Using default location: St. John\'s, NL')
                      : 'Location permission required for personalized results',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Map
        Expanded(
          child: GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              print('🗺️ Map controller created successfully');
            },
            initialCameraPosition: cameraPosition,
            markers: _markers,
            myLocationEnabled:
                _locationPermissionGranted && _currentPosition != null,
            myLocationButtonEnabled: false, // We have our own FAB
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            compassEnabled: true,
            buildingsEnabled: true,
            trafficEnabled: false,
            mapType: MapType.normal,
            onTap: (LatLng position) {
              print(
                '🗺️ Map tapped at: ${position.latitude}, ${position.longitude}',
              );
            },
          ),
        ),
      ],
    );
  }
}
