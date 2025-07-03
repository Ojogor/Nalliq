import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/exchange_request_model.dart';

class ProfileProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentUser;
  List<ExchangeRequest> _incomingRequests = [];
  List<ExchangeRequest> _outgoingRequests = [];
  List<AppUser> _friends = [];
  List<ExchangeRequest> _exchangeHistory = [];
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  List<ExchangeRequest> get incomingRequests => _incomingRequests;
  List<ExchangeRequest> get outgoingRequests => _outgoingRequests;
  List<AppUser> get friends => _friends;
  List<ExchangeRequest> get exchangeHistory => _exchangeHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProfileData(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await Future.wait([
        _loadCurrentUser(userId),
        _loadRequests(userId),
        _loadFriends(userId),
        _loadExchangeHistory(userId),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCurrentUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      _currentUser = AppUser.fromFirestore(doc);
    }
  }

  Future<void> _loadRequests(String userId) async {
    // Load incoming requests
    final incomingQuery =
        await _firestore
            .collection('exchange_requests')
            .where('ownerId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .get();

    _incomingRequests =
        incomingQuery.docs
            .map((doc) => ExchangeRequest.fromFirestore(doc))
            .toList();

    // Load outgoing requests
    final outgoingQuery =
        await _firestore
            .collection('exchange_requests')
            .where('requesterId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();

    _outgoingRequests =
        outgoingQuery.docs
            .map((doc) => ExchangeRequest.fromFirestore(doc))
            .toList();
  }

  Future<void> _loadFriends(String userId) async {
    if (_currentUser?.friendIds.isEmpty ?? true) {
      _friends = [];
      return;
    }

    final query =
        await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: _currentUser!.friendIds)
            .get();

    _friends = query.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
  }

  Future<void> _loadExchangeHistory(String userId) async {
    final query =
        await _firestore
            .collection('exchange_requests')
            .where('status', isEqualTo: 'completed')
            .orderBy('completedAt', descending: true)
            .limit(50)
            .get();

    _exchangeHistory =
        query.docs
            .map((doc) => ExchangeRequest.fromFirestore(doc))
            .where(
              (request) =>
                  request.requesterId == userId || request.ownerId == userId,
            )
            .toList();
  }

  Future<bool> updateProfile({
    String? displayName,
    String? bio,
    String? phoneNumber,
  }) async {
    if (_currentUser == null) return false;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      updates['lastActive'] = Timestamp.fromDate(DateTime.now());

      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .update(updates);

      // Update local user
      _currentUser = _currentUser!.copyWith(
        displayName: displayName,
        bio: bio,
        phoneNumber: phoneNumber,
        lastActive: DateTime.now(),
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendFriendRequest(String friendUserId) async {
    if (_currentUser == null) return false;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Add friend to current user's friend list
      final updatedFriendIds = [..._currentUser!.friendIds, friendUserId];

      await _firestore.collection('users').doc(_currentUser!.id).update({
        'friendIds': updatedFriendIds,
      });

      // Add current user to friend's friend list
      final friendDoc =
          await _firestore.collection('users').doc(friendUserId).get();

      if (friendDoc.exists) {
        final friendData = friendDoc.data() as Map<String, dynamic>;
        final friendFriendIds = List<String>.from(
          friendData['friendIds'] ?? [],
        );
        friendFriendIds.add(_currentUser!.id);

        await _firestore.collection('users').doc(friendUserId).update({
          'friendIds': friendFriendIds,
        });
      }

      // Update local data
      _currentUser = _currentUser!.copyWith(friendIds: updatedFriendIds);
      await _loadFriends(_currentUser!.id);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeFriend(String friendUserId) async {
    if (_currentUser == null) return false;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Remove friend from current user's friend list
      final updatedFriendIds =
          _currentUser!.friendIds.where((id) => id != friendUserId).toList();

      await _firestore.collection('users').doc(_currentUser!.id).update({
        'friendIds': updatedFriendIds,
      });

      // Remove current user from friend's friend list
      final friendDoc =
          await _firestore.collection('users').doc(friendUserId).get();

      if (friendDoc.exists) {
        final friendData = friendDoc.data() as Map<String, dynamic>;
        final friendFriendIds =
            List<String>.from(
              friendData['friendIds'] ?? [],
            ).where((id) => id != _currentUser!.id).toList();

        await _firestore.collection('users').doc(friendUserId).update({
          'friendIds': friendFriendIds,
        });
      }

      // Update local data
      _currentUser = _currentUser!.copyWith(friendIds: updatedFriendIds);
      await _loadFriends(_currentUser!.id);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<AppUser>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      final results =
          await _firestore.collection('users').orderBy('displayName').get();

      return results.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .where(
            (user) =>
                user.id != _currentUser?.id &&
                (user.displayName.toLowerCase().contains(query.toLowerCase()) ||
                    user.email.toLowerCase().contains(query.toLowerCase())),
          )
          .toList();
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
