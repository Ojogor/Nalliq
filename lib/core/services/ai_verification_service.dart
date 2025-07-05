import 'dart:io';
import 'package:flutter/material.dart';
import '../models/food_item_model.dart';
import '../models/user_model.dart';

enum AIVerificationResult { passed, failed, needsHumanReview, error }

class AIVerification {
  final AIVerificationResult result;
  final double confidence;
  final String message;
  final List<String> issues;
  final List<String> recommendations;

  const AIVerification({
    required this.result,
    required this.confidence,
    required this.message,
    this.issues = const [],
    this.recommendations = const [],
  });
}

class AIVerificationService {
  // Simulate AI analysis for now - would integrate with actual AI service
  static Future<AIVerification> verifyCanIntegrity(File imageFile) async {
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));

    // Simulate AI analysis
    final random = DateTime.now().millisecondsSinceEpoch;
    final confidence = 0.7 + (random % 30) / 100; // 70-99% confidence

    // Simple mock analysis based on file size/name for demo
    final fileName = imageFile.path.toLowerCase();
    List<String> issues = [];
    List<String> recommendations = [];

    if (fileName.contains('opened') || fileName.contains('damaged')) {
      issues.add('Container appears to be opened or damaged');
      recommendations.add('Do not share opened containers');
      return AIVerification(
        result: AIVerificationResult.failed,
        confidence: confidence,
        message: 'Opened or damaged container detected',
        issues: issues,
        recommendations: recommendations,
      );
    }

    if (fileName.contains('unclear') || fileName.contains('blurry')) {
      return AIVerification(
        result: AIVerificationResult.needsHumanReview,
        confidence: 0.3,
        message: 'Image quality too low for automatic verification',
        recommendations: [
          'Please take a clearer photo',
          'Ensure good lighting',
        ],
      );
    }

    // Mock positive result
    return AIVerification(
      result: AIVerificationResult.passed,
      confidence: confidence,
      message: 'Container appears sealed and intact',
      recommendations: ['Item looks safe for sharing'],
    );
  }

  static Future<AIVerification> verifyExpirationDate(File imageFile) async {
    await Future.delayed(const Duration(seconds: 1));

    // Mock expiration date verification
    final random = DateTime.now().millisecondsSinceEpoch;
    final confidence = 0.6 + (random % 35) / 100;

    final fileName = imageFile.path.toLowerCase();

    if (fileName.contains('expired') || fileName.contains('old')) {
      return AIVerification(
        result: AIVerificationResult.failed,
        confidence: confidence,
        message: 'Item appears to be expired',
        issues: ['Expiration date has passed'],
        recommendations: ['Do not share expired items'],
      );
    }

    if (fileName.contains('soon') || fileName.contains('near')) {
      return AIVerification(
        result: AIVerificationResult.needsHumanReview,
        confidence: confidence,
        message: 'Item expires soon - verify date manually',
        recommendations: [
          'Check expiration date carefully',
          'Consider sharing urgently',
        ],
      );
    }

    return AIVerification(
      result: AIVerificationResult.passed,
      confidence: confidence,
      message: 'Expiration date appears valid',
    );
  }

  static Future<AIVerification> verifyPackagingIntegrity(
    List<File> images,
  ) async {
    await Future.delayed(const Duration(seconds: 3));

    List<String> issues = [];
    List<String> recommendations = [];
    double totalConfidence = 0;
    int passedChecks = 0;

    for (final image in images) {
      final result = await verifyCanIntegrity(image);
      totalConfidence += result.confidence;

      if (result.result == AIVerificationResult.passed) {
        passedChecks++;
      } else {
        issues.addAll(result.issues);
      }
    }

    final averageConfidence = totalConfidence / images.length;
    final passRate = passedChecks / images.length;

    if (passRate >= 0.8 && averageConfidence >= 0.7) {
      return AIVerification(
        result: AIVerificationResult.passed,
        confidence: averageConfidence,
        message: 'All packaging appears intact and safe',
        recommendations: ['Item appears safe for sharing'],
      );
    } else if (passRate >= 0.5) {
      return AIVerification(
        result: AIVerificationResult.needsHumanReview,
        confidence: averageConfidence,
        message: 'Some packaging concerns detected',
        issues: issues,
        recommendations: [
          'Manual review recommended',
          'Check all packaging carefully',
          ...recommendations,
        ],
      );
    } else {
      return AIVerification(
        result: AIVerificationResult.failed,
        confidence: averageConfidence,
        message: 'Multiple packaging integrity issues detected',
        issues: issues,
        recommendations: [
          'Do not share these items',
          'Items may be unsafe',
          ...recommendations,
        ],
      );
    }
  }

  static Future<AIVerification> verifyItemSafety(
    ItemCategory category,
    UserRole userRole,
    List<File> images,
  ) async {
    List<AIVerification> verifications = [];

    // Basic packaging check
    final packagingCheck = await verifyPackagingIntegrity(images);
    verifications.add(packagingCheck);

    // Category-specific checks
    if (category == ItemCategory.canned) {
      // Check for dents, rust, or damage on cans
      final canCheck = await _verifyCannedGoods(images);
      verifications.add(canCheck);
    }

    if (category == ItemCategory.dairy || category == ItemCategory.meat) {
      // Check for proper packaging and sealing
      final temperatureCheck = await _verifyTemperatureSensitiveItems(images);
      verifications.add(temperatureCheck);
    }

    // Role-specific restrictions
    if (userRole == UserRole.communityMember) {
      final roleCheck = await _verifyCommunityMemberRestrictions(
        category,
        images,
      );
      verifications.add(roleCheck);
    }

    return _combineVerificationResults(verifications);
  }

  static Future<AIVerification> _verifyCannedGoods(List<File> images) async {
    await Future.delayed(const Duration(seconds: 1));

    // Mock can-specific verification
    return AIVerification(
      result: AIVerificationResult.passed,
      confidence: 0.85,
      message: 'Can appears undamaged and properly sealed',
      recommendations: ['Check for any dents or rust before consuming'],
    );
  }

  static Future<AIVerification> _verifyTemperatureSensitiveItems(
    List<File> images,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    return AIVerification(
      result: AIVerificationResult.needsHumanReview,
      confidence: 0.6,
      message: 'Temperature-sensitive item requires manual verification',
      recommendations: [
        'Verify proper refrigeration has been maintained',
        'Check for signs of spoilage',
        'Ensure cold chain integrity',
      ],
    );
  }

  static Future<AIVerification> _verifyCommunityMemberRestrictions(
    ItemCategory category,
    List<File> images,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    // Check if community member is trying to share restricted items
    final restrictedCategories = [
      ItemCategory.meat,
      ItemCategory.dairy,
      ItemCategory.fruits,
      ItemCategory.vegetables,
    ];

    if (restrictedCategories.contains(category)) {
      return AIVerification(
        result: AIVerificationResult.failed,
        confidence: 1.0,
        message: 'Community members cannot share this item type',
        issues: ['Item category not allowed for community members'],
        recommendations: [
          'Only share packaged, shelf-stable items',
          'Upgrade account status to share fresh items',
        ],
      );
    }

    return AIVerification(
      result: AIVerificationResult.passed,
      confidence: 0.9,
      message: 'Item type allowed for community members',
    );
  }

  static AIVerification _combineVerificationResults(
    List<AIVerification> results,
  ) {
    if (results.isEmpty) {
      return AIVerification(
        result: AIVerificationResult.error,
        confidence: 0.0,
        message: 'No verification results available',
      );
    }

    // Check if any verification failed
    final failedResults = results.where(
      (r) => r.result == AIVerificationResult.failed,
    );
    if (failedResults.isNotEmpty) {
      final issues = failedResults.expand((r) => r.issues).toList();
      final recommendations =
          failedResults.expand((r) => r.recommendations).toList();

      return AIVerification(
        result: AIVerificationResult.failed,
        confidence:
            failedResults.map((r) => r.confidence).reduce((a, b) => a + b) /
            failedResults.length,
        message: 'Item failed safety verification',
        issues: issues,
        recommendations: recommendations,
      );
    }

    // Check if any need human review
    final reviewResults = results.where(
      (r) => r.result == AIVerificationResult.needsHumanReview,
    );
    if (reviewResults.isNotEmpty) {
      final recommendations =
          reviewResults.expand((r) => r.recommendations).toList();

      return AIVerification(
        result: AIVerificationResult.needsHumanReview,
        confidence:
            results.map((r) => r.confidence).reduce((a, b) => a + b) /
            results.length,
        message: 'Manual review required for safety verification',
        recommendations: recommendations,
      );
    }

    // All passed
    final averageConfidence =
        results.map((r) => r.confidence).reduce((a, b) => a + b) /
        results.length;
    return AIVerification(
      result: AIVerificationResult.passed,
      confidence: averageConfidence,
      message: 'Item passed all safety verifications',
      recommendations: ['Item appears safe for sharing'],
    );
  }

  // Get color for verification result display
  static Color getResultColor(AIVerificationResult result) {
    switch (result) {
      case AIVerificationResult.passed:
        return Colors.green;
      case AIVerificationResult.failed:
        return Colors.red;
      case AIVerificationResult.needsHumanReview:
        return Colors.orange;
      case AIVerificationResult.error:
        return Colors.grey;
    }
  }

  // Get icon for verification result
  static IconData getResultIcon(AIVerificationResult result) {
    switch (result) {
      case AIVerificationResult.passed:
        return Icons.check_circle;
      case AIVerificationResult.failed:
        return Icons.error;
      case AIVerificationResult.needsHumanReview:
        return Icons.warning;
      case AIVerificationResult.error:
        return Icons.help_outline;
    }
  }
}
