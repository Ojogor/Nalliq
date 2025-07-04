import 'package:cloud_firestore/cloud_firestore.dart';

enum CertificationType {
  foodHandling1,
  foodHandling2,
  allergenAwareness,
  temperatureControl,
  hygienePractices,
  foodStorageSafety,
}

enum CertificationStatus { pending, approved, rejected, expired }

class FoodCertification {
  final String id;
  final String userId;
  final CertificationType type;
  final CertificationStatus status;
  final String? certificateImageUrl;
  final String? issuer;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final String? reviewedBy;
  final double trustScorePoints;

  const FoodCertification({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    this.certificateImageUrl,
    this.issuer,
    this.issueDate,
    this.expiryDate,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewNotes,
    this.reviewedBy,
    this.trustScorePoints = 0.0,
  });

  factory FoodCertification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodCertification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: CertificationType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => CertificationType.foodHandling1,
      ),
      status: CertificationStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => CertificationStatus.pending,
      ),
      certificateImageUrl: data['certificateImageUrl'],
      issuer: data['issuer'],
      issueDate:
          data['issueDate'] != null
              ? (data['issueDate'] as Timestamp).toDate()
              : null,
      expiryDate:
          data['expiryDate'] != null
              ? (data['expiryDate'] as Timestamp).toDate()
              : null,
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      reviewedAt:
          data['reviewedAt'] != null
              ? (data['reviewedAt'] as Timestamp).toDate()
              : null,
      reviewNotes: data['reviewNotes'],
      reviewedBy: data['reviewedBy'],
      trustScorePoints: (data['trustScorePoints'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'status': status.name,
      'certificateImageUrl': certificateImageUrl,
      'issuer': issuer,
      'issueDate': issueDate != null ? Timestamp.fromDate(issueDate!) : null,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewNotes': reviewNotes,
      'reviewedBy': reviewedBy,
      'trustScorePoints': trustScorePoints,
    };
  }

  String get displayName {
    switch (type) {
      case CertificationType.foodHandling1:
        return 'Food Handling Level 1';
      case CertificationType.foodHandling2:
        return 'Food Handling Level 2';
      case CertificationType.allergenAwareness:
        return 'Allergen Awareness';
      case CertificationType.temperatureControl:
        return 'Temperature Control';
      case CertificationType.hygienePractices:
        return 'Hygiene Practices';
      case CertificationType.foodStorageSafety:
        return 'Food Storage Safety';
    }
  }

  String get description {
    switch (type) {
      case CertificationType.foodHandling1:
        return 'Basic food handling and safety practices';
      case CertificationType.foodHandling2:
        return 'Advanced food handling and management';
      case CertificationType.allergenAwareness:
        return 'Allergen identification and management';
      case CertificationType.temperatureControl:
        return 'Proper temperature monitoring and control';
      case CertificationType.hygienePractices:
        return 'Personal and workplace hygiene standards';
      case CertificationType.foodStorageSafety:
        return 'Safe food storage and preservation methods';
    }
  }

  double get scorePoints {
    switch (type) {
      case CertificationType.foodHandling1:
        return 2.0;
      case CertificationType.foodHandling2:
        return 3.0;
      case CertificationType.allergenAwareness:
        return 1.5;
      case CertificationType.temperatureControl:
        return 1.5;
      case CertificationType.hygienePractices:
        return 1.0;
      case CertificationType.foodStorageSafety:
        return 1.0;
    }
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  FoodCertification copyWith({
    String? id,
    String? userId,
    CertificationType? type,
    CertificationStatus? status,
    String? certificateImageUrl,
    String? issuer,
    DateTime? issueDate,
    DateTime? expiryDate,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewNotes,
    String? reviewedBy,
    double? trustScorePoints,
  }) {
    return FoodCertification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      certificateImageUrl: certificateImageUrl ?? this.certificateImageUrl,
      issuer: issuer ?? this.issuer,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      trustScorePoints: trustScorePoints ?? this.trustScorePoints,
    );
  }
}
