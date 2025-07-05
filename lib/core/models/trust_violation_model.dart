import 'package:cloud_firestore/cloud_firestore.dart';

enum ViolationType {
  foodSafety,
  fraudulentActivity,
  inappropriateBehavior,
  spamming,
  fakeProfile,
  noShow,
  qualityMisrepresentation,
  hygieneConcerns,
  expiredFood,
  allergenMislabeling,
  harassment,
  other,
}

enum ViolationSeverity { minor, moderate, severe, critical }

enum ViolationStatus { reported, underReview, validated, dismissed, resolved }

class TrustViolation {
  final String id;
  final String userId; // User who committed the violation
  final String reportedBy; // User who reported the violation
  final ViolationType type;
  final ViolationSeverity severity;
  final ViolationStatus status;
  final String description;
  final String? evidence; // Image URLs, etc.
  final DateTime reportedAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final String? reviewedBy;
  final double trustScorePenalty;
  final bool isActive; // False if resolved/dismissed
  final String? relatedExchangeId;
  final String? relatedItemId;

  const TrustViolation({
    required this.id,
    required this.userId,
    required this.reportedBy,
    required this.type,
    required this.severity,
    required this.status,
    required this.description,
    this.evidence,
    required this.reportedAt,
    this.reviewedAt,
    this.reviewNotes,
    this.reviewedBy,
    this.trustScorePenalty = 0.0,
    this.isActive = true,
    this.relatedExchangeId,
    this.relatedItemId,
  });

  factory TrustViolation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrustViolation(
      id: doc.id,
      userId: data['userId'] ?? '',
      reportedBy: data['reportedBy'] ?? '',
      type: ViolationType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => ViolationType.other,
      ),
      severity: ViolationSeverity.values.firstWhere(
        (severity) => severity.name == data['severity'],
        orElse: () => ViolationSeverity.minor,
      ),
      status: ViolationStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => ViolationStatus.reported,
      ),
      description: data['description'] ?? '',
      evidence: data['evidence'],
      reportedAt:
          data['reportedAt'] != null
              ? (data['reportedAt'] as Timestamp).toDate()
              : DateTime.now(),
      reviewedAt:
          data['reviewedAt'] != null
              ? (data['reviewedAt'] as Timestamp).toDate()
              : null,
      reviewNotes: data['reviewNotes'],
      reviewedBy: data['reviewedBy'],
      trustScorePenalty: (data['trustScorePenalty'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? true,
      relatedExchangeId: data['relatedExchangeId'],
      relatedItemId: data['relatedItemId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'reportedBy': reportedBy,
      'type': type.name,
      'severity': severity.name,
      'status': status.name,
      'description': description,
      'evidence': evidence,
      'reportedAt': Timestamp.fromDate(reportedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewNotes': reviewNotes,
      'reviewedBy': reviewedBy,
      'trustScorePenalty': trustScorePenalty,
      'isActive': isActive,
      'relatedExchangeId': relatedExchangeId,
      'relatedItemId': relatedItemId,
    };
  }

  String get displayName {
    switch (type) {
      case ViolationType.foodSafety:
        return 'Food Safety Violation';
      case ViolationType.fraudulentActivity:
        return 'Fraudulent Activity';
      case ViolationType.inappropriateBehavior:
        return 'Inappropriate Behavior';
      case ViolationType.spamming:
        return 'Spamming';
      case ViolationType.fakeProfile:
        return 'Fake Profile';
      case ViolationType.noShow:
        return 'No Show';
      case ViolationType.qualityMisrepresentation:
        return 'Quality Misrepresentation';
      case ViolationType.hygieneConcerns:
        return 'Hygiene Concerns';
      case ViolationType.expiredFood:
        return 'Expired Food';
      case ViolationType.allergenMislabeling:
        return 'Allergen Mislabeling';
      case ViolationType.harassment:
        return 'Harassment';
      case ViolationType.other:
        return 'Other Violation';
    }
  }

  double get penaltyPoints {
    double basePoints = 0.0;

    // Base penalty by type
    switch (type) {
      case ViolationType.foodSafety:
      case ViolationType.expiredFood:
      case ViolationType.allergenMislabeling:
        basePoints = 3.0;
        break;
      case ViolationType.fraudulentActivity:
      case ViolationType.fakeProfile:
        basePoints = 4.0;
        break;
      case ViolationType.inappropriateBehavior:
      case ViolationType.harassment:
        basePoints = 2.5;
        break;
      case ViolationType.hygieneConcerns:
      case ViolationType.qualityMisrepresentation:
        basePoints = 2.0;
        break;
      case ViolationType.noShow:
        basePoints = 1.5;
        break;
      case ViolationType.spamming:
        basePoints = 1.0;
        break;
      case ViolationType.other:
        basePoints = 1.0;
        break;
    }

    // Multiply by severity
    switch (severity) {
      case ViolationSeverity.minor:
        return basePoints * 0.5;
      case ViolationSeverity.moderate:
        return basePoints * 1.0;
      case ViolationSeverity.severe:
        return basePoints * 1.5;
      case ViolationSeverity.critical:
        return basePoints * 2.0;
    }
  }

  String get severityColor {
    switch (severity) {
      case ViolationSeverity.minor:
        return '#FFA726'; // Orange
      case ViolationSeverity.moderate:
        return '#FF7043'; // Deep Orange
      case ViolationSeverity.severe:
        return '#E53935'; // Red
      case ViolationSeverity.critical:
        return '#B71C1C'; // Dark Red
    }
  }

  TrustViolation copyWith({
    String? id,
    String? userId,
    String? reportedBy,
    ViolationType? type,
    ViolationSeverity? severity,
    ViolationStatus? status,
    String? description,
    String? evidence,
    DateTime? reportedAt,
    DateTime? reviewedAt,
    String? reviewNotes,
    String? reviewedBy,
    double? trustScorePenalty,
    bool? isActive,
    String? relatedExchangeId,
    String? relatedItemId,
  }) {
    return TrustViolation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reportedBy: reportedBy ?? this.reportedBy,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      description: description ?? this.description,
      evidence: evidence ?? this.evidence,
      reportedAt: reportedAt ?? this.reportedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      trustScorePenalty: trustScorePenalty ?? this.trustScorePenalty,
      isActive: isActive ?? this.isActive,
      relatedExchangeId: relatedExchangeId ?? this.relatedExchangeId,
      relatedItemId: relatedItemId ?? this.relatedItemId,
    );
  }
}
