import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/user_location.dart';
import 'dart:math';

/// Debug helper to add sample users for testing map functionality
class SampleUserHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add sample users around St. John's, NL for testing
  static Future<void> addSampleUsers() async {
    print('🧪 Adding sample users for testing...');

    final sampleUsers = [
      {
        'id': 'sample_user_1',
        'displayName': 'Sarah Johnson',
        'email': 'sarah@example.com',
        'profilePictureUrl': null,
        'role': 'community',
        'location': _createRandomLocationNearStJohns(0.01), // ~1km offset
      },
      {
        'id': 'sample_user_2',
        'displayName': 'Mike Chen',
        'email': 'mike@example.com',
        'profilePictureUrl': null,
        'role': 'community',
        'location': _createRandomLocationNearStJohns(0.02), // ~2km offset
      },
      {
        'id': 'sample_user_3',
        'displayName': 'Food Bank Central',
        'email': 'foodbank@example.com',
        'profilePictureUrl': null,
        'role': 'foodBank',
        'location': _createRandomLocationNearStJohns(0.015), // ~1.5km offset
      },
      {
        'id': 'sample_user_4',
        'displayName': 'Emma Thompson',
        'email': 'emma@example.com',
        'profilePictureUrl': null,
        'role': 'community',
        'location': _createRandomLocationNearStJohns(0.025), // ~2.5km offset
      },
    ];

    for (final user in sampleUsers) {
      try {
        await _firestore
            .collection('users')
            .doc(user['id'] as String)
            .set(user);
        print('✅ Added sample user: ${user['displayName']}');
      } catch (e) {
        print('❌ Error adding user ${user['displayName']}: $e');
      }
    }

    print('🎉 Sample users added successfully!');
  }

  /// Create a random location near St. John's with given offset
  static Map<String, dynamic> _createRandomLocationNearStJohns(
    double maxOffset,
  ) {
    final random = Random();
    final latOffset = (random.nextDouble() - 0.5) * maxOffset * 2;
    final lngOffset = (random.nextDouble() - 0.5) * maxOffset * 2;

    final baseLocation = UserLocation.defaultLocation;
    final location = UserLocation(
      latitude: baseLocation.latitude + latOffset,
      longitude: baseLocation.longitude + lngOffset,
      address: 'Sample Location, St. John\'s, NL',
      city: 'St. John\'s',
      province: 'Newfoundland and Labrador',
      country: 'Canada',
      isVisible: true,
      lastUpdated: DateTime.now(),
    );

    return location.toJson();
  }

  /// Remove all sample users
  static Future<void> removeSampleUsers() async {
    print('🧹 Removing sample users...');

    final sampleUserIds = [
      'sample_user_1',
      'sample_user_2',
      'sample_user_3',
      'sample_user_4',
    ];

    for (final userId in sampleUserIds) {
      try {
        await _firestore.collection('users').doc(userId).delete();
        print('✅ Removed sample user: $userId');
      } catch (e) {
        print('❌ Error removing user $userId: $e');
      }
    }

    print('🎉 Sample users removed successfully!');
  }
}
