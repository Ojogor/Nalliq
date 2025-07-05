import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/user_model.dart';
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
                  child: _buildUserInfo(
                    authProvider.appUser,
                    trustProvider,
                    authProvider,
                  ),
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
    );
  }

  Widget _buildUserInfo(
    user,
    TrustScoreProvider trustProvider,
    AuthProvider authProvider,
  ) {
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
          user?.photoUrl != null &&
                  user!.photoUrl!.isNotEmpty &&
                  !user.photoUrl!.contains('example.com')
              ? CachedNetworkImage(
                imageUrl: user.photoUrl!,
                imageBuilder:
                    (context, imageProvider) => CircleAvatar(
                      radius: 40,
                      backgroundImage: imageProvider,
                    ),
                placeholder:
                    (context, url) => CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                      child: const CircularProgressIndicator(),
                    ),
                errorWidget:
                    (context, url, error) => CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.primaryGreen,
                      ),
                    ),
              )
              : CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: AppColors.primaryGreen,
                ),
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

          // Location display (if user has set location)
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.appUser;
              final hasLocation = user?.location != null;

              if (!hasLocation) return const SizedBox.shrink();

              return Column(
                children: [
                  const SizedBox(height: AppDimensions.marginS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          user?.location?['address'] ?? 'Location set',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
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
              Flexible(
                child: Text(
                  'Trust Score: ${trustProvider.getCurrentTrustScore().toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getTrustColorFromScore(
                      trustProvider.getCurrentTrustScore(),
                    ),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.marginM),

          // Improve trust score button (hidden for food banks)
          if (authProvider.appUser?.role != UserRole.foodBank)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton.icon(
                onPressed: () => context.pushNamed('trust-score'),
                icon: const Icon(Icons.trending_up),
                label: const Text(
                  'View Trust Score',
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                    vertical: AppDimensions.paddingM,
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppDimensions.marginS),

          // Edit profile button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: OutlinedButton.icon(
              onPressed: () => context.pushNamed('edit-profile'),
              icon: const Icon(Icons.edit),
              label: const Text(
                'Edit Profile',
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                  vertical: AppDimensions.paddingM,
                ),
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
      child: IntrinsicHeight(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppDimensions.marginS),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
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
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.location_on,
            title: 'Manage Location',
            onTap: () => context.pushNamed('change-location'),
          ),
          _buildDivider(),
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
