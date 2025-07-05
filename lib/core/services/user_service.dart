import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/user_model.dart';
import '../models/map_user.dart';
import '../services/location_service.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static CollectionReference get _usersCollection =>
      _firestore.collection('users');

  /// Get current user's document
  static Future<AppUser?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      final doc = await _usersCollection.doc(currentUser.uid).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
    return null;
  }

  /// Update user's location in Firebase
  static Future<bool> updateUserLocation({
    required String userId,
    required LatLng coordinates,
    required String address,
    required bool isVisible,
  }) async {
    try {
      final locationData = {
        'lat': coordinates.latitude,
        'lng': coordinates.longitude,
        'address': address,
        'isVisible': isVisible,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _usersCollection.doc(userId).update({'location': locationData});

      return true;
    } catch (e) {
      print('Error updating user location: $e');
      return false;
    }
  }

  /// Get nearby users within a radius (in kilometers)
  static Future<List<MapUser>> getNearbyUsers({
    required LatLng centerPoint,
    double radiusKm = 50.0,
    String? excludeUserId,
  }) async {
    try {
      // Get all users with visible locations
      final snapshot =
          await _usersCollection
              .where('location.isVisible', isEqualTo: true)
              .get();

      final List<MapUser> nearbyUsers = [];

      for (var doc in snapshot.docs) {
        final user = AppUser.fromFirestore(doc);

        // Skip current user
        if (excludeUserId != null && user.id == excludeUserId) continue;

        // Check if user has location data
        if (user.location != null) {
          final userLat = user.location!['lat'] as double?;
          final userLng = user.location!['lng'] as double?;

          if (userLat != null && userLng != null) {
            final userLocation = LatLng(userLat, userLng);
            final distance = LocationService.calculateDistance(
              centerPoint.latitude,
              centerPoint.longitude,
              userLocation.latitude,
              userLocation.longitude,
            );

            // Only include users within the specified radius
            if (distance <= radiusKm) {
              nearbyUsers.add(
                MapUser(
                  id: user.id,
                  name: user.displayName,
                  profileImageUrl:
                      user.photoUrl ?? 'https://via.placeholder.com/100',
                  location: userLocation,
                  isLocationVisible: true,
                  distanceFromCurrentUser: distance,
                ),
              );
            }
          }
        }
      }

      // Sort by distance
      nearbyUsers.sort(
        (a, b) => (a.distanceFromCurrentUser ?? 0).compareTo(
          b.distanceFromCurrentUser ?? 0,
        ),
      );

      return nearbyUsers;
    } catch (e) {
      print('Error getting nearby users: $e');
      return [];
    }
  }

  /// Update user's location visibility
  static Future<bool> updateLocationVisibility({
    required String userId,
    required bool isVisible,
  }) async {
    try {
      await _usersCollection.doc(userId).update({
        'location.isVisible': isVisible,
        'location.updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating location visibility: $e');
      return false;
    }
  }

  /// Get user by ID
  static Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
    } catch (e) {
      print('Error getting user by ID: $e');
    }
    return null;
  }

  /// Stream nearby users in real-time
  static Stream<List<MapUser>> streamNearbyUsers({
    required LatLng centerPoint,
    double radiusKm = 50.0,
    String? excludeUserId,
  }) {
    return _usersCollection
        .where('location.isVisible', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final List<MapUser> nearbyUsers = [];

          for (var doc in snapshot.docs) {
            final user = AppUser.fromFirestore(doc);

            // Skip current user
            if (excludeUserId != null && user.id == excludeUserId) continue;

            // Check if user has location data
            if (user.location != null) {
              final userLat = user.location!['lat'] as double?;
              final userLng = user.location!['lng'] as double?;

              if (userLat != null && userLng != null) {
                final userLocation = LatLng(userLat, userLng);
                final distance = LocationService.calculateDistance(
                  centerPoint.latitude,
                  centerPoint.longitude,
                  userLocation.latitude,
                  userLocation.longitude,
                );

                // Only include users within the specified radius
                if (distance <= radiusKm) {
                  nearbyUsers.add(
                    MapUser(
                      id: user.id,
                      name: user.displayName,
                      profileImageUrl:
                          user.photoUrl ?? 'https://via.placeholder.com/100',
                      location: userLocation,
                      isLocationVisible: true,
                      distanceFromCurrentUser: distance,
                    ),
                  );
                }
              }
            }
          }

          // Sort by distance
          nearbyUsers.sort(
            (a, b) => (a.distanceFromCurrentUser ?? 0).compareTo(
              b.distanceFromCurrentUser ?? 0,
            ),
          );

          return nearbyUsers;
        });
  }

  /// Update user's last active timestamp
  static Future<void> updateLastActive(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last active: $e');
    }
  }
}
