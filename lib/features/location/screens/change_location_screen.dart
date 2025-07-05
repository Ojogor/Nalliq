import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:nalliq/core/models/user_location.dart';

class ChangeLocationScreen extends StatefulWidget {
  const ChangeLocationScreen({super.key});

  @override
  State<ChangeLocationScreen> createState() => _ChangeLocationScreenState();
}

class _ChangeLocationScreenState extends State<ChangeLocationScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(47.5615, -52.7126); // St. John's
  Marker? _marker;
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _marker = Marker(
      markerId: const MarkerId('selected-location'),
      position: _selectedLocation,
      infoWindow: const InfoWindow(title: 'Selected Location'),
    );

    // Set initial address
    _addressController.text = 'St. John\'s, NL, Canada';
  }

  Future<void> _onMapTapped(LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _marker = Marker(
        markerId: const MarkerId('selected-location'),
        position: _selectedLocation,
        infoWindow: const InfoWindow(title: 'Selected Location'),
      );
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.street,
          placemark.locality,
          placemark.administrativeArea,
        ].where((part) => part != null && part.isNotEmpty).join(', ');

        _addressController.text =
            address.isEmpty
                ? 'Latitude: ${_selectedLocation.latitude.toStringAsFixed(4)}, '
                    'Longitude: ${_selectedLocation.longitude.toStringAsFixed(4)}'
                : address;
      }
    } catch (e) {
      // Fallback to coordinates if geocoding fails
      _addressController.text =
          'Latitude: ${_selectedLocation.latitude.toStringAsFixed(4)}, '
          'Longitude: ${_selectedLocation.longitude.toStringAsFixed(4)}';
      print('Geocoding error: $e');
    }
  }

  Future<void> _onSearch() async {
    if (_addressController.text.trim().isEmpty) return;

    try {
      final locations = await locationFromAddress(_addressController.text);
      if (locations.isNotEmpty) {
        final location = locations.first;
        _selectedLocation = LatLng(location.latitude, location.longitude);

        // Update marker
        setState(() {
          _marker = Marker(
            markerId: const MarkerId('selected-location'),
            position: _selectedLocation,
            infoWindow: const InfoWindow(title: 'Selected Location'),
          );
        });

        // Animate camera to new location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation, 15),
        );
      } else {
        _showErrorSnackBar(
          'Address not found. Please try a different address.',
        );
      }
    } catch (e) {
      print('Search error: $e');
      _showErrorSnackBar('Error searching for address. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onConfirm() async {
    try {
      // Get detailed place information
      final placemarks = await placemarkFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );

      String? city, province, country;
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        city = placemark.locality;
        province = placemark.administrativeArea;
        country = placemark.country;
      }

      Navigator.pop(
        context,
        UserLocation(
          address: _addressController.text,
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
          city: city,
          province: province,
          country: country,
          isVisible: true,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e) {
      print('Error getting location details: $e');
      // Fallback without detailed location info
      Navigator.pop(
        context,
        UserLocation(
          address: _addressController.text,
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
          isVisible: true,
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Location'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Debug info banner
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Current: ${_selectedLocation.latitude.toStringAsFixed(4)}, '
              '${_selectedLocation.longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              child: GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  print('Google Map created successfully');
                },
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation,
                  zoom: 13,
                ),
                onTap: _onMapTapped,
                markers: _marker != null ? {_marker!} : {},
                mapType: MapType.normal,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                compassEnabled: true,
                mapToolbarEnabled: false,
                buildingsEnabled: true,
                trafficEnabled: false,
                liteModeEnabled: false, // Ensure full map mode
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{},
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    hintText: 'Enter an address to search',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _onSearch,
                    ),
                  ),
                  onSubmitted: (value) => _onSearch(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async => await _onConfirm(),
                        icon: const Icon(Icons.check),
                        label: const Text('Confirm Location'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap on the map to select a location or search for an address',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
