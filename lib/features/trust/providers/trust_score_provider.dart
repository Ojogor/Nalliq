import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/models/trust_score_model.dart';
import '../../../core/models/certification_model.dart';
import '../../../core/models/id_verification_model.dart';
import '../../../core/models/trust_violation_model.dart';

class TrustScoreProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  TrustScoreSummary? _trustSummary;
  List<TrustScoreEntry> _trustEntries = [];
  List<FoodCertification> _certifications = [];
  List<IDVerification> _idVerifications = [];
  List<TrustViolation> _violations = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  TrustScoreSummary? get trustSummary => _trustSummary;
  List<TrustScoreEntry> get trustEntries => _trustEntries;
  List<FoodCertification> get certifications => _certifications;
  List<IDVerification> get idVerifications => _idVerifications;
  List<TrustViolation> get violations => _violations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all trust score data for a user
  Future<void> loadTrustData(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await Future.wait([
        _loadTrustEntries(userId),
        _loadCertifications(userId),
        _loadIDVerifications(userId),
        _loadViolations(userId),
      ]);

      _generateTrustSummary(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTrustEntries(String userId) async {
    final query =
        await _firestore
            .collection('trust_score_entries')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();

    _trustEntries =
        query.docs.map((doc) => TrustScoreEntry.fromFirestore(doc)).toList();
  }

  Future<void> _loadCertifications(String userId) async {
    final query =
        await _firestore
            .collection('food_certifications')
            .where('userId', isEqualTo: userId)
            .orderBy('submittedAt', descending: true)
            .get();

    _certifications =
        query.docs.map((doc) => FoodCertification.fromFirestore(doc)).toList();
  }

  Future<void> _loadIDVerifications(String userId) async {
    final query =
        await _firestore
            .collection('id_verifications')
            .where('userId', isEqualTo: userId)
            .orderBy('submittedAt', descending: true)
            .get();

    _idVerifications =
        query.docs.map((doc) => IDVerification.fromFirestore(doc)).toList();
  }

  Future<void> _loadViolations(String userId) async {
    final query =
        await _firestore
            .collection('trust_violations')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .orderBy('reportedAt', descending: true)
            .get();

    _violations =
        query.docs.map((doc) => TrustViolation.fromFirestore(doc)).toList();
  }

  void _generateTrustSummary(String userId) {
    final bool hasVerifiedID = _idVerifications.any(
      (id) => id.status == IDVerificationStatus.approved,
    );

    // If no trust score entries exist, create an initial profile completion entry
    if (_trustEntries.isEmpty) {
      _createInitialTrustEntries(userId);
    }

    _trustSummary = TrustScoreSummary.fromEntries(_trustEntries, hasVerifiedID);
  }

  Future<void> _createInitialTrustEntries(String userId) async {
    try {
      // Create initial profile completion entry for new users
      final initialEntry = TrustScoreEntry(
        id: '',
        userId: userId,
        action: TrustScoreAction.profileCompletion,
        points: 1.0,
        description: 'Profile created',
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('trust_score_entries')
          .add(initialEntry.toFirestore());

      // Add to local list
      _trustEntries = [initialEntry];

      // Update user's trust score
      await _updateUserTrustScore(userId, 1.0);
    } catch (e) {
      // Silently fail to avoid blocking the UI
      debugPrint('Failed to create initial trust entries: $e');
    }
  }

  // Add trust score entry
  Future<bool> addTrustScoreEntry({
    required String userId,
    required TrustScoreAction action,
    required double points,
    required String description,
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final entry = TrustScoreEntry(
        id: '',
        userId: userId,
        action: action,
        points: points,
        description: description,
        timestamp: DateTime.now(),
        relatedId: relatedId,
        metadata: metadata,
      );

      await _firestore
          .collection('trust_score_entries')
          .add(entry.toFirestore());

      // Update user's trust score
      await _updateUserTrustScore(userId, points);

      // Reload data
      await loadTrustData(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _updateUserTrustScore(String userId, double points) async {
    final userDoc = _firestore.collection('users').doc(userId);
    final userData = await userDoc.get();

    if (userData.exists) {
      final currentScore = userData.data()!['trustScore'] as double? ?? 0.0;
      final newScore = (currentScore + points).clamp(0.0, 10.0);

      await userDoc.update({
        'trustScore': newScore,
        'lastTrustScoreUpdate': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  // Submit ID verification
  Future<bool> submitIDVerification({
    required String userId,
    required IDType idType,
    required XFile frontImage,
    XFile? backImage,
    String? idNumber,
    DateTime? expiryDate,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Upload images
      final frontImageUrl = await _uploadImage(frontImage, 'id_verification');
      String? backImageUrl;
      if (backImage != null) {
        backImageUrl = await _uploadImage(backImage, 'id_verification');
      }

      // Create verification record
      final verification = IDVerification(
        id: '',
        userId: userId,
        idType: idType,
        status: IDVerificationStatus.pending,
        frontImageUrl: frontImageUrl,
        backImageUrl: backImageUrl,
        idNumber: idNumber,
        submittedAt: DateTime.now(),
        expiryDate: expiryDate,
      );

      await _firestore
          .collection('id_verifications')
          .add(verification.toFirestore());

      await loadTrustData(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Submit food certification
  Future<bool> submitFoodCertification({
    required String userId,
    required CertificationType type,
    required XFile certificateImage,
    String? issuer,
    DateTime? issueDate,
    DateTime? expiryDate,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Upload certificate image
      final imageUrl = await _uploadImage(certificateImage, 'certifications');

      // Create certification record
      final certification = FoodCertification(
        id: '',
        userId: userId,
        type: type,
        status: CertificationStatus.pending,
        certificateImageUrl: imageUrl,
        issuer: issuer,
        issueDate: issueDate,
        expiryDate: expiryDate,
        submittedAt: DateTime.now(),
      );

      await _firestore
          .collection('food_certifications')
          .add(certification.toFirestore());

      await loadTrustData(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Report violation
  Future<bool> reportViolation({
    required String userId,
    required String reportedBy,
    required ViolationType type,
    required ViolationSeverity severity,
    required String description,
    String? evidence,
    String? relatedExchangeId,
    String? relatedItemId,
  }) async {
    try {
      final violation = TrustViolation(
        id: '',
        userId: userId,
        reportedBy: reportedBy,
        type: type,
        severity: severity,
        status: ViolationStatus.reported,
        description: description,
        evidence: evidence,
        reportedAt: DateTime.now(),
        relatedExchangeId: relatedExchangeId,
        relatedItemId: relatedItemId,
      );

      await _firestore
          .collection('trust_violations')
          .add(violation.toFirestore());

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Upload image helper
  Future<String> _uploadImage(XFile imageFile, String folder) async {
    final file = File(imageFile.path);
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
    final ref = _storage.ref().child('$folder/$fileName');

    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  // Get available certification types
  List<CertificationType> getAvailableCertificationTypes() {
    return CertificationType.values;
  }

  // Get certification info
  Map<String, String> getCertificationInfo(CertificationType type) {
    final cert = FoodCertification(
      id: '',
      userId: '',
      type: type,
      status: CertificationStatus.pending,
      submittedAt: DateTime.now(),
    );

    return {
      'name': cert.displayName,
      'description': cert.description,
      'points': cert.scorePoints.toString(),
    };
  }

  // Helper methods for UI
  double getCurrentTrustScore() => _trustSummary?.totalScore ?? 0.0;

  String getTrustLevel() => _trustSummary?.trustLevel ?? 'New User';

  bool isIDVerified() => _trustSummary?.idVerified ?? false;

  int getCertificationCount() => _trustSummary?.certifications ?? 0;

  int getViolationCount() => _trustSummary?.violations ?? 0;

  List<String> getRecommendations() => _trustSummary?.recommendations ?? [];

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
