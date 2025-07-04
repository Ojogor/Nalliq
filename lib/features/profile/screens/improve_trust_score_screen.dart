import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/trust_score_provider.dart';

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
      Provider.of<TrustScoreProvider>(context, listen: false).loadCurrentUser();
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
      body: Consumer<TrustScoreProvider>(
        builder: (context, trustProvider, child) {
          if (trustProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUser = trustProvider.currentUser;
          if (currentUser == null) {
            return const Center(
              child: Text('Please login to view trust score'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current trust score card
                _buildCurrentScoreCard(trustProvider, currentUser.trustScore),

                const SizedBox(height: AppDimensions.marginL),

                // Improvement options
                _buildImprovementOptions(trustProvider),

                const SizedBox(height: AppDimensions.marginL),

                // Trust score history
                _buildTrustScoreHistory(trustProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentScoreCard(
    TrustScoreProvider trustProvider,
    double score,
  ) {
    final scoreLabel = trustProvider.getTrustScoreLabel(score);
    final scoreColor = trustProvider.getTrustScoreColor(score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          children: [
            Icon(Icons.verified_user, size: 64, color: scoreColor),
            const SizedBox(height: AppDimensions.marginM),
            Text(
              score.toStringAsFixed(1),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: scoreColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              scoreLabel,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: scoreColor),
            ),
            const SizedBox(height: AppDimensions.marginS),
            LinearProgressIndicator(
              value: score / 25.0, // Assuming max score of 25
              backgroundColor: AppColors.lightGrey,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementOptions(TrustScoreProvider trustProvider) {
    final options = trustProvider.getTrustImprovementOptions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ways to Improve Your Trust Score',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppDimensions.marginM),
        ...options.map(
          (option) => _buildImprovementOption(trustProvider, option),
        ),
      ],
    );
  }

  Widget _buildImprovementOption(
    TrustScoreProvider trustProvider,
    Map<String, dynamic> option,
  ) {
    final isAvailable = option['available'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.marginM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isAvailable ? AppColors.primaryGreen : AppColors.grey,
          child: Icon(option['icon'] as IconData, color: AppColors.white),
        ),
        title: Text(
          option['title'] as String,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isAvailable ? AppColors.textPrimary : AppColors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option['description'] as String,
              style: TextStyle(
                color: isAvailable ? AppColors.textSecondary : AppColors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '+${option['points']} points',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isAvailable ? AppColors.primaryGreen : AppColors.grey,
              ),
            ),
          ],
        ),
        trailing:
            isAvailable
                ? ElevatedButton(
                  onPressed:
                      () => _handleImprovementAction(
                        trustProvider,
                        option['action'] as TrustScoreAction,
                        option['title'] as String,
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(color: AppColors.white),
                  ),
                )
                : const Icon(Icons.check, color: AppColors.success),
      ),
    );
  }

  Widget _buildTrustScoreHistory(TrustScoreProvider trustProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppDimensions.marginM),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: trustProvider.getTrustScoreHistory(
            trustProvider.currentUser!.id,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.paddingL),
                  child: Center(
                    child: Text(
                      'No trust score activity yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              );
            }

            return Column(
              children:
                  snapshot.data!
                      .map(
                        (activity) => Card(
                          margin: const EdgeInsets.only(
                            bottom: AppDimensions.marginS,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  (activity['scoreChange'] as double) > 0
                                      ? AppColors.success
                                      : AppColors.error,
                              child: Icon(
                                (activity['scoreChange'] as double) > 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: AppColors.white,
                              ),
                            ),
                            title: Text(
                              _getActionDisplayName(
                                activity['action'] as String,
                              ),
                            ),
                            subtitle: Text(
                              '${(activity['scoreChange'] as double) > 0 ? '+' : ''}${activity['scoreChange']} points',
                            ),
                            trailing: Text(
                              _formatDate(activity['timestamp'] as DateTime),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            );
          },
        ),
      ],
    );
  }

  void _handleImprovementAction(
    TrustScoreProvider trustProvider,
    TrustScoreAction action,
    String title,
  ) {
    switch (action) {
      case TrustScoreAction.idVerification:
        _showIdVerificationDialog(trustProvider);
        break;
      case TrustScoreAction.foodSafetyQA:
        _showFoodSafetyQuiz(trustProvider);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title feature coming soon!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
    }
  }

  void _showIdVerificationDialog(TrustScoreProvider trustProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ID Verification'),
            content: const Text(
              'ID verification helps build trust in the community. This feature will be available soon.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Simulate ID verification completion
                  final success = await trustProvider.updateTrustScore(
                    TrustScoreAction.idVerification,
                    reason: 'Completed ID verification process',
                  );

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'ID verification completed! +5 trust points',
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: const Text('Verify Now'),
              ),
            ],
          ),
    );
  }

  void _showFoodSafetyQuiz(TrustScoreProvider trustProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Food Safety Quiz'),
            content: const Text(
              'Complete our food safety quiz to learn best practices and earn trust points.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Simulate quiz completion
                  final success = await trustProvider.updateTrustScore(
                    TrustScoreAction.foodSafetyQA,
                    reason: 'Completed food safety quiz',
                  );

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Food safety quiz completed! +3 trust points',
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: const Text('Start Quiz'),
              ),
            ],
          ),
    );
  }

  String _getActionDisplayName(String action) {
    switch (action) {
      case 'idVerification':
        return 'ID Verification';
      case 'completedBarter':
        return 'Completed Barter';
      case 'completedDonation':
        return 'Completed Donation';
      case 'foodSafetyQA':
        return 'Food Safety Quiz';
      case 'positiveReview':
        return 'Positive Review';
      case 'negativeReview':
        return 'Negative Review';
      case 'reportedMisconduct':
        return 'Reported Misconduct';
      case 'failedExchange':
        return 'Failed Exchange';
      default:
        return action;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
