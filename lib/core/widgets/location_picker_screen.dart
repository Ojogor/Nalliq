import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.initialAddress,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _controller;
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoading = true;
  bool _isLoadingAddress = false;
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    // Default to St. John's, NL
    LatLng defaultLocation = const LatLng(47.5615, -52.7126);
    LatLng initialLocation;

    if (widget.initialLocation != null) {
      initialLocation = widget.initialLocation!;
      _selectedAddress = widget.initialAddress ?? '';
      _addressController.text = _selectedAddress;
    } else {
      try {
        // Try to get current location, but fall back to St. John's
        Position position = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 5),
        ).timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            throw Exception('Location timeout');
          },
        );
        initialLocation = LatLng(position.latitude, position.longitude);
        print('📍 Location picker: Got current location');
      } catch (e) {
        print(
          '📍 Location picker: Failed to get location, using St. John\'s, NL: $e',
        );
        initialLocation = defaultLocation;
        _selectedAddress = 'St. John\'s, NL, Canada';
        _addressController.text = _selectedAddress;
      }
    }

    setState(() {
      _selectedLocation = initialLocation;
      _isLoading = false;
    });
  }

  Future<String> _getAddressFromCoordinates(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street ?? ''}, ${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}, ${placemark.country ?? ''}'
            .replaceAll(RegExp(r'^,\s*|,\s*$'), '')
            .replaceAll(RegExp(r',\s*,'), ',');
      }
      return 'Unknown location';
    } catch (e) {
      return 'Unknown location';
    }
  }

  Future<void> _onMapTapped(LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _isLoadingAddress = true;
    });

    final address = await _getAddressFromCoordinates(location);

    setState(() {
      _selectedAddress = address;
      _addressController.text = address;
      _isLoadingAddress = false;
    });
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {
        'location': _selectedLocation,
        'address': _selectedAddress,
      });
    }
  }

  void _getCurrentLocation() async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);
      final address = await _getAddressFromCoordinates(location);

      setState(() {
        _selectedLocation = location;
        _selectedAddress = address;
        _addressController.text = address;
        _isLoadingAddress = false;
      });

      _controller?.animateCamera(CameraUpdate.newLatLng(location));
    } catch (e) {
      setState(() {
        _isLoadingAddress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get current location: $e')),
      );
    }
  }

  void _onAddressSearch() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final addresses = await locationFromAddress(address);
      if (addresses.isNotEmpty) {
        final location = LatLng(
          addresses.first.latitude,
          addresses.first.longitude,
        );

        setState(() {
          _selectedLocation = location;
          _selectedAddress = address;
          _isLoadingAddress = false;
        });

        _controller?.animateCamera(CameraUpdate.newLatLng(location));
      } else {
        setState(() {
          _isLoadingAddress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address not found. Please try a different search.'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingAddress = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to find location: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _selectedLocation != null ? _confirmLocation : null,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    // Address search field
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[50],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Enter your address or location description:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              hintText:
                                  "e.g. Downtown Ottawa, near ByWard Market",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.green,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.green,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.green,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.search,
                                  color: Colors.green,
                                ),
                                onPressed: _onAddressSearch,
                              ),
                            ),
                            onSubmitted: (_) => _onAddressSearch(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tip: Tap anywhere on the map to set your precise location',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Location display section
                    if (_selectedLocation != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.green[50],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Selected Location:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _isLoadingAddress
                                ? const Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Getting address...'),
                                  ],
                                )
                                : Text(
                                  _selectedAddress,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                          ],
                        ),
                      ),

                    // Map
                    Expanded(
                      child: GoogleMap(
                        onMapCreated: (controller) => _controller = controller,
                        initialCameraPosition: CameraPosition(
                          target:
                              _selectedLocation ??
                              const LatLng(45.4215, -75.6972),
                          zoom: 15.0,
                        ),
                        onTap: _onMapTapped,
                        markers:
                            _selectedLocation != null
                                ? {
                                  Marker(
                                    markerId: const MarkerId(
                                      'selected_location',
                                    ),
                                    position: _selectedLocation!,
                                    draggable: true,
                                    onDragEnd: _onMapTapped,
                                  ),
                                }
                                : {},
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                      ),
                    ),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "location_picker_fab",
        onPressed: _getCurrentLocation,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
