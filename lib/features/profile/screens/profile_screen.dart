import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../trust/providers/trust_score_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final trustProvider = context.read<TrustScoreProvider>();

    if (authProvider.isAuthenticated && authProvider.user != null) {
      profileProvider.loadProfileData(authProvider.user!.uid);
      trustProvider.loadTrustData(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      body: Consumer3<ProfileProvider, AuthProvider, TrustScoreProvider>(
        builder: (
          context,
          profileProvider,
          authProvider,
          trustProvider,
          child,
        ) {
          if (!authProvider.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.goNamed('login');
            });
            return const SizedBox.shrink();
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(authProvider),

              if (profileProvider.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // User info section
                SliverToBoxAdapter(
                  child: _buildUserInfo(authProvider.appUser, trustProvider),
                ),

                // Stats section
                SliverToBoxAdapter(child: _buildStats(profileProvider)),

                // Menu items
                SliverToBoxAdapter(child: _buildMenuItems(authProvider)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(AuthProvider authProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      floating: true,
      backgroundColor:
          isDark ? const Color(0xFF2D2D30) : AppColors.primaryGreen,
      foregroundColor: AppColors.white,
      title: const Text(AppStrings.profile),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => context.pushNamed('settings'),
        ),
      ],
    );
  }

  Widget _buildUserInfo(user, TrustScoreProvider trustProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(AppDimensions.marginM),
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D30) : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
            backgroundImage:
                user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
            child:
                user?.photoUrl == null
                    ? Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.primaryGreen,
                    )
                    : null,
          ),

          const SizedBox(height: AppDimensions.marginM),

          // Name
          Text(
            user?.displayName ?? 'User',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(height: AppDimensions.marginS),

          // Email
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(height: AppDimensions.marginM),

          // Trust score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified,
                color: _getTrustColorFromScore(
                  trustProvider.getCurrentTrustScore(),
                ),
                size: 20,
              ),
              const SizedBox(width: AppDimensions.marginS),
              Text(
                'Trust Score: ${trustProvider.getCurrentTrustScore().toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getTrustColorFromScore(
                    trustProvider.getCurrentTrustScore(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.marginM),

          // Improve trust score button
          ElevatedButton.icon(
            onPressed: () => context.pushNamed('trust-score'),
            icon: const Icon(Icons.trending_up),
            label: const Text('Improve Trust Score'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingL,
                vertical: AppDimensions.paddingM,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(ProfileProvider profileProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginM),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Friends',
              '${profileProvider.friends.length}',
              Icons.people,
              AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: AppDimensions.marginM),
          Expanded(
            child: _buildStatCard(
              'Exchanges',
              '${profileProvider.exchangeHistory.length}',
              Icons.swap_horiz,
              AppColors.primaryOrange,
            ),
          ),
          const SizedBox(width: AppDimensions.marginM),
          Expanded(
            child: _buildStatCard(
              'Requests',
              '${profileProvider.incomingRequests.length}',
              Icons.inbox,
              AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D30) : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppDimensions.marginS),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(AuthProvider authProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(AppDimensions.marginM),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D30) : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.inventory,
            title: AppStrings.myListings,
            onTap: () => context.pushNamed('my-listings'),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.inbox,
            title: AppStrings.incomingRequests,
            onTap: () => context.pushNamed('incoming-requests'),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.outbox,
            title: AppStrings.outgoingRequests,
            onTap: () => context.pushNamed('outgoing-requests'),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.people,
            title: AppStrings.friends,
            onTap: () => context.pushNamed('friends'),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.history,
            title: AppStrings.history,
            onTap: () => context.pushNamed('history'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? (isDark ? Colors.white70 : AppColors.grey),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: textColor ?? (isDark ? Colors.white : AppColors.textPrimary),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.white70 : AppColors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Divider(
      height: 1,
      color: (isDark ? Colors.white : AppColors.grey).withOpacity(0.2),
      indent: 16,
      endIndent: 16,
    );
  }

  Color _getTrustColorFromScore(double score) {
    if (score >= 8.0) return const Color(0xFF4CAF50); // Green
    if (score >= 6.0) return const Color(0xFF8BC34A); // Light Green
    if (score >= 4.0) return const Color(0xFFFFC107); // Amber
    if (score >= 2.0) return const Color(0xFFFF9800); // Orange
    return const Color(0xFF757575); // Grey
  }
}

class TrustScoreDialog extends StatefulWidget {
  final dynamic user;

  const TrustScoreDialog({super.key, required this.user});

  @override
  State<TrustScoreDialog> createState() => _TrustScoreDialogState();
}

class _TrustScoreDialogState extends State<TrustScoreDialog> {
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
        final summary = trustProvider.trustSummary;
        final currentScore = summary?.totalScore ?? 0.0;
        final isLoading = trustProvider.isLoading;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.verified, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Trust Score', overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6, // Limit height
            child:
                isLoading
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                    : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Current trust score
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryGreen.withOpacity(0.2),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGreen.withOpacity(
                                    0.1,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      color: AppColors.primaryGreen,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Your Trust Score',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGreen,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${currentScore.toStringAsFixed(1)}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.displayMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                Text(
                                  'out of 10.0',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                color: AppColors.primaryGreen,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ways to improve your trust score:',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Trust score improvement options
                          _buildTrustScoreOption(
                            context,
                            Icons.verified_user,
                            'ID Verification',
                            '+2.0 points',
                            'Verify your identity with official documents',
                            AppColors.info,
                            !trustProvider.isIDVerified(),
                          ),

                          _buildTrustScoreOption(
                            context,
                            Icons.school,
                            'Food Safety Certifications',
                            '+1.5 points',
                            'Complete food safety certifications',
                            AppColors.primaryOrange,
                            true, // Always available to get more certifications
                          ),

                          _buildTrustScoreOption(
                            context,
                            Icons.swap_horiz,
                            'Complete Exchanges',
                            '+0.5 points each',
                            'Successfully complete barter exchanges',
                            AppColors.primaryGreen,
                            true, // Always available
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'Note: Trust score may be reduced for negative actions like failing to complete exchanges, reporting violations, etc.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                context.pop();
                context.pushNamed('trust-score');
              },
              child: const Text('View Details'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrustScoreOption(
    BuildContext context,
    IconData icon,
    String title,
    String points,
    String description,
    Color color,
    bool isAvailable,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.grey).withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  points,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey[400] : AppColors.textSecondary,
            ),
          ),
        ),
        trailing:
            isAvailable
                ? Icon(Icons.chevron_right, size: 20, color: color)
                : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Completed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        onTap: isAvailable ? () => _handleTrustScoreAction(title) : null,
      ),
    );
  }

  void _handleTrustScoreAction(String action) async {
    context.pop();

    switch (action) {
      case 'ID Verification':
        context.push('/id-verification');
        break;
      case 'Food Safety Certifications':
        context.push('/certifications');
        break;
      case 'Complete Exchanges':
        // Navigate to exchanges or show info
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Complete successful exchanges to earn trust points!',
            ),
          ),
        );
        break;
    }
  }
}
