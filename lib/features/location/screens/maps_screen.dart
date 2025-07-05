import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/food_item_model.dart';
import '../../home/providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/location_filter_widget.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  Future<void> _initializeMap() async {
    final locationProvider = context.read<LocationProvider>();
    final homeProvider = context.read<HomeProvider>();

    // Initialize location if not already done
    if (!locationProvider.hasLocation) {
      await locationProvider.updateCurrentLocation();
    }

    // Load home data to get available items
    final authProvider = context.read<AuthProvider>();
    if (authProvider.appUser != null) {
      await homeProvider.loadHomeData(authProvider.appUser!.id);
    }

    // Create markers for items with location
    _createMarkersForItems();
  }

  void _createMarkersForItems() {
    final homeProvider = context.read<HomeProvider>();
    final locationProvider = context.read<LocationProvider>();

    // Get all available items from all stores
    final allItems = [
      ...homeProvider.communityItems,
      ...homeProvider.friendsItems,
      ...homeProvider.foodBankItems,
    ];

    final filteredItems = locationProvider.filterItemsByLocation(allItems);

    final newMarkers = <Marker>{};

    // Add user location marker if available
    if (locationProvider.hasLocation) {
      final userPosition = locationProvider.currentPosition!;
      newMarkers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(userPosition.latitude, userPosition.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
        ),
      );
    }

    // Add markers for food items
    for (final item in filteredItems) {
      if (item.location != null) {
        final lat = item.location!['lat'] as double?;
        final lng = item.location!['lng'] as double?;

        if (lat != null && lng != null) {
          final distance = locationProvider.getItemDistanceText(item);

          newMarkers.add(
            Marker(
              markerId: MarkerId(item.id),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _getMarkerColor(item.category),
              ),
              infoWindow: InfoWindow(
                title: item.name,
                snippet: '${item.conditionDisplayName} • $distance',
                onTap: () => _onMarkerTapped(item),
              ),
            ),
          );
        }
      }
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  double _getMarkerColor(ItemCategory category) {
    switch (category) {
      case ItemCategory.fruits:
        return BitmapDescriptor.hueRed;
      case ItemCategory.vegetables:
        return BitmapDescriptor.hueGreen;
      case ItemCategory.dairy:
        return BitmapDescriptor.hueYellow;
      case ItemCategory.meat:
        return BitmapDescriptor.hueOrange;
      case ItemCategory.grains:
        return BitmapDescriptor.hueViolet;
      case ItemCategory.beverages:
        return BitmapDescriptor.hueRose;
      case ItemCategory.canned:
        return BitmapDescriptor.hueCyan;
      case ItemCategory.snacks:
        return BitmapDescriptor.hueAzure;
      case ItemCategory.spices:
        return BitmapDescriptor.hueMagenta;
      case ItemCategory.other:
        return BitmapDescriptor.hueAzure;
    }
  }

  void _onMarkerTapped(FoodItem item) {
    context.pushNamed('item-detail', pathParameters: {'itemId': item.id});
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _moveToUserLocation();
  }

  void _moveToUserLocation() {
    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.hasLocation && _mapController != null) {
      final position = locationProvider.currentPosition!;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Food Items'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _moveToUserLocation();
            },
          ),
        ],
      ),
      body: Consumer2<LocationProvider, HomeProvider>(
        builder: (context, locationProvider, homeProvider, child) {
          if (locationProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Getting your location...'),
                ],
              ),
            );
          }

          if (locationProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_off,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    locationProvider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      locationProvider.updateCurrentLocation();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!locationProvider.hasLocation) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_disabled,
                    size: 64,
                    color: AppColors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Location access is required to show nearby items',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    locationProvider.currentPosition!.latitude,
                    locationProvider.currentPosition!.longitude,
                  ),
                  zoom: 14.0,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                onTap: (_) {
                  // Dismiss any open info windows or filters
                  setState(() {
                    _showFilters = false;
                  });
                },
              ),

              // Filter panel
              if (_showFilters)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.white,
                    child: LocationFilterWidget(
                      onFilterChanged: () {
                        _createMarkersForItems();
                      },
                    ),
                  ),
                ),

              // Floating info panel
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.primaryGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Showing ${_markers.length - 1} items within ${locationProvider.getRadiusText(locationProvider.searchRadius)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildLegendItem(
                            BitmapDescriptor.hueBlue,
                            'Your Location',
                          ),
                          const SizedBox(width: 16),
                          _buildLegendItem(
                            BitmapDescriptor.hueRed,
                            'Food Items',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(double hue, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _hueToColor(hue),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _hueToColor(double hue) {
    if (hue == BitmapDescriptor.hueBlue) return Colors.blue;
    if (hue == BitmapDescriptor.hueRed) return Colors.red;
    if (hue == BitmapDescriptor.hueGreen) return Colors.green;
    if (hue == BitmapDescriptor.hueYellow) return Colors.yellow;
    if (hue == BitmapDescriptor.hueOrange) return Colors.orange;
    return Colors.grey;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
