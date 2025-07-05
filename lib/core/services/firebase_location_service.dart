import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../models/user_location.dart';

class FirebaseLocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save user location to Firestore
  static Future<void> updateUserLocation(UserLocation location) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'location': location.toJson(),
      });
    } catch (e) {
      print('Error updating user location: $e');
      throw Exception('Failed to update location');
    }
  }

  // Get user location from Firestore
  static Future<UserLocation?> getUserLocation(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data()?['location'] != null) {
        return UserLocation.fromJson(doc.data()!['location']);
      }
      return UserLocation.defaultLocation;
    } catch (e) {
      print('Error getting user location: $e');
      return UserLocation.defaultLocation;
    }
  }

  // Get current user's location
  static Future<UserLocation?> getCurrentUserLocation() async {
    final user = _auth.currentUser;
    if (user == null) return UserLocation.defaultLocation;
    return getUserLocation(user.uid);
  }

  // Get all users with visible locations
  static Future<List<MapUser>> getAllUsersWithLocations() async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .where('location.isVisible', isEqualTo: true)
              .get();

      List<MapUser> users = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['location'] != null) {
          final location = UserLocation.fromJson(data['location']);
          users.add(
            MapUser(
              id: doc.id,
              name: data['displayName'] ?? 'Unknown User',
              profilePictureUrl: data['profilePictureUrl'],
              location: location,
            ),
          );
        }
      }
      return users;
    } catch (e) {
      print('Error getting users with locations: $e');
      return [];
    }
  }

  // Get a stream of all users with visible locations
  static Stream<List<MapUser>> getNearbyUsersStream() {
    try {
      return _firestore
          .collection('users')
          .where('location.isVisible', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            print(
              '🔥 Firebase stream received ${snapshot.docs.length} user documents',
            );
            List<MapUser> users = [];
            for (var doc in snapshot.docs) {
              final data = doc.data();
              print(
                '👤 Processing user: ${doc.id} - displayName: ${data['displayName']}',
              );
              print('📍 Location data: ${data['location']}');
              if (data['location'] != null) {
                final location = UserLocation.fromJson(data['location']);
                users.add(
                  MapUser(
                    id: doc.id,
                    name: data['displayName'] ?? 'Unknown User',
                    profilePictureUrl: data['profilePictureUrl'],
                    location: location,
                  ),
                );
                print('✅ Added user ${data['displayName']} to map users list');
              } else {
                print('⚠️ User ${doc.id} has no location data');
              }
            }
            print('🎯 Final users list: ${users.length} users');
            return users;
          });
    } catch (e) {
      print('Error getting users stream: $e');
      return Stream.value([]);
    }
  }

  // Initialize user with default location if not set
  static Future<void> initializeUserLocation(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists || doc.data()?['location'] == null) {
        // Create a default location with a random offset
        final random = Random();
        const double offset = 0.05; // Approx 5.5 km radius
        final latOffset = (random.nextDouble() - 0.5) * offset * 2;
        final lngOffset = (random.nextDouble() - 0.5) * offset * 2;

        final defaultLocation = UserLocation.defaultLocation;
        final initialLocation = UserLocation(
          latitude: defaultLocation.latitude + latOffset,
          longitude: defaultLocation.longitude + lngOffset,
          lastUpdated: DateTime.now(),
          isVisible: true,
        );

        await _firestore.collection('users').doc(userId).set({
          'location': initialLocation.toJson(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error initializing user location: $e');
    }
  }

  // Calculate distance between two locations
  static double calculateDistance(
    UserLocation location1,
    UserLocation location2,
  ) {
    return Geolocator.distanceBetween(
          location1.latitude,
          location1.longitude,
          location2.latitude,
          location2.longitude,
        ) /
        1000; // Convert to kilometers
  }
}

class MapUser {
  final String id;
  final String name;
  final String? profilePictureUrl;
  final UserLocation location;

  MapUser({
    required this.id,
    required this.name,
    this.profilePictureUrl,
    required this.location,
  });
}
