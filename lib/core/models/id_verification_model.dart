import 'package:cloud_firestore/cloud_firestore.dart';

enum IDVerificationStatus { pending, approved, rejected, expired }

enum IDType { driversLicense, passport, nationalId, studentId, other }

class IDVerification {
  final String id;
  final String userId;
  final IDType idType;
  final IDVerificationStatus status;
  final String? frontImageUrl;
  final String? backImageUrl;
  final String? idNumber; // Encrypted/hashed for security
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final String? reviewedBy;
  final double trustScorePoints;
  final DateTime? expiryDate;

  const IDVerification({
    required this.id,
    required this.userId,
    required this.idType,
    required this.status,
    this.frontImageUrl,
    this.backImageUrl,
    this.idNumber,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewNotes,
    this.reviewedBy,
    this.trustScorePoints = 0.0,
    this.expiryDate,
  });

  factory IDVerification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IDVerification(
      id: doc.id,
      userId: data['userId'] ?? '',
      idType: IDType.values.firstWhere(
        (type) => type.name == data['idType'],
        orElse: () => IDType.other,
      ),
      status: IDVerificationStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => IDVerificationStatus.pending,
      ),
      frontImageUrl: data['frontImageUrl'],
      backImageUrl: data['backImageUrl'],
      idNumber: data['idNumber'],
      submittedAt:
          data['submittedAt'] != null
              ? (data['submittedAt'] as Timestamp).toDate()
              : DateTime.now(),
      reviewedAt:
          data['reviewedAt'] != null
              ? (data['reviewedAt'] as Timestamp).toDate()
              : null,
      reviewNotes: data['reviewNotes'],
      reviewedBy: data['reviewedBy'],
      trustScorePoints: (data['trustScorePoints'] ?? 0.0).toDouble(),
      expiryDate:
          data['expiryDate'] != null
              ? (data['expiryDate'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'idType': idType.name,
      'status': status.name,
      'frontImageUrl': frontImageUrl,
      'backImageUrl': backImageUrl,
      'idNumber': idNumber,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewNotes': reviewNotes,
      'reviewedBy': reviewedBy,
      'trustScorePoints': trustScorePoints,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
    };
  }

  String get displayName {
    switch (idType) {
      case IDType.driversLicense:
        return 'Driver\'s License';
      case IDType.passport:
        return 'Passport';
      case IDType.nationalId:
        return 'National ID';
      case IDType.studentId:
        return 'Student ID';
      case IDType.other:
        return 'Other ID';
    }
  }

  double get scorePoints {
    switch (idType) {
      case IDType.passport:
        return 3.0;
      case IDType.driversLicense:
        return 2.5;
      case IDType.nationalId:
        return 2.5;
      case IDType.studentId:
        return 1.5;
      case IDType.other:
        return 1.0;
    }
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  IDVerification copyWith({
    String? id,
    String? userId,
    IDType? idType,
    IDVerificationStatus? status,
    String? frontImageUrl,
    String? backImageUrl,
    String? idNumber,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewNotes,
    String? reviewedBy,
    double? trustScorePoints,
    DateTime? expiryDate,
  }) {
    return IDVerification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      idType: idType ?? this.idType,
      status: status ?? this.status,
      frontImageUrl: frontImageUrl ?? this.frontImageUrl,
      backImageUrl: backImageUrl ?? this.backImageUrl,
      idNumber: idNumber ?? this.idNumber,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      trustScorePoints: trustScorePoints ?? this.trustScorePoints,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}
