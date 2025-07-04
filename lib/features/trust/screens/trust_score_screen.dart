import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/certification_model.dart';
import '../../../core/models/trust_score_model.dart';
import '../../../core/models/trust_violation_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/trust_score_provider.dart';

class TrustScoreScreen extends StatefulWidget {
  const TrustScoreScreen({super.key});

  @override
  State<TrustScoreScreen> createState() => _TrustScoreScreenState();
}

class _TrustScoreScreenState extends State<TrustScoreScreen> {
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
    return Consumer2<TrustScoreProvider, AuthProvider>(
      builder: (context, trustProvider, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Trust Score'),
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.white,
          ),
          body:
              trustProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : trustProvider.error != null
                  ? _buildErrorState(trustProvider)
                  : _buildContent(trustProvider, authProvider),
        );
      },
    );
  }

  Widget _buildErrorState(TrustScoreProvider trustProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Error loading trust data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            trustProvider.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              if (authProvider.user != null) {
                trustProvider.loadTrustData(authProvider.user!.uid);
              }
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    TrustScoreProvider trustProvider,
    AuthProvider authProvider,
  ) {
    final summary = trustProvider.trustSummary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trust Score Overview
          _buildTrustScoreCard(summary),
          const SizedBox(height: AppDimensions.marginL),

          // Action Cards
          _buildActionCards(trustProvider, authProvider),
          const SizedBox(height: AppDimensions.marginL),

          // Recent Activity
          if (trustProvider.trustEntries.isNotEmpty) ...[
            _buildSectionHeader('Recent Activity'),
            _buildRecentActivity(trustProvider.trustEntries.take(5).toList()),
            const SizedBox(height: AppDimensions.marginL),
          ],

          // Recommendations
          if (summary?.recommendations.isNotEmpty ?? false) ...[
            _buildSectionHeader('Recommendations'),
            _buildRecommendations(summary!.recommendations),
            const SizedBox(height: AppDimensions.marginL),
          ],

          // Certifications
          _buildSectionHeader('Food Safety Certifications'),
          _buildCertifications(trustProvider.certifications),
          const SizedBox(height: AppDimensions.marginL),

          // Violations (if any)
          if (trustProvider.violations.isNotEmpty) ...[
            _buildSectionHeader('Trust Violations'),
            _buildViolations(trustProvider.violations),
          ],
        ],
      ),
    );
  }

  Widget _buildTrustScoreCard(TrustScoreSummary? summary) {
    final score = summary?.totalScore ?? 0.0;
    final level = summary?.trustLevel ?? 'New User';
    final color = Color(
      int.parse(
            summary?.trustLevelColor.substring(1) ?? 'FF757575',
            radix: 16,
          ) +
          0xFF000000,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trust Score',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        score.toStringAsFixed(1),
                        style: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        level,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.marginM),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: score / 10.0,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.marginM),
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Exchanges',
                      summary?.successfulExchanges ?? 0,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _buildStatItem(
                      'Certifications',
                      summary?.certifications ?? 0,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _buildStatItem(
                      'Violations',
                      summary?.violations ?? 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionCards(
    TrustScoreProvider trustProvider,
    AuthProvider authProvider,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'ID Verification',
                trustProvider.isIDVerified() ? 'Verified' : 'Not Verified',
                trustProvider.isIDVerified()
                    ? Icons.verified_user
                    : Icons.person_outline,
                trustProvider.isIDVerified()
                    ? AppColors.success
                    : AppColors.warning,
                () => context.push('/id-verification'),
              ),
            ),
            const SizedBox(width: AppDimensions.marginM),
            Expanded(
              child: _buildActionCard(
                'Certifications',
                'Get Certified',
                Icons.school,
                AppColors.primaryGreen,
                () => context.push('/certifications'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: color),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.marginS),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRecentActivity(List<TrustScoreEntry> entries) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return ListTile(
            leading: Icon(
              entry.isPositive ? Icons.add_circle : Icons.remove_circle,
              color: entry.isPositive ? AppColors.success : AppColors.error,
            ),
            title: Text(entry.actionDisplayName),
            subtitle: Text(entry.description),
            trailing: Text(
              '${entry.isPositive ? '+' : ''}${entry.points.toStringAsFixed(1)}',
              style: TextStyle(
                color: entry.isPositive ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendations(List<String> recommendations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children:
              recommendations
                  .map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.marginS,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: AppDimensions.marginS),
                          Expanded(child: Text(rec)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildCertifications(List<FoodCertification> certifications) {
    if (certifications.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            children: [
              const Icon(Icons.school, size: 48, color: Colors.grey),
              const SizedBox(height: AppDimensions.marginM),
              Text(
                'No certifications yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDimensions.marginS),
              const Text(
                'Get food safety certifications to boost your trust score',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: AppDimensions.marginM),
              ElevatedButton(
                onPressed: () => context.push('/certifications'),
                child: const Text('Get Certified'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: certifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final cert = certifications[index];
          Color statusColor;
          IconData statusIcon;

          switch (cert.status) {
            case CertificationStatus.approved:
              statusColor = AppColors.success;
              statusIcon = Icons.check_circle;
              break;
            case CertificationStatus.pending:
              statusColor = AppColors.warning;
              statusIcon = Icons.pending;
              break;
            case CertificationStatus.rejected:
              statusColor = AppColors.error;
              statusIcon = Icons.cancel;
              break;
            case CertificationStatus.expired:
              statusColor = Colors.grey;
              statusIcon = Icons.schedule;
              break;
          }

          return ListTile(
            leading: Icon(statusIcon, color: statusColor),
            title: Text(cert.displayName),
            subtitle: Text(cert.description),
            trailing:
                cert.status == CertificationStatus.approved
                    ? Text(
                      '+${cert.scorePoints.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          );
        },
      ),
    );
  }

  Widget _buildViolations(List<TrustViolation> violations) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: violations.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final violation = violations[index];
          final severityColor = Color(
            int.parse(violation.severityColor.substring(1), radix: 16) +
                0xFF000000,
          );

          return ListTile(
            leading: Icon(Icons.warning, color: severityColor),
            title: Text(violation.displayName),
            subtitle: Text(violation.description),
            trailing: Text(
              '-${violation.penaltyPoints.toStringAsFixed(1)}',
              style: TextStyle(
                color: severityColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}
