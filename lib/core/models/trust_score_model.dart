import 'package:cloud_firestore/cloud_firestore.dart';

enum TrustScoreAction {
  idVerification,
  certificationCompleted,
  successfulExchange,
  positiveReview,
  violation,
  negativeReview,
  accountAging,
  communityContribution,
  profileCompletion,
}

class TrustScoreEntry {
  final String id;
  final String userId;
  final TrustScoreAction action;
  final double points;
  final String description;
  final DateTime timestamp;
  final String? relatedId; // Related exchange, certification, etc.
  final Map<String, dynamic>? metadata;

  const TrustScoreEntry({
    required this.id,
    required this.userId,
    required this.action,
    required this.points,
    required this.description,
    required this.timestamp,
    this.relatedId,
    this.metadata,
  });

  factory TrustScoreEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrustScoreEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      action: TrustScoreAction.values.firstWhere(
        (action) => action.name == data['action'],
        orElse: () => TrustScoreAction.positiveReview,
      ),
      points: (data['points'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      timestamp:
          data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
      relatedId: data['relatedId'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'action': action.name,
      'points': points,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'relatedId': relatedId,
      'metadata': metadata,
    };
  }

  String get actionDisplayName {
    switch (action) {
      case TrustScoreAction.idVerification:
        return 'ID Verification';
      case TrustScoreAction.certificationCompleted:
        return 'Certification Completed';
      case TrustScoreAction.successfulExchange:
        return 'Successful Exchange';
      case TrustScoreAction.positiveReview:
        return 'Positive Review';
      case TrustScoreAction.violation:
        return 'Violation';
      case TrustScoreAction.negativeReview:
        return 'Negative Review';
      case TrustScoreAction.accountAging:
        return 'Account Aging Bonus';
      case TrustScoreAction.communityContribution:
        return 'Community Contribution';
      case TrustScoreAction.profileCompletion:
        return 'Profile Completion';
    }
  }

  bool get isPositive => points > 0;
}

class TrustScoreSummary {
  final double totalScore;
  final int totalEntries;
  final double positivePoints;
  final double negativePoints;
  final int successfulExchanges;
  final int violations;
  final int certifications;
  final bool idVerified;
  final DateTime lastUpdated;
  final Map<TrustScoreAction, int> actionCounts;

  const TrustScoreSummary({
    required this.totalScore,
    required this.totalEntries,
    required this.positivePoints,
    required this.negativePoints,
    required this.successfulExchanges,
    required this.violations,
    required this.certifications,
    required this.idVerified,
    required this.lastUpdated,
    required this.actionCounts,
  });

  factory TrustScoreSummary.fromEntries(
    List<TrustScoreEntry> entries,
    bool idVerified,
  ) {
    double totalScore = 0.0;
    double positivePoints = 0.0;
    double negativePoints = 0.0;
    int successfulExchanges = 0;
    int violations = 0;
    int certifications = 0;
    final Map<TrustScoreAction, int> actionCounts = {};

    for (final entry in entries) {
      totalScore += entry.points;

      if (entry.points > 0) {
        positivePoints += entry.points;
      } else {
        negativePoints += entry.points.abs();
      }

      switch (entry.action) {
        case TrustScoreAction.successfulExchange:
          successfulExchanges++;
          break;
        case TrustScoreAction.violation:
          violations++;
          break;
        case TrustScoreAction.certificationCompleted:
          certifications++;
          break;
        default:
          break;
      }

      actionCounts[entry.action] = (actionCounts[entry.action] ?? 0) + 1;
    }

    return TrustScoreSummary(
      totalScore: totalScore.clamp(0.0, 10.0),
      totalEntries: entries.length,
      positivePoints: positivePoints,
      negativePoints: negativePoints,
      successfulExchanges: successfulExchanges,
      violations: violations,
      certifications: certifications,
      idVerified: idVerified,
      lastUpdated:
          entries.isNotEmpty
              ? entries
                  .map((e) => e.timestamp)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
              : DateTime.now(),
      actionCounts: actionCounts,
    );
  }

  String get trustLevel {
    if (totalScore >= 8.0) return 'Excellent';
    if (totalScore >= 6.0) return 'Good';
    if (totalScore >= 4.0) return 'Fair';
    if (totalScore >= 2.0) return 'Poor';
    return 'New User';
  }

  String get trustLevelColor {
    if (totalScore >= 8.0) return '#4CAF50'; // Green
    if (totalScore >= 6.0) return '#8BC34A'; // Light Green
    if (totalScore >= 4.0) return '#FFC107'; // Amber
    if (totalScore >= 2.0) return '#FF9800'; // Orange
    return '#757575'; // Grey
  }

  double get trustPercentage => (totalScore / 10.0) * 100;

  bool get isReliable => totalScore >= 6.0 && violations < 3;

  bool get needsImprovement => totalScore < 4.0 || violations >= 5;

  List<String> get recommendations {
    final List<String> recommendations = [];

    if (!idVerified) {
      recommendations.add('Complete ID verification to improve trust score');
    }

    if (certifications < 2) {
      recommendations.add('Obtain food safety certifications');
    }

    if (successfulExchanges < 5) {
      recommendations.add('Complete more successful exchanges');
    }

    if (violations > 0) {
      recommendations.add('Avoid violations to maintain trust score');
    }

    if (totalScore < 5.0) {
      recommendations.add('Engage positively with the community');
    }

    return recommendations;
  }
}
