import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/exchange_request_model.dart';
import '../../../core/models/food_item_model.dart';

class ExchangeProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Send a donation request
  Future<bool> sendDonationRequest({
    required List<String> requestedItemIds,
    String? message,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get owner ID from the first item
      if (requestedItemIds.isEmpty) {
        throw Exception('No items selected');
      }

      final itemDoc =
          await _firestore
              .collection('items')
              .doc(requestedItemIds.first)
              .get();
      if (!itemDoc.exists) {
        throw Exception('Item not found');
      }

      final ownerId = itemDoc.data()!['ownerId'] as String;

      final requestId = _uuid.v4();
      final request = ExchangeRequest(
        id: requestId,
        requesterId: currentUser.uid,
        ownerId: ownerId,
        requestedItemIds: requestedItemIds,
        offeredItemIds: [], // Empty for donation
        type: RequestType.donation,
        status: RequestStatus.pending,
        message: message,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('exchange_requests')
          .doc(requestId)
          .set(request.toFirestore());

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send a barter request
  Future<bool> sendBarterRequest({
    required List<String> requestedItemIds,
    required List<String> offeredItemIds,
    String? message,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (requestedItemIds.isEmpty) {
        throw Exception('No items selected');
      }

      if (offeredItemIds.isEmpty) {
        throw Exception('No items offered for barter');
      }

      // Get owner ID from the first item
      final itemDoc =
          await _firestore
              .collection('items')
              .doc(requestedItemIds.first)
              .get();
      if (!itemDoc.exists) {
        throw Exception('Item not found');
      }

      final ownerId = itemDoc.data()!['ownerId'] as String;

      final requestId = _uuid.v4();
      final request = ExchangeRequest(
        id: requestId,
        requesterId: currentUser.uid,
        ownerId: ownerId,
        requestedItemIds: requestedItemIds,
        offeredItemIds: offeredItemIds,
        type: RequestType.barter,
        status: RequestStatus.pending,
        message: message,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('exchange_requests')
          .doc(requestId)
          .set(request.toFirestore());

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get user's available items for barter
  Future<List<FoodItem>> getUserAvailableItems(String userId) async {
    try {
      final query =
          await _firestore
              .collection('items')
              .where('ownerId', isEqualTo: userId)
              .where('status', isEqualTo: 'available')
              .where('isForBarter', isEqualTo: true)
              .get();

      return query.docs.map((doc) => FoodItem.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user items: $e');
      return [];
    }
  }

  /// Respond to a request (accept/decline)
  Future<bool> respondToRequest({
    required String requestId,
    required RequestStatus status,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('exchange_requests').doc(requestId).update({
        'status': status.name,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark request as completed
  Future<bool> completeRequest(String requestId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get the request details first
      final requestDoc =
          await _firestore.collection('exchange_requests').doc(requestId).get();
      if (!requestDoc.exists) {
        throw Exception('Request not found');
      }

      final request = ExchangeRequest.fromFirestore(requestDoc);

      // Update request status
      await _firestore.collection('exchange_requests').doc(requestId).update({
        'status': RequestStatus.completed.name,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Add trust score for both parties if it's a barter
      if (request.type == RequestType.barter) {
        // Add trust score for both requester and owner
        await _updateTrustScoreForCompletion(request.requesterId);
        await _updateTrustScoreForCompletion(request.ownerId);
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

  /// Update trust score for successful exchange completion
  Future<void> _updateTrustScoreForCompletion(String userId) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      final userData = await userDoc.get();

      if (userData.exists) {
        final currentScore = userData.data()!['trustScore'] as double? ?? 0.0;
        final newScore = (currentScore + 0.5).clamp(0.0, 10.0);

        await userDoc.update({
          'trustScore': newScore,
          'lastTrustScoreUpdate': Timestamp.fromDate(DateTime.now()),
        });

        // Log the trust score change
        await _firestore.collection('trust_score_logs').add({
          'userId': userId,
          'scoreChange': 0.5,
          'previousScore': currentScore,
          'newScore': newScore,
          'reason': 'Barter Exchange Completed',
          'timestamp': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      debugPrint('Error updating trust score: $e');
    }
  }

  /// Cancel a request
  Future<bool> cancelRequest(String requestId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('exchange_requests').doc(requestId).update({
        'status': RequestStatus.cancelled.name,
      });

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
