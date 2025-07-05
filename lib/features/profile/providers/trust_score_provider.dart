import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_model.dart';

enum TrustScoreAction {
  idVerification,
  completedBarter,
  completedDonation,
  foodSafetyQA,
  positiveReview,
  negativeReview,
  reportedMisconduct,
  failedExchange,
}

class TrustScoreProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _error;
  AppUser? _currentUser;

  bool get isLoading => _isLoading;
  String? get error => _error;
  AppUser? get currentUser => _currentUser;

  static const Map<TrustScoreAction, double> _actionScores = {
    TrustScoreAction.idVerification: 5.0,
    TrustScoreAction.completedBarter: 2.0,
    TrustScoreAction.completedDonation: 1.5,
    TrustScoreAction.foodSafetyQA: 3.0,
    TrustScoreAction.positiveReview: 1.0,
    TrustScoreAction.negativeReview: -2.0,
    TrustScoreAction.reportedMisconduct: -5.0,
    TrustScoreAction.failedExchange: -1.0,
  };

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _currentUser = null;
        return;
      }

      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        _currentUser = AppUser.fromFirestore(userDoc);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTrustScore(
    TrustScoreAction action, {
    String? reason,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final scoreChange = _actionScores[action] ?? 0.0;
      final newScore = (_currentUser?.trustScore ?? 0.0) + scoreChange;

      // Ensure score doesn't go below 0
      final finalScore = newScore < 0 ? 0.0 : newScore;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'trustScore': finalScore,
      });

      // Log the trust score change
      await _logTrustScoreChange(
        userId: currentUser.uid,
        action: action,
        scoreChange: scoreChange,
        newScore: finalScore,
        reason: reason,
      );

      // Update local user
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(trustScore: finalScore);
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

  Future<void> _logTrustScoreChange({
    required String userId,
    required TrustScoreAction action,
    required double scoreChange,
    required double newScore,
    String? reason,
  }) async {
    await _firestore.collection('trust_score_history').add({
      'userId': userId,
      'action': action.name,
      'scoreChange': scoreChange,
      'newScore': newScore,
      'reason': reason,
      'timestamp': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<List<Map<String, dynamic>>> getTrustScoreHistory(String userId) async {
    try {
      final query =
          await _firestore
              .collection('trust_score_history')
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .limit(20)
              .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'action': data['action'],
          'scoreChange': data['scoreChange'],
          'newScore': data['newScore'],
          'reason': data['reason'],
          'timestamp':
              data['timestamp'] != null
                  ? (data['timestamp'] as Timestamp).toDate()
                  : DateTime.now(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading trust score history: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> getTrustImprovementOptions() {
    return [
      {
        'title': 'Verify Your Identity',
        'description': 'Upload government ID for verification',
        'action': TrustScoreAction.idVerification,
        'points': _actionScores[TrustScoreAction.idVerification],
        'icon': Icons.verified_user,
        'available': _currentUser?.isVerified != true,
      },
      {
        'title': 'Complete Food Safety Quiz',
        'description': 'Learn about food safety and handling',
        'action': TrustScoreAction.foodSafetyQA,
        'points': _actionScores[TrustScoreAction.foodSafetyQA],
        'icon': Icons.quiz,
        'available': true,
      },
      {
        'title': 'Complete Exchanges',
        'description': 'Participate in barter and donation exchanges',
        'action': TrustScoreAction.completedBarter,
        'points': _actionScores[TrustScoreAction.completedBarter],
        'icon': Icons.swap_horiz,
        'available': true,
      },
    ];
  }

  String getTrustScoreLabel(double score) {
    if (score >= 20) return 'Excellent';
    if (score >= 15) return 'Very Good';
    if (score >= 10) return 'Good';
    if (score >= 5) return 'Fair';
    return 'New User';
  }

  Color getTrustScoreColor(double score) {
    if (score >= 20) return Colors.green.shade700;
    if (score >= 15) return Colors.green;
    if (score >= 10) return Colors.orange;
    if (score >= 5) return Colors.amber;
    return Colors.grey;
  }
}
