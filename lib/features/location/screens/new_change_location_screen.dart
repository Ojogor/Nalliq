import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/models/user_location.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';

class ChangeLocationScreen extends StatefulWidget {
  const ChangeLocationScreen({super.key});

  @override
  State<ChangeLocationScreen> createState() => _ChangeLocationScreenState();
}

class _ChangeLocationScreenState extends State<ChangeLocationScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(
    47.5615,
    -52.7126,
  ); // Default to St. John's
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _addressController.text = "St. John's, NL, Canada";
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress() async {
    if (_addressController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final locations = await locationFromAddress(_addressController.text);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final newPosition = LatLng(location.latitude, location.longitude);

        setState(() {
          _selectedLocation = newPosition;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 15.0),
        );
      } else {
        setState(() {
          _error = 'Address not found. Please try a different address.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to search address: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get address details from coordinates
      final placemarks = await placemarkFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        final userLocation = UserLocation(
          address: _addressController.text.trim(),
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
          city: placemark.locality,
          province: placemark.administrativeArea,
          country: placemark.country,
          isVisible: true,
          lastUpdated: DateTime.now(),
        );

        // Return the location to the previous screen
        if (mounted) {
          context.pop(userLocation);
        }
      } else {
        setState(() {
          _error = 'Unable to get address details for this location.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to confirm location: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapTap(LatLng position) async {
    setState(() {
      _selectedLocation = position;
      _isLoading = true;
    });

    try {
      // Update address field with reverse geocoding
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.name,
          placemark.locality,
          placemark.administrativeArea,
          placemark.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        _addressController.text = address;
      }
    } catch (e) {
      print('Error getting address: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      appBar: const CustomAppBar(title: 'Change Location'),
      body: Column(
        children: [
          // Address Search Section
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search Address',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: 'Enter address...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onSubmitted: (_) => _searchAddress(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isLoading ? null : _searchAddress,
                      icon:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.search),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Map Section
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _selectedLocation,
                zoom: 15.0,
              ),
              onTap: _onMapTap,
              markers: {
                Marker(
                  markerId: const MarkerId('selected_location'),
                  position: _selectedLocation,
                  infoWindow: const InfoWindow(
                    title: 'Selected Location',
                    snippet: 'Tap to confirm this location',
                  ),
                ),
              },
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
            ),
          ),

          // Confirm Button Section
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Selected Location:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _addressController.text.isNotEmpty
                      ? _addressController.text
                      : 'Tap on the map to select a location',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: _isLoading ? 'Confirming...' : 'Confirm Location',
                  onPressed: _isLoading ? () {} : _confirmLocation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
