import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/trust_score_model.dart';
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
      body: SafeArea(
        child: Consumer2<TrustScoreProvider, AuthProvider>(
          builder: (context, trustProvider, authProvider, child) {
            if (trustProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (authProvider.user == null) {
              return const Center(
                child: Text('Please login to view trust score'),
              );
            }

            final currentScore = trustProvider.getCurrentTrustScore();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current trust score card
                  _buildCurrentScoreCard(currentScore),

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
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentScoreCard(double score) {
    final scoreColor = _getTrustScoreColor(score);
    final scoreLabel = _getTrustScoreLabel(score);

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
              value: score / 10.0, // Max score of 10
              backgroundColor: AppColors.lightGrey,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementOptions(
    TrustScoreProvider trustProvider,
    String userId,
  ) {
    final options = _getTrustImprovementOptions();

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
          (option) => _buildImprovementOption(trustProvider, userId, option),
        ),
      ],
    );
  }

  Widget _buildImprovementOption(
    TrustScoreProvider trustProvider,
    String userId,
    Map<String, dynamic> option,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.marginM),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryGreen,
                  child: Icon(
                    option['icon'] as IconData,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: AppDimensions.marginM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${option['points']} points',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.marginS),
            Text(option['description'] as String),
            const SizedBox(height: AppDimensions.marginM),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    () => _handleImprovementAction(
                      trustProvider,
                      userId,
                      option['action'] as String,
                      option['points'] as double,
                      option['title'] as String,
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ),
          ],
        ),
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
        if (trustProvider.trustEntries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.paddingL),
              child: Center(
                child: Text(
                  'No trust score activity yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          )
        else
          Column(
            children:
                trustProvider.trustEntries
                    .take(5)
                    .map(
                      (entry) => Card(
                        margin: const EdgeInsets.only(
                          bottom: AppDimensions.marginS,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                entry.points > 0
                                    ? AppColors.success
                                    : AppColors.error,
                            child: Icon(
                              entry.points > 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: AppColors.white,
                            ),
                          ),
                          title: Text(entry.description),
                          subtitle: Text(
                            '${entry.points > 0 ? '+' : ''}${entry.points} points',
                          ),
                          trailing: Text(
                            _formatDate(entry.timestamp),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
      ],
    );
  }

  void _handleImprovementAction(
    TrustScoreProvider trustProvider,
    String userId,
    String action,
    double points,
    String title,
  ) {
    switch (action) {
      case 'idVerification':
        _showIdVerificationDialog(trustProvider, userId, points);
        break;
      case 'certificationCompleted':
        _showFoodSafetyQuiz(trustProvider, userId, points);
        break;
      case 'successfulExchange':
        _showExchangeInfo(title);
        break;
      case 'communityContribution':
        _showDonationInfo(title);
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

  void _showIdVerificationDialog(
    TrustScoreProvider trustProvider,
    String userId,
    double points,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ID Verification'),
            content: const Text(
              'ID verification helps build trust in the community. This will add points to your trust score.',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  context.pop();
                  // Use the actual method from TrustScoreProvider
                  final success = await trustProvider.addTrustScoreEntry(
                    userId: userId,
                    action: TrustScoreAction.idVerification,
                    points: points,
                    description: 'Completed ID verification process',
                  );

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'ID verification completed! +$points trust points',
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

  void _showFoodSafetyQuiz(
    TrustScoreProvider trustProvider,
    String userId,
    double points,
  ) {
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
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  context.pop();
                  // Use the actual method from TrustScoreProvider
                  final success = await trustProvider.addTrustScoreEntry(
                    userId: userId,
                    action: TrustScoreAction.certificationCompleted,
                    points: points,
                    description: 'Completed food safety quiz',
                  );

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Food safety quiz completed! +$points trust points',
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

  void _showExchangeInfo(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Complete exchanges through the app to earn trust points automatically!',
        ),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDonationInfo(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Make donations to food banks or community members to earn trust points!',
        ),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<Map<String, dynamic>> _getTrustImprovementOptions() {
    return [
      {
        'icon': Icons.verified_user,
        'title': 'ID Verification',
        'description': 'Verify your identity to build trust with other users',
        'points': 5.0,
        'action': 'idVerification',
      },
      {
        'icon': Icons.quiz,
        'title': 'Food Safety Quiz',
        'description': 'Complete a quiz about food safety practices',
        'points': 3.0,
        'action': 'certificationCompleted',
      },
      {
        'icon': Icons.swap_horiz,
        'title': 'Complete Exchanges',
        'description': 'Successfully complete food exchanges with other users',
        'points': 2.0,
        'action': 'successfulExchange',
      },
      {
        'icon': Icons.volunteer_activism,
        'title': 'Make Donations',
        'description': 'Donate food items to help others in the community',
        'points': 3.0,
        'action': 'communityContribution',
      },
    ];
  }

  Color _getTrustScoreColor(double score) {
    if (score >= 8.0) return AppColors.success;
    if (score >= 6.0) return AppColors.primaryGreen;
    if (score >= 4.0) return AppColors.primaryOrange;
    if (score >= 2.0) return Colors.orange;
    return AppColors.error;
  }

  String _getTrustScoreLabel(double score) {
    if (score >= 8.0) return 'Excellent';
    if (score >= 6.0) return 'Good';
    if (score >= 4.0) return 'Fair';
    if (score >= 2.0) return 'Poor';
    return 'Very Poor';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
