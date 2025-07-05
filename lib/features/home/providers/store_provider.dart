import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/food_item_model.dart';

class StoreProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _storeUser;
  List<FoodItem> _storeItems = [];
  bool _isLoading = false;
  String? _error;
  bool _isFriend = false;
  bool _friendRequestSent = false;
  bool _hasPendingRequestFromStore = false;
  String? _pendingRequestId;

  AppUser? get storeUser => _storeUser;
  List<FoodItem> get storeItems => _storeItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFriend => _isFriend;
  bool get friendRequestSent => _friendRequestSent;
  bool get hasPendingRequestFromStore => _hasPendingRequestFromStore;
  String? get pendingRequestId => _pendingRequestId;

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
        final friendIds = List<String>.from(
          currentUserDoc.data()?['friendIds'] ?? [],
        );
        _isFriend = friendIds.contains(storeUserId);
      }

      // Check for pending friend requests
      final requestQuery =
          await _firestore
              .collection('friend_requests')
              .where('fromUserId', isEqualTo: currentUserId)
              .where('toUserId', isEqualTo: storeUserId)
              .where('status', isEqualTo: 'pending')
              .get();

      if (requestQuery.docs.isNotEmpty) {
        _friendRequestSent = true;
        _pendingRequestId = requestQuery.docs.first.id;
      } else {
        _friendRequestSent = false;
        _pendingRequestId = null;
      }

      final incomingRequestQuery =
          await _firestore
              .collection('friend_requests')
              .where('fromUserId', isEqualTo: storeUserId)
              .where('toUserId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'pending')
              .get();

      if (incomingRequestQuery.docs.isNotEmpty) {
        _hasPendingRequestFromStore = true;
        _pendingRequestId = incomingRequestQuery.docs.first.id;
      } else {
        _hasPendingRequestFromStore = false;
        if (!_friendRequestSent) {
          _pendingRequestId = null;
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

  Future<void> sendFriendRequest(
    String storeUserId,
    String currentUserId,
  ) async {
    try {
      final requestRef = _firestore.collection('friend_requests').doc();
      await requestRef.set({
        'fromUserId': currentUserId,
        'toUserId': storeUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _friendRequestSent = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error sending friend request: $e');
      notifyListeners();
    }
  }

  Future<void> acceptFriendRequest(
    String requestId,
    String storeUserId,
    String currentUserId,
  ) async {
    try {
      // Use a batch write to perform multiple operations atomically
      final batch = _firestore.batch();

      // Update the friend request status
      final requestRef = _firestore
          .collection('friend_requests')
          .doc(requestId);
      batch.update(requestRef, {'status': 'accepted'});

      // Add each user to the other's friend list
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'friendIds': FieldValue.arrayUnion([storeUserId]),
      });

      final storeUserRef = _firestore.collection('users').doc(storeUserId);
      batch.update(storeUserRef, {
        'friendIds': FieldValue.arrayUnion([currentUserId]),
      });

      await batch.commit();

      _isFriend = true;
      _hasPendingRequestFromStore = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error accepting friend request: $e');
      notifyListeners();
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friend_requests').doc(requestId).delete();
      _friendRequestSent = false;
      _hasPendingRequestFromStore = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error cancelling friend request: $e');
      notifyListeners();
    }
  }

  Future<void> removeFriend(String storeUserId, String currentUserId) async {
    try {
      final batch = _firestore.batch();

      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'friendIds': FieldValue.arrayRemove([storeUserId]),
      });

      final storeUserRef = _firestore.collection('users').doc(storeUserId);
      batch.update(storeUserRef, {
        'friendIds': FieldValue.arrayRemove([currentUserId]),
      });

      await batch.commit();

      _isFriend = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error removing friend: $e');
      notifyListeners();
    }
  }

  Future<void> toggleFriend(String storeUserId, String currentUserId) async {
    try {
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      final currentUserDoc = await currentUserRef.get();

      if (!currentUserDoc.exists) return;

      final friendIds = List<String>.from(
        currentUserDoc.data()?['friendIds'] ?? [],
      );

      if (_isFriend) {
        // Remove friend
        friendIds.remove(storeUserId);
        _isFriend = false;
      } else {
        // Add friend
        friendIds.add(storeUserId);
        _isFriend = true;
      }

      await currentUserRef.update({'friendIds': friendIds});
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
    _friendRequestSent = false;
    _hasPendingRequestFromStore = false;
    _pendingRequestId = null;
    notifyListeners();
  }
}
