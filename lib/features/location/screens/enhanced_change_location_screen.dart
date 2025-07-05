import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../../../core/models/user_location.dart';
import '../../../core/constants/app_colors.dart';
import '../../../secrets_service.dart';

class EnhancedChangeLocationScreen extends StatefulWidget {
  const EnhancedChangeLocationScreen({super.key});

  @override
  State<EnhancedChangeLocationScreen> createState() =>
      _EnhancedChangeLocationScreenState();
}

class _EnhancedChangeLocationScreenState
    extends State<EnhancedChangeLocationScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(
    47.5615,
    -52.7126,
  ); // Default to St. John's
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _googleApiKey;

  @override
  void initState() {
    super.initState();
    _initializeSecrets();
    _addressController.text = "St. John's, NL, Canada";
  }

  Future<void> _initializeSecrets() async {
    try {
      final secret = await SecretService.load();
      setState(() {
        _googleApiKey = secret.googleMapApiKey; // Using Google Maps API key for Places API
      });
      print('✅ Google API key loaded: ${_googleApiKey?.substring(0, 10)}...');
    } catch (e) {
      print('❌ Error loading secrets: $e');
    }
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

        // Save location (simplified without ProfileProvider for now)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(userLocation);
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to save location: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
    _updateAddressFromCoordinates(position);
  }

  Future<void> _updateAddressFromCoordinates(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final placemark = placemarks.first;
        final address = [
          placemark.name,
          placemark.locality,
          placemark.administrativeArea,
          placemark.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      print('Error getting address from coordinates: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
      appBar: AppBar(
        title: const Text('Choose Location'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _confirmLocation,
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Address search section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2D30) : AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search for an address:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Google Places Autocomplete
                if (_googleApiKey != null)
                  GooglePlaceAutoCompleteTextField(
                    textEditingController: _addressController,
                    googleAPIKey: _googleApiKey!,
                    inputDecoration: InputDecoration(
                      hintText: 'Enter address',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primaryGreen),
                      ),
                    ),
                    debounceTime: 600,
                    countries: const ["ca"], // Limit to Canada
                    isLatLngRequired: true,
                    getPlaceDetailWithLatLng: (Prediction prediction) {
                      print("Place selected: ${prediction.description}");
                      if (prediction.lat != null && prediction.lng != null) {
                        final newPosition = LatLng(
                          double.parse(prediction.lat!),
                          double.parse(prediction.lng!),
                        );

                        setState(() {
                          _selectedLocation = newPosition;
                          _addressController.text =
                              prediction.description ?? '';
                        });

                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(newPosition, 15.0),
                        );
                      }
                    },
                    itemClick: (Prediction prediction) {
                      _addressController.text = prediction.description ?? '';
                      _addressController.selection = TextSelection.fromPosition(
                        TextPosition(
                          offset: prediction.description?.length ?? 0,
                        ),
                      );
                    },
                    seperatedBuilder: const Divider(),
                    containerHorizontalPadding: 10,
                    itemBuilder: (context, index, Prediction prediction) {
                      return Container(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                prediction.description ?? "",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    isCrossBtnShown: true,
                    boxDecoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2D2D30) : AppColors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  )
                else
                  // Fallback to regular text field if API key not available
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      hintText: 'Enter address',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: _searchAddress,
                              ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primaryGreen),
                      ),
                    ),
                    onSubmitted: (_) => _searchAddress(),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),

          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap on the map or drag the marker to select your location',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryGreen,
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
                  draggable: true,
                  onDragEnd: (LatLng position) {
                    setState(() {
                      _selectedLocation = position;
                    });
                    _updateAddressFromCoordinates(position);
                  },
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),

          // Selected location info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2D30) : AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selected Location',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _confirmLocation(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Confirm Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
