import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/location_provider.dart';

class LocationSettingsScreen extends StatelessWidget {
  const LocationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Settings'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            children: [
              // Location Services Section
              _buildSectionHeader('Location Services'),
              const SizedBox(height: AppDimensions.marginM),

              _buildLocationStatus(context, locationProvider),

              const SizedBox(height: AppDimensions.marginM),

              if (locationProvider.isLocationEnabled) ...[
                _buildLocationInfo(context, locationProvider),
                const SizedBox(height: AppDimensions.marginL),
              ],

              // Search Settings Section
              _buildSectionHeader('Search Settings'),
              const SizedBox(height: AppDimensions.marginM),

              _buildSearchRadiusSetting(context, locationProvider),
              const SizedBox(height: AppDimensions.marginM),

              _buildSortByDistanceSetting(context, locationProvider),
              const SizedBox(height: AppDimensions.marginM),

              _buildShowDistanceSetting(context, locationProvider),
              const SizedBox(height: AppDimensions.marginL),

              // Alert Settings Section
              _buildSectionHeader('Location Alerts'),
              const SizedBox(height: AppDimensions.marginM),

              _buildLocationAlertsSetting(context, locationProvider),
              const SizedBox(height: AppDimensions.marginM),

              if (locationProvider.locationAlertsEnabled) ...[
                _buildAlertRadiusSetting(context, locationProvider),
                const SizedBox(height: AppDimensions.marginM),

                _buildAlertInfo(context),
              ],

              const SizedBox(height: AppDimensions.marginL),

              // Actions Section
              _buildActionsSection(context, locationProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildLocationStatus(
    BuildContext context,
    LocationProvider locationProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  locationProvider.isLocationEnabled
                      ? Icons.location_on
                      : Icons.location_off,
                  color:
                      locationProvider.isLocationEnabled
                          ? AppColors.success
                          : AppColors.error,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Location Services',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: locationProvider.isLocationEnabled,
                  onChanged: (value) {
                    if (value) {
                      _checkPermissionsAndEnable(context, locationProvider);
                    } else {
                      locationProvider.toggleLocationEnabled();
                    }
                  },
                  activeColor: AppColors.primaryGreen,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              locationProvider.isLocationEnabled
                  ? 'Location services are enabled. You can see nearby food items and get location-based alerts.'
                  : 'Location services are disabled. Enable to see nearby items and get alerts.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            if (locationProvider.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locationProvider.error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(
    BuildContext context,
    LocationProvider locationProvider,
  ) {
    if (!locationProvider.hasLocation) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            children: [
              const Icon(
                Icons.location_searching,
                size: 32,
                color: AppColors.grey,
              ),
              const SizedBox(height: 8),
              const Text(
                'Getting your location...',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  locationProvider.updateCurrentLocation();
                },
                child: const Text('Refresh Location'),
              ),
            ],
          ),
        ),
      );
    }

    final position = locationProvider.currentPosition!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.my_location, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Text(
                  'Current Location',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Latitude: ${position.latitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Longitude: ${position.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Accuracy: ±${position.accuracy.toStringAsFixed(0)}m',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                locationProvider.updateCurrentLocation();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Update Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRadiusSetting(
    BuildContext context,
    LocationProvider locationProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.radio_button_unchecked,
                  color: AppColors.primaryGreen,
                ),
                SizedBox(width: 8),
                Text(
                  'Search Radius',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'How far to search for food items',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Current: ${locationProvider.getRadiusText(locationProvider.searchRadius)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DropdownButton<double>(
                  value: locationProvider.searchRadius,
                  onChanged: (value) {
                    if (value != null) {
                      locationProvider.updateSearchRadius(value);
                    }
                  },
                  items:
                      locationProvider.radiusOptions.map((radius) {
                        return DropdownMenuItem<double>(
                          value: radius,
                          child: Text(locationProvider.getRadiusText(radius)),
                        );
                      }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortByDistanceSetting(
    BuildContext context,
    LocationProvider locationProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Row(
          children: [
            const Icon(Icons.sort, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort by Distance',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Show nearest items first',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: locationProvider.sortByDistance,
              onChanged: (value) {
                locationProvider.toggleSortByDistance();
              },
              activeColor: AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowDistanceSetting(
    BuildContext context,
    LocationProvider locationProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Row(
          children: [
            const Icon(Icons.straighten, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Show Distance on Cards',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Display distance to items on food cards',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: locationProvider.showDistanceInCards,
              onChanged: (value) {
                locationProvider.toggleShowDistanceInCards();
              },
              activeColor: AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationAlertsSetting(
    BuildContext context,
    LocationProvider locationProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_active,
              color: AppColors.primaryGreen,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location-based Alerts',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Get notified when new items are available nearby',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: locationProvider.locationAlertsEnabled,
              onChanged: (value) {
                locationProvider.toggleLocationAlerts();
              },
              activeColor: AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertRadiusSetting(
    BuildContext context,
    LocationProvider locationProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primaryGreen,
                ),
                SizedBox(width: 8),
                Text(
                  'Alert Radius',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Get alerts for items within this radius',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Current: ${locationProvider.getRadiusText(locationProvider.alertRadius)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DropdownButton<double>(
                  value: locationProvider.alertRadius,
                  onChanged: (value) {
                    if (value != null) {
                      locationProvider.updateAlertRadius(value);
                    }
                  },
                  items:
                      locationProvider.radiusOptions.map((radius) {
                        return DropdownMenuItem<double>(
                          value: radius,
                          child: Text(locationProvider.getRadiusText(radius)),
                        );
                      }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertInfo(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'You\'ll receive notifications when new food items are posted within your alert radius.',
                style: TextStyle(color: AppColors.primaryGreen, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(
    BuildContext context,
    LocationProvider locationProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.pushNamed('maps');
                },
                icon: const Icon(Icons.map),
                label: const Text('View Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _openAppSettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Location Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkPermissionsAndEnable(
    BuildContext context,
    LocationProvider locationProvider,
  ) async {
    final status = await Permission.location.status;

    if (status.isGranted) {
      locationProvider.toggleLocationEnabled();
    } else if (status.isDenied) {
      final result = await Permission.location.request();
      if (result.isGranted) {
        locationProvider.toggleLocationEnabled();
      } else {
        _showPermissionDeniedDialog(context);
      }
    } else if (status.isPermanentlyDenied) {
      _showPermissionPermanentlyDeniedDialog(context);
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'Location access is required to show nearby food items and provide location-based alerts.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Permission.location.request();
                },
                child: const Text('Grant Permission'),
              ),
            ],
          ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Location Permission Denied'),
            content: const Text(
              'Location permission has been permanently denied. Please enable it in app settings to use location features.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }
}
