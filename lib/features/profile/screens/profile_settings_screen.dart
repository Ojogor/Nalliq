import 'package:flutter/material.dart';
import 'package:nalliq/features/profile/screens/manage_location_screen.dart';
import 'package:nalliq/features/location/screens/location_privacy_screen.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.location_on_outlined,
                color: Colors.green,
              ),
              title: const Text('Manage Location'),
              subtitle: const Text(
                'Update your address and visibility settings',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageLocationScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Add other profile settings here in the future
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.privacy_tip_outlined,
                color: Colors.green,
              ),
              title: const Text('Location Privacy'),
              subtitle: const Text('Control who can see your location'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationPrivacyScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.notifications_outlined,
                color: Colors.green,
              ),
              title: const Text('Notifications'),
              subtitle: const Text('Manage notification preferences'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Add notification settings
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security_outlined, color: Colors.green),
              title: const Text('General Privacy'),
              subtitle: const Text('Control your privacy settings'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Add privacy settings
              },
            ),
          ),
        ],
      ),
    );
  }
}
