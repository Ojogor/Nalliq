import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/certification_model.dart';
import '../../../core/models/id_verification_model.dart';
import '../../trust/providers/trust_score_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ImproveTrustScoreScreen extends StatefulWidget {
  const ImproveTrustScoreScreen({super.key});

  @override
  State<ImproveTrustScoreScreen> createState() =>
      _ImproveTrustScoreScreenState();
}

class _ImproveTrustScoreScreenState extends State<ImproveTrustScoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final trustProvider = Provider.of<TrustScoreProvider>(
        context,
        listen: false,
      );
      if (authProvider.user != null) {
        trustProvider.loadTrustData(authProvider.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Improve Trust Score'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer2<TrustScoreProvider, AuthProvider>(
        builder: (context, trustProvider, authProvider, child) {
          if (trustProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (authProvider.user == null) {
            return const Center(
              child: Text('Please login to view trust score'),
            );
          }

          if (trustProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${trustProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        () =>
                            trustProvider.loadTrustData(authProvider.user!.uid),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current trust score card
                  _buildCurrentScoreCard(trustProvider),

                  const SizedBox(height: AppDimensions.marginL),

                  // Improvement options
                  _buildImprovementOptions(
                    trustProvider,
                    authProvider.user!.uid,
                  ),

                  const SizedBox(height: AppDimensions.marginL),

                  // Trust score history
                  _buildTrustScoreHistory(trustProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentScoreCard(TrustScoreProvider trustProvider) {
    final currentScore = trustProvider.getCurrentTrustScore();
    final trustLevel = trustProvider.getTrustLevel();
    final isIDVerified = trustProvider.isIDVerified();
    final certificationCount = trustProvider.getCertificationCount();
    final violationCount = trustProvider.getViolationCount();

    Color scoreColor;
    if (currentScore >= 8.0) {
      scoreColor = Colors.green;
    } else if (currentScore >= 6.0) {
      scoreColor = Colors.lightGreen;
    } else if (currentScore >= 4.0) {
      scoreColor = Colors.amber;
    } else if (currentScore >= 2.0) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.grey;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          children: [
            Icon(Icons.verified_user, size: 64, color: scoreColor),
            const SizedBox(height: AppDimensions.marginM),
            Text(
              currentScore.toStringAsFixed(1),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: scoreColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.marginS),
            Text(
              trustLevel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: scoreColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.marginM),
            LinearProgressIndicator(
              value: (currentScore / 10.0).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
            const SizedBox(height: AppDimensions.marginM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreMetric(
                  'ID Verified',
                  isIDVerified ? 'Yes' : 'No',
                  isIDVerified ? Colors.green : Colors.grey,
                ),
                _buildScoreMetric(
                  'Certifications',
                  certificationCount.toString(),
                  certificationCount > 0 ? Colors.blue : Colors.grey,
                ),
                _buildScoreMetric(
                  'Violations',
                  violationCount.toString(),
                  violationCount == 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildImprovementOptions(
    TrustScoreProvider trustProvider,
    String userId,
  ) {
    final recommendations = trustProvider.getRecommendations();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ways to Improve Your Trust Score',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginM),
            if (recommendations.isNotEmpty) ...[
              ...recommendations.map(
                (recommendation) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.marginS),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: AppDimensions.marginS),
                      Expanded(child: Text(recommendation)),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Text('You\'re doing great! Keep up the good work.'),
            ],
            const SizedBox(height: AppDimensions.marginL),
            _buildActionButtons(trustProvider, userId),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(TrustScoreProvider trustProvider, String userId) {
    return Column(
      children: [
        if (!trustProvider.isIDVerified()) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showIDVerificationDialog(trustProvider, userId),
              icon: const Icon(Icons.verified_user),
              label: const Text('Verify Your ID'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.marginM),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showCertificationDialog(trustProvider, userId),
            icon: const Icon(Icons.card_membership),
            label: const Text('Add Food Certification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustScoreHistory(TrustScoreProvider trustProvider) {
    final entries = trustProvider.trustEntries;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trust Score History',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginM),
            if (entries.isEmpty) ...[
              const Center(child: Text('No trust score history yet.')),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.take(10).length, // Show last 10 entries
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ListTile(
                    leading: Icon(
                      entry.isPositive
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: entry.isPositive ? Colors.green : Colors.red,
                    ),
                    title: Text(entry.actionDisplayName),
                    subtitle: Text(entry.description),
                    trailing: Text(
                      '${entry.isPositive ? '+' : ''}${entry.points.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: entry.isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showIDVerificationDialog(
    TrustScoreProvider trustProvider,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ID Verification'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ID verification helps improve your trust score and allows access to more features.',
              ),
              SizedBox(height: 16),
              Text('You\'ll need to provide:'),
              Text('• A government-issued photo ID'),
              Text('• Clear photos of both sides (if applicable)'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startIDVerification(trustProvider, userId);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _showCertificationDialog(
    TrustScoreProvider trustProvider,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Food Certification'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Food certifications boost your trust score and show your commitment to food safety.',
              ),
              SizedBox(height: 16),
              Text('Available certifications:'),
              Text('• Food Handler Certificate'),
              Text('• Food Safety Manager'),
              Text('• HACCP Certification'),
              Text('• Organic Certification'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startCertificationProcess(trustProvider, userId);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startIDVerification(
    TrustScoreProvider trustProvider,
    String userId,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();

      // Pick front image
      final XFile? frontImage = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (frontImage == null) return;

      // For now, we'll submit with just the front image
      // In a real app, you might want to pick back image for certain ID types
      final success = await trustProvider.submitIDVerification(
        userId: userId,
        idType: IDType.driversLicense, // Default type
        frontImage: frontImage,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'ID verification submitted successfully! It will be reviewed shortly.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to submit ID verification: ${trustProvider.error}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _startCertificationProcess(
    TrustScoreProvider trustProvider,
    String userId,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();

      // Pick certification image
      final XFile? certImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (certImage == null) return;

      final success = await trustProvider.submitFoodCertification(
        userId: userId,
        type: CertificationType.foodHandling1, // Default type
        certificateImage: certImage,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Certification submitted successfully! It will be reviewed shortly.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to submit certification: ${trustProvider.error}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
