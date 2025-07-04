import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { individual, foodBank, communityMember }

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
  final String? bio;
  final Map<String, dynamic>? location;
  final Map<String, int> stats; // exchanges, donations, etc.

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
    this.bio,
    this.location,
    this.stats = const {},
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
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActive: (data['lastActive'] as Timestamp).toDate(),
      isVerified: data['isVerified'] ?? false,
      bio: data['bio'],
      location: data['location'],
      stats: Map<String, int>.from(data['stats'] ?? {}),
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
      'bio': bio,
      'location': location,
      'stats': stats,
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
    String? bio,
    Map<String, dynamic>? location,
    Map<String, int>? stats,
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
      bio: bio ?? this.bio,
      location: location ?? this.location,
      stats: stats ?? this.stats,
    );
  }
}
