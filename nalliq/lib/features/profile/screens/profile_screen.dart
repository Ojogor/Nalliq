import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
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

    if (authProvider.isAuthenticated && authProvider.user != null) {
      profileProvider.loadProfileData(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<ProfileProvider, AuthProvider>(
        builder: (context, profileProvider, authProvider, child) {
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
                SliverToBoxAdapter(child: _buildUserInfo(authProvider.appUser)),

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
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: AppColors.white,
      title: const Text(AppStrings.profile),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // Navigate to settings
          },
        ),
      ],
    );
  }

  Widget _buildUserInfo(user) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.marginM),
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: AppDimensions.marginS),

          // Email
          Text(
            user?.email ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),

          const SizedBox(height: AppDimensions.marginM),

          // Trust score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified,
                color: _getTrustColor(user?.trustLevel),
                size: 20,
              ),
              const SizedBox(width: AppDimensions.marginS),
              Text(
                'Trust Score: ${user?.trustScore?.toStringAsFixed(1) ?? '0.0'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _getTrustColor(user?.trustLevel),
                ),
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppDimensions.marginS),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.marginM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.inventory,
            title: AppStrings.myListings,
            onTap: () {
              // Navigate to my listings
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.inbox,
            title: AppStrings.incomingRequests,
            onTap: () {
              // Navigate to incoming requests
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.outbox,
            title: AppStrings.outgoingRequests,
            onTap: () {
              // Navigate to outgoing requests
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.people,
            title: AppStrings.friends,
            onTap: () {
              // Navigate to friends
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.history,
            title: AppStrings.history,
            onTap: () {
              // Navigate to exchange history
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.logout,
            title: AppStrings.logout,
            onTap: () => _handleLogout(authProvider),
            textColor: AppColors.error,
            iconColor: AppColors.error,
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
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.grey),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: AppColors.grey.withOpacity(0.2),
      indent: 16,
      endIndent: 16,
    );
  }

  Color _getTrustColor(trustLevel) {
    // Default implementation
    return AppColors.primaryGreen;
  }

  void _handleLogout(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  authProvider.signOut();
                  context.goNamed('login');
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }
}
