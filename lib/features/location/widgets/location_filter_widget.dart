import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/new_location_provider.dart';

class LocationFilterWidget extends StatefulWidget {
  final VoidCallback? onFilterChanged;

  const LocationFilterWidget({super.key, this.onFilterChanged});

  @override
  State<LocationFilterWidget> createState() => _LocationFilterWidgetState();
}

class _LocationFilterWidgetState extends State<LocationFilterWidget> {
  double _searchRadius = 5.0; // km
  bool _sortByDistance = false;
  bool _showDistanceInCards = true;

  final List<double> _radiusOptions = [1.0, 2.0, 5.0, 10.0, 25.0, 50.0];

  String _getRadiusText(double radius) {
    if (radius < 1) {
      return '${(radius * 1000).toInt()}m';
    } else {
      return '${radius.toInt()}km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.tune,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Location Filters',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const Spacer(),
                  if (locationProvider.currentLocation != null)
                    TextButton.icon(
                      onPressed: () {
                        locationProvider.loadCurrentLocation();
                        widget.onFilterChanged?.call();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Search Radius
              Row(
                children: [
                  const Icon(
                    Icons.radio_button_unchecked,
                    color: AppColors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Search Radius:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  DropdownButton<double>(
                    value: _searchRadius,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _searchRadius = value;
                        });
                        widget.onFilterChanged?.call();
                      }
                    },
                    items:
                        _radiusOptions.map((radius) {
                          return DropdownMenuItem<double>(
                            value: radius,
                            child: Text(_getRadiusText(radius)),
                          );
                        }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Sort by Distance Toggle
              Row(
                children: [
                  const Icon(Icons.sort, color: AppColors.grey, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Sort by Distance',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Switch(
                    value: _sortByDistance,
                    onChanged: (value) {
                      setState(() {
                        _sortByDistance = value;
                      });
                      widget.onFilterChanged?.call();
                    },
                    activeColor: AppColors.primaryGreen,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Show Distance in Cards Toggle
              Row(
                children: [
                  const Icon(Icons.straighten, color: AppColors.grey, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Show Distance on Cards',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Switch(
                    value: _showDistanceInCards,
                    onChanged: (value) {
                      setState(() {
                        _showDistanceInCards = value;
                      });
                      widget.onFilterChanged?.call();
                    },
                    activeColor: AppColors.primaryGreen,
                  ),
                ],
              ),

              if (locationProvider.currentLocation != null) ...[
                const SizedBox(height: 16),

                // Current Location Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.primaryGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Location',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              locationProvider.currentLocation!.address ??
                                  '${locationProvider.currentLocation!.latitude.toStringAsFixed(4)}, ${locationProvider.currentLocation!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (locationProvider.isLoading) ...[
                const SizedBox(height: 16),
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],

              if (locationProvider.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationProvider.error!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Getters for other widgets to access filter values
  double get searchRadius => _searchRadius;
  bool get sortByDistance => _sortByDistance;
  bool get showDistanceInCards => _showDistanceInCards;
}
