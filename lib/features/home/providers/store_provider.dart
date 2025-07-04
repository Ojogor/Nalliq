import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/models/food_item_model.dart';
import '../../../core/models/user_model.dart';

class StoreProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _storeUser;
  List<FoodItem> _storeItems = [];
  bool _isLoading = false;
  String? _error;
  bool _isFriend = false;
  bool _isFriendRequested = false;
  bool _isRequesting = false;
  AppUser? get storeUser => _storeUser;
  List<FoodItem> get storeItems => _storeItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFriend => _isFriend;
  bool get isFriendRequested => _isFriendRequested;
  bool get isRequesting => _isRequesting;

  Future<void> loadStoreProfile(
    String storeUserId,
    String currentUserId,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Load store user data
      final userDoc =
          await _firestore.collection('users').doc(storeUserId).get();
      if (!userDoc.exists) {
        _error = 'Store not found';
        return;
      }

      _storeUser = AppUser.fromFirestore(userDoc);

      // Check if current user is friends with this store
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      if (currentUserDoc.exists) {
        var friendIds = List<String>.from(
          currentUserDoc.data()?['friendIds'] ?? [],
        );
        _isFriendRequested = friendIds.contains(storeUserId);
        if (_isFriendRequested) {
          final storeUserDoc =
              await _firestore.collection('users').doc(storeUserId).get();
          if (storeUserDoc.exists) {
            friendIds = List<String>.from(
              storeUserDoc.data()?['friendIds'] ?? [],
            );
            _isFriend = friendIds.contains(currentUserId);
          }
        } else if (!_isFriendRequested) {
          final storeUserDoc =
              await _firestore.collection('users').doc(storeUserId).get();
          if (storeUserDoc.exists) {
            friendIds = List<String>.from(
              storeUserDoc.data()?['friendIds'] ?? [],
            );
            _isRequesting = friendIds.contains(currentUserId);
          }
        }
      }

      // Load store items
      final itemsQuery =
          await _firestore
              .collection('items')
              .where('ownerId', isEqualTo: storeUserId)
              .where('status', isEqualTo: 'available')
              .orderBy('createdAt', descending: true)
              .get();

      _storeItems =
          itemsQuery.docs.map((doc) => FoodItem.fromFirestore(doc)).toList();

      print(
        'Loaded store profile for ${_storeUser!.displayName} with ${_storeItems.length} items',
      );
    } catch (e) {
      _error = e.toString();
      print('Error loading store profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFriend1(
    String storeUserId,
    String currentUserId,
    String action,
  ) async {
    try {
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      final storeUserRef = _firestore.collection('users').doc(storeUserId);
      final currentUserDoc = await currentUserRef.get();
      final storeUserDoc = await storeUserRef.get();
      if (!currentUserDoc.exists) return;

      final friendIds1 = List<String>.from(
        currentUserDoc.data()?['friendIds'] ?? [],
      );
      final friendIds2 = List<String>.from(
        storeUserDoc.data()?['friendIds'] ?? [],
      );
      if (action == "Confirm") {
        friendIds1.add(storeUserId);
        _isFriend = true;
        _isRequesting = false;
      } else if (action == "Delete") {
        friendIds1.remove(storeUserId);
        friendIds2.remove(currentUserId);
        _isRequesting = false;
      }
      await currentUserRef.update({'friendIds': friendIds1});
      await storeUserRef.update({'friendIds': friendIds2});
      notifyListeners();

      print(
        '${_isFriend ? "Added" : "Removed"} ${_storeUser?.displayName} as friend',
      );
    } catch (e) {
      _error = e.toString();
      print('Error toggling friend: $e');
      notifyListeners();
    }
  }

  Future<void> toggleFriend(String storeUserId, String currentUserId) async {
    try {
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      final storeUserRef = _firestore.collection('users').doc(storeUserId);
      final currentUserDoc = await currentUserRef.get();
      final storeUserDoc = await storeUserRef.get();
      if (!currentUserDoc.exists) return;

      final friendIds1 = List<String>.from(
        currentUserDoc.data()?['friendIds'] ?? [],
      );
      final friendIds2 = List<String>.from(
        storeUserDoc.data()?['friendIds'] ?? [],
      );
      if (_isFriend) {
        // Remove friend
        friendIds1.remove(storeUserId);
        friendIds2.remove(currentUserId);
        _isFriendRequested = false;
        _isFriend = false;
      } else if (_isFriendRequested) {
        // Add friend
        friendIds1.remove(storeUserId);
        _isFriendRequested = false;
      } else if (!_isFriendRequested) {
        friendIds1.add(storeUserId);
        _isFriendRequested = true;
      }

      await currentUserRef.update({'friendIds': friendIds1});
      await storeUserRef.update({'friendIds': friendIds2});
      notifyListeners();

      print(
        '${_isFriend ? "Added" : "Removed"} ${_storeUser?.displayName} as friend',
      );
    } catch (e) {
      _error = e.toString();
      print('Error toggling friend: $e');
      notifyListeners();
    }
  }

  Future<void> refreshStore(String storeUserId, String currentUserId) async {
    await loadStoreProfile(storeUserId, currentUserId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _storeUser = null;
    _storeItems = [];
    _isLoading = false;
    _error = null;
    _isFriend = false;
    notifyListeners();
  }
}
