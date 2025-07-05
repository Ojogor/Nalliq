import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/location_update_service.dart';

class LocationPrivacyScreen extends StatefulWidget {
  const LocationPrivacyScreen({super.key});

  @override
  State<LocationPrivacyScreen> createState() => _LocationPrivacyScreenState();
}

class _LocationPrivacyScreenState extends State<LocationPrivacyScreen> {
  bool _shareLocation = false;
  bool _allowRealTimeTracking = false;
  bool _showOnMap = false;
  bool _shareWithFriends = false;
  bool _shareWithCommunity = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final user = await UserService.getCurrentUser();
      if (user != null && user.location != null) {
        setState(() {
          _shareLocation = user.location!['isVisible'] as bool? ?? false;
          _showOnMap = _shareLocation;
          _shareWithFriends =
              true; // Default values, you might want to store these separately
          _shareWithCommunity = _shareLocation;
          _allowRealTimeTracking = LocationUpdateService.isTracking;
        });
      }
    } catch (e) {
      print('Error loading privacy settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLocationSharing(bool value) async {
    setState(() {
      _shareLocation = value;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await UserService.updateLocationVisibility(
          userId: currentUser.uid,
          isVisible: value,
        );

        if (value && _allowRealTimeTracking) {
          await LocationUpdateService.startLocationTracking();
        } else {
          LocationUpdateService.stopLocationTracking();
        }
      }
    } catch (e) {
      print('Error updating location sharing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update location settings'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _shareLocation = !value; // Revert on error
      });
    }
  }

  Future<void> _updateRealTimeTracking(bool value) async {
    setState(() {
      _allowRealTimeTracking = value;
    });

    try {
      if (value && _shareLocation) {
        await LocationUpdateService.startLocationTracking();
      } else {
        LocationUpdateService.stopLocationTracking();
      }
    } catch (e) {
      print('Error updating real-time tracking: $e');
      setState(() {
        _allowRealTimeTracking = !value; // Revert on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Location Privacy'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Privacy'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location Sharing',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Control who can see your location and when',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Share my location'),
                    subtitle: const Text('Allow others to see where you are'),
                    value: _shareLocation,
                    onChanged: _updateLocationSharing,
                  ),
                  if (_shareLocation) ...[
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Show on community map'),
                      subtitle: const Text(
                        'Appear on the main map for all users',
                      ),
                      value: _showOnMap,
                      onChanged: (value) {
                        setState(() {
                          _showOnMap = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Share with friends'),
                      subtitle: const Text(
                        'Your friends can see your location',
                      ),
                      value: _shareWithFriends,
                      onChanged: (value) {
                        setState(() {
                          _shareWithFriends = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Share with community'),
                      subtitle: const Text(
                        'Community members can see your location',
                      ),
                      value: _shareWithCommunity,
                      onChanged: (value) {
                        setState(() {
                          _shareWithCommunity = value;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Real-time Updates',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Automatically update your location when you move',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Real-time location tracking'),
                    subtitle: const Text(
                      'Updates your location automatically when you move\n'
                      '(Uses GPS in background)',
                    ),
                    value: _allowRealTimeTracking,
                    onChanged: _shareLocation ? _updateRealTimeTracking : null,
                  ),
                  if (_allowRealTimeTracking) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Battery Usage'),
                      subtitle: const Text(
                        'Real-time tracking may affect battery life. '
                        'Location is updated every 50 meters or 5 minutes.',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy Notice',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Your location is only shared with users you choose\n'
                    '• You can turn off location sharing at any time\n'
                    '• Location data is encrypted and securely stored\n'
                    '• You control who can see your location information',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Clear Location Data'),
                              content: const Text(
                                'This will remove your current location from our servers. '
                                'You will not appear on the map until you set a new location.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // TODO: Implement clear location data
                                  },
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear Location Data'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
