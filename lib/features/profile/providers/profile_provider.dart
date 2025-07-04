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
      print('📊 Loading profile data for user: $userId');
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Add timeout to prevent infinite loading
      await Future.wait([
        _loadCurrentUser(userId).timeout(Duration(seconds: 10)),
        _loadRequests(userId).timeout(Duration(seconds: 10)),
        _loadFriends(userId).timeout(Duration(seconds: 10)),
        _loadExchangeHistory(userId).timeout(Duration(seconds: 10)),
      ]);

      print('✅ Profile data loaded successfully');
    } catch (e) {
      print('❌ Profile data loading error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCurrentUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _currentUser = AppUser.fromFirestore(doc);
        print('✅ Current user loaded: ${_currentUser?.email}');
      } else {
        print('❌ User document not found');
      }
    } catch (e) {
      print('❌ Error loading current user: $e');
    }
  }

  Future<void> _loadRequests(String userId) async {
    try {
      // Load incoming requests - simplified query first
      final incomingQuery =
          await _firestore
              .collection('exchange_requests')
              .where('ownerId', isEqualTo: userId)
              .where('status', isEqualTo: 'pending')
              .get();

      _incomingRequests =
          incomingQuery.docs
              .map((doc) => ExchangeRequest.fromFirestore(doc))
              .toList();

      // Sort locally instead of using orderBy to avoid index requirement
      _incomingRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Load outgoing requests - simplified query
      final outgoingQuery =
          await _firestore
              .collection('exchange_requests')
              .where('requesterId', isEqualTo: userId)
              .get();

      _outgoingRequests =
          outgoingQuery.docs
              .map((doc) => ExchangeRequest.fromFirestore(doc))
              .toList();

      // Sort locally
      _outgoingRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error loading requests: $e');
      _incomingRequests = [];
      _outgoingRequests = [];
    }
  }

  Future<void> _loadFriends(String userId) async {
    try {
      if (_currentUser?.friendIds.isEmpty ?? true) {
        _friends = [];
        print('✅ No friends to load');
        return;
      }

      final query =
          await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: _currentUser!.friendIds)
              .get();

      _friends = query.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
      print('✅ Loaded ${_friends.length} friends');
    } catch (e) {
      print('❌ Error loading friends: $e');
      _friends = [];
    }
  }

  Future<void> _loadExchangeHistory(String userId) async {
    try {
      final query =
          await _firestore
              .collection('exchange_requests')
              .where('status', isEqualTo: 'completed')
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

      // Sort locally by completedAt
      _exchangeHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error loading exchange history: $e');
      _exchangeHistory = [];
    }
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

  /// Update user's trust score
  Future<bool> updateTrustScore(
    String userId,
    double scoreChange,
    String reason,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userDoc = _firestore.collection('users').doc(userId);
      final userData = await userDoc.get();

      if (!userData.exists) {
        throw Exception('User not found');
      }

      final currentScore = userData.data()!['trustScore'] as double? ?? 0.0;
      final newScore = (currentScore + scoreChange).clamp(0.0, 10.0);

      await userDoc.update({
        'trustScore': newScore,
        'lastTrustScoreUpdate': Timestamp.fromDate(DateTime.now()),
      });

      // Log the trust score change
      await _firestore.collection('trust_score_logs').add({
        'userId': userId,
        'scoreChange': scoreChange,
        'previousScore': currentScore,
        'newScore': newScore,
        'reason': reason,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });

      // Update local user data
      if (_currentUser != null && _currentUser!.id == userId) {
        _currentUser = _currentUser!.copyWith(trustScore: newScore);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark ID verification as completed
  Future<bool> completeIDVerification(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'idVerified': true,
        'idVerificationDate': Timestamp.fromDate(DateTime.now()),
      });

      // Add trust score points for ID verification
      await updateTrustScore(userId, 2.0, 'ID Verification Completed');

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Mark food safety QA as completed
  Future<bool> completeFoodSafetyQA(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'foodSafetyQACompleted': true,
        'foodSafetyQADate': Timestamp.fromDate(DateTime.now()),
      });

      // Add trust score points for food safety QA
      await updateTrustScore(userId, 1.5, 'Food Safety QA Completed');

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Add trust score for completed barter
  Future<void> addBarterCompletionScore(String userId) async {
    await updateTrustScore(userId, 0.5, 'Barter Exchange Completed');
  }

  /// Deduct trust score for negative actions
  Future<void> deductTrustScore(
    String userId,
    double amount,
    String reason,
  ) async {
    await updateTrustScore(userId, -amount, reason);
  }
}
