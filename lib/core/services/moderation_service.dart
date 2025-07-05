import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/user_report_model.dart';

class ModerationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _reportsThreshold = 5;
  static const double _trustScorePenalty = 2.0;

  // Report a user
  static Future<bool> reportUser({
    required String reporterId,
    required String reportedUserId,
    required ReportReason reason,
    required String description,
    String? relatedItemId,
  }) async {
    try {
      // Check if user has already reported this person
      final existingReport =
          await _firestore
              .collection('reports')
              .where('reporterId', isEqualTo: reporterId)
              .where('reportedUserId', isEqualTo: reportedUserId)
              .get();

      if (existingReport.docs.isNotEmpty) {
        throw Exception('You have already reported this user');
      }

      // Create the report
      final report = UserReport(
        id: '',
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        reason: reason,
        description: description,
        createdAt: DateTime.now(),
        relatedItemId: relatedItemId,
      );

      // Add to Firestore
      await _firestore.collection('reports').add(report.toFirestore());

      // Update reported user's report count
      await _updateReportCount(reportedUserId, reporterId);

      return true;
    } catch (e) {
      print('Error reporting user: $e');
      return false;
    }
  }

  // Update report count and check for auto-ban
  static Future<void> _updateReportCount(
    String userId,
    String reporterId,
  ) async {
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final reportCount = (userData['reportCount'] ?? 0) + 1;
      final reportedByUsers = List<String>.from(
        userData['reportedByUsers'] ?? [],
      );

      if (!reportedByUsers.contains(reporterId)) {
        reportedByUsers.add(reporterId);
      }

      final updates = {
        'reportCount': reportCount,
        'reportedByUsers': reportedByUsers,
        'lastReportDate': Timestamp.fromDate(DateTime.now()),
      };

      // Check if user should have trust score penalty
      if (reportCount % _reportsThreshold == 0) {
        final currentTrustScore = (userData['trustScore'] ?? 0.0).toDouble();
        final newTrustScore = currentTrustScore - _trustScorePenalty;

        updates['trustScore'] = newTrustScore;
        updates['lastTrustScoreUpdate'] = Timestamp.fromDate(DateTime.now());

        // Check if user should be auto-banned
        final createdAt =
            userData['createdAt'] != null
                ? (userData['createdAt'] as Timestamp).toDate()
                : DateTime.now();
        final weeksSinceCreation =
            DateTime.now().difference(createdAt).inDays / 7;

        if (newTrustScore <= 0 && weeksSinceCreation >= 1) {
          updates['isBanned'] = true;
          updates['banReason'] =
              'Automatic ban due to low trust score from multiple reports';
          updates['banDate'] = Timestamp.fromDate(DateTime.now());
        }
      }

      transaction.update(userRef, updates);
    });
  }

  // Check if current user can access moderator features
  static bool canAccessModeratorFeatures(AppUser? currentUser) {
    return currentUser?.isModerator == true;
  }

  // Get pending reports for moderators
  static Stream<List<UserReport>> getPendingReports() {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: ReportStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => UserReport.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get reports for a specific user (for moderators)
  static Stream<List<UserReport>> getReportsForUser(String userId) {
    return _firestore
        .collection('reports')
        .where('reportedUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => UserReport.fromFirestore(doc))
                  .toList(),
        );
  }

  // Resolve a report (moderator action)
  static Future<bool> resolveReport({
    required String reportId,
    required String moderatorId,
    required ReportStatus newStatus,
    required String moderatorNotes,
  }) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': newStatus.name,
        'reviewedAt': Timestamp.fromDate(DateTime.now()),
        'reviewedBy': moderatorId,
        'moderatorNotes': moderatorNotes,
      });
      return true;
    } catch (e) {
      print('Error resolving report: $e');
      return false;
    }
  }

  // Ban user manually (moderator action)
  static Future<bool> banUser({
    required String userId,
    required String moderatorId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': true,
        'banReason': reason,
        'banDate': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error banning user: $e');
      return false;
    }
  }

  // Unban user (moderator action)
  static Future<bool> unbanUser({
    required String userId,
    required String moderatorId,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': false,
        'banReason': null,
        'banDate': null,
      });
      return true;
    } catch (e) {
      print('Error unbanning user: $e');
      return false;
    }
  }

  // Adjust trust score (moderator action)
  static Future<bool> adjustTrustScore({
    required String userId,
    required double newScore,
    required String moderatorId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'trustScore': newScore,
        'lastTrustScoreUpdate': Timestamp.fromDate(DateTime.now()),
      });

      // Log the trust score adjustment
      await _firestore.collection('trust_score_logs').add({
        'userId': userId,
        'adjustedBy': moderatorId,
        'newScore': newScore,
        'reason': reason,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error adjusting trust score: $e');
      return false;
    }
  }

  // Check if user should see ban screen
  static bool shouldShowBanScreen(AppUser user) {
    return user.isBanned || user.shouldBeBanned;
  }

  // Get ban message for user
  static String getBanMessage(AppUser user) {
    if (user.isBanned) {
      return user.banReason ??
          'Your account has been suspended. Contact support if you believe this is an error.';
    } else if (user.shouldBeBanned) {
      return 'Sorry, you have been banned from the app due to low trust score. Contact support if this is not the case.';
    }
    return '';
  }
}
