import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { individual, foodBank, communityMember, moderator }

enum TrustLevel { low, medium, high }

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final UserRole role;
  final TrustLevel trustLevel;
  final double trustScore;
  final List<String> friendIds;
  final DateTime createdAt;
  final DateTime lastActive;
  final bool isVerified;
  final bool idVerified;
  final DateTime? idVerificationDate;
  final bool foodSafetyQACompleted;
  final DateTime? foodSafetyQADate;
  final DateTime? lastTrustScoreUpdate;
  final String? bio;
  final Map<String, dynamic>? location;
  final Map<String, int> stats;
  final bool termsAccepted;
  final DateTime? termsAcceptedDate;
  final bool safetyTrainingCompleted;
  final DateTime? safetyTrainingDate;
  final bool isBanned;
  final String? banReason;
  final DateTime? banDate;
  final int reportCount;
  final List<String> reportedByUsers;
  final DateTime? lastReportDate;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.role = UserRole.individual,
    this.trustLevel = TrustLevel.low,
    this.trustScore = 0.0,
    this.friendIds = const [],
    required this.createdAt,
    required this.lastActive,
    this.isVerified = false,
    this.idVerified = false,
    this.idVerificationDate,
    this.foodSafetyQACompleted = false,
    this.foodSafetyQADate,
    this.lastTrustScoreUpdate,
    this.bio,
    this.location,
    this.stats = const {},
    this.termsAccepted = false,
    this.termsAcceptedDate,
    this.safetyTrainingCompleted = false,
    this.safetyTrainingDate,
    this.isBanned = false,
    this.banReason,
    this.banDate,
    this.reportCount = 0,
    this.reportedByUsers = const [],
    this.lastReportDate,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      phoneNumber: data['phoneNumber'],
      role: UserRole.values.firstWhere(
        (role) => role.name == data['role'],
        orElse: () => UserRole.individual,
      ),
      trustLevel: TrustLevel.values.firstWhere(
        (level) => level.name == data['trustLevel'],
        orElse: () => TrustLevel.low,
      ),
      trustScore: (data['trustScore'] ?? 0.0).toDouble(),
      friendIds: List<String>.from(data['friendIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive:
          (data['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: data['isVerified'] ?? false,
      idVerified: data['idVerified'] ?? false,
      idVerificationDate: (data['idVerificationDate'] as Timestamp?)?.toDate(),
      foodSafetyQACompleted: data['foodSafetyQACompleted'] ?? false,
      foodSafetyQADate: (data['foodSafetyQADate'] as Timestamp?)?.toDate(),
      lastTrustScoreUpdate:
          (data['lastTrustScoreUpdate'] as Timestamp?)?.toDate(),
      bio: data['bio'],
      location: data['location'],
      stats: Map<String, int>.from(data['stats'] ?? {}),
      termsAccepted: data['termsAccepted'] ?? false,
      termsAcceptedDate: (data['termsAcceptedDate'] as Timestamp?)?.toDate(),
      safetyTrainingCompleted: data['safetyTrainingCompleted'] ?? false,
      safetyTrainingDate: (data['safetyTrainingDate'] as Timestamp?)?.toDate(),
      isBanned: data['isBanned'] ?? false,
      banReason: data['banReason'],
      banDate: (data['banDate'] as Timestamp?)?.toDate(),
      reportCount: data['reportCount'] ?? 0,
      reportedByUsers: List<String>.from(data['reportedByUsers'] ?? []),
      lastReportDate: (data['lastReportDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'trustLevel': trustLevel.name,
      'trustScore': trustScore,
      'friendIds': friendIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'isVerified': isVerified,
      'idVerified': idVerified,
      'idVerificationDate':
          idVerificationDate != null
              ? Timestamp.fromDate(idVerificationDate!)
              : null,
      'foodSafetyQACompleted': foodSafetyQACompleted,
      'foodSafetyQADate':
          foodSafetyQADate != null
              ? Timestamp.fromDate(foodSafetyQADate!)
              : null,
      'lastTrustScoreUpdate':
          lastTrustScoreUpdate != null
              ? Timestamp.fromDate(lastTrustScoreUpdate!)
              : null,
      'bio': bio,
      'location': location,
      'stats': stats,
      'termsAccepted': termsAccepted,
      'termsAcceptedDate':
          termsAcceptedDate != null
              ? Timestamp.fromDate(termsAcceptedDate!)
              : null,
      'safetyTrainingCompleted': safetyTrainingCompleted,
      'safetyTrainingDate':
          safetyTrainingDate != null
              ? Timestamp.fromDate(safetyTrainingDate!)
              : null,
      'isBanned': isBanned,
      'banReason': banReason,
      'banDate': banDate != null ? Timestamp.fromDate(banDate!) : null,
      'reportCount': reportCount,
      'reportedByUsers': reportedByUsers,
      'lastReportDate':
          lastReportDate != null ? Timestamp.fromDate(lastReportDate!) : null,
    };
  }

  AppUser copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    UserRole? role,
    TrustLevel? trustLevel,
    double? trustScore,
    List<String>? friendIds,
    DateTime? lastActive,
    bool? isVerified,
    bool? idVerified,
    DateTime? idVerificationDate,
    bool? foodSafetyQACompleted,
    DateTime? foodSafetyQADate,
    DateTime? lastTrustScoreUpdate,
    String? bio,
    Map<String, dynamic>? location,
    Map<String, int>? stats,
    bool? termsAccepted,
    DateTime? termsAcceptedDate,
    bool? safetyTrainingCompleted,
    DateTime? safetyTrainingDate,
    bool? isBanned,
    String? banReason,
    DateTime? banDate,
    int? reportCount,
    List<String>? reportedByUsers,
    DateTime? lastReportDate,
  }) {
    return AppUser(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      trustLevel: trustLevel ?? this.trustLevel,
      trustScore: trustScore ?? this.trustScore,
      friendIds: friendIds ?? this.friendIds,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
      isVerified: isVerified ?? this.isVerified,
      idVerified: idVerified ?? this.idVerified,
      idVerificationDate: idVerificationDate ?? this.idVerificationDate,
      foodSafetyQACompleted:
          foodSafetyQACompleted ?? this.foodSafetyQACompleted,
      foodSafetyQADate: foodSafetyQADate ?? this.foodSafetyQADate,
      lastTrustScoreUpdate: lastTrustScoreUpdate ?? this.lastTrustScoreUpdate,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      stats: stats ?? this.stats,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      termsAcceptedDate: termsAcceptedDate ?? this.termsAcceptedDate,
      safetyTrainingCompleted:
          safetyTrainingCompleted ?? this.safetyTrainingCompleted,
      safetyTrainingDate: safetyTrainingDate ?? this.safetyTrainingDate,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      banDate: banDate ?? this.banDate,
      reportCount: reportCount ?? this.reportCount,
      reportedByUsers: reportedByUsers ?? this.reportedByUsers,
      lastReportDate: lastReportDate ?? this.lastReportDate,
    );
  }

  bool get shouldBeBanned {
    final weeksSinceCreation = DateTime.now().difference(createdAt).inDays / 7;
    return trustScore <= 0 && weeksSinceCreation >= 1;
  }

  bool get isModerator => role == UserRole.moderator;

  bool hasBeenReportedBy(String userId) {
    return reportedByUsers.contains(userId);
  }

  int get daysWithLowTrustScore {
    if (lastTrustScoreUpdate == null || trustScore > 0) return 0;
    return DateTime.now().difference(lastTrustScoreUpdate!).inDays;
  }
}
