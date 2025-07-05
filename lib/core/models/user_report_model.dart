import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportReason {
  inappropriateContent,
  scam,
  unsafeFood,
  harassment,
  spam,
  fakeProfile,
  other,
}

enum ReportStatus { pending, reviewed, resolved, dismissed }

class UserReport {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final ReportReason reason;
  final String description;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy; // Moderator ID
  final String? moderatorNotes;
  final String? relatedItemId; // If reporting about a specific food item

  const UserReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.description,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.moderatorNotes,
    this.relatedItemId,
  });

  factory UserReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserReport(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reportedUserId: data['reportedUserId'] ?? '',
      reason: ReportReason.values.firstWhere(
        (reason) => reason.name == data['reason'],
        orElse: () => ReportReason.other,
      ),
      description: data['description'] ?? '',
      status: ReportStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      reviewedAt:
          data['reviewedAt'] != null
              ? (data['reviewedAt'] as Timestamp).toDate()
              : null,
      reviewedBy: data['reviewedBy'],
      moderatorNotes: data['moderatorNotes'],
      relatedItemId: data['relatedItemId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason.name,
      'description': description,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'moderatorNotes': moderatorNotes,
      'relatedItemId': relatedItemId,
    };
  }

  UserReport copyWith({
    ReportStatus? status,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? moderatorNotes,
  }) {
    return UserReport(
      id: id,
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      reason: reason,
      description: description,
      status: status ?? this.status,
      createdAt: createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      moderatorNotes: moderatorNotes ?? this.moderatorNotes,
      relatedItemId: relatedItemId,
    );
  }

  String get reasonDisplayName {
    switch (reason) {
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.scam:
        return 'Scam or Fraud';
      case ReportReason.unsafeFood:
        return 'Unsafe Food Item';
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.fakeProfile:
        return 'Fake Profile';
      case ReportReason.other:
        return 'Other';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending Review';
      case ReportStatus.reviewed:
        return 'Under Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Dismissed';
    }
  }
}
