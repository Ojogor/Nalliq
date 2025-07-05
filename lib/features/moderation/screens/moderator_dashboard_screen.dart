import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/food_item_model.dart';
import '../../auth/providers/auth_provider.dart';

class ModeratorDashboardScreen extends StatefulWidget {
  const ModeratorDashboardScreen({super.key});

  @override
  State<ModeratorDashboardScreen> createState() =>
      _ModeratorDashboardScreenState();
}

class _ModeratorDashboardScreenState extends State<ModeratorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Check if user is actually a moderator
    if (authProvider.appUser?.role != UserRole.moderator) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You need moderator privileges to access this area.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderator Dashboard'),
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.inventory), text: 'Items'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildItemsTab(),
          _buildUsersTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: AppDimensions.marginL),
          _buildQuickStats(),
          const SizedBox(height: AppDimensions.marginL),
          _buildRecentAlerts(),
          const SizedBox(height: AppDimensions.marginL),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      color: AppColors.error.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.error,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Moderator Access',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      Text(
                        'Community safety and content moderation',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'You have full moderator privileges including item review, user management, and safety enforcement. Use these tools responsibly to maintain community standards.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginM),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('items').snapshots(),
              builder: (context, itemSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('users').snapshots(),
                  builder: (context, userSnapshot) {
                    final itemCount = itemSnapshot.data?.docs.length ?? 0;
                    final userCount = userSnapshot.data?.docs.length ?? 0;
                    final pendingItems =
                        itemSnapshot.data?.docs
                            .where(
                              (doc) =>
                                  (doc.data()
                                      as Map<String, dynamic>)['status'] ==
                                  'pending',
                            )
                            .length ??
                        0;

                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Items',
                            itemCount.toString(),
                            Icons.inventory,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Total Users',
                            userCount.toString(),
                            Icons.people,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Pending Review',
                            pendingItems.toString(),
                            Icons.pending,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlerts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Safety Alerts',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginM),
            StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('safety_reports')
                      .orderBy('createdAt', descending: true)
                      .limit(5)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reports = snapshot.data!.docs;

                if (reports.isEmpty) {
                  return Center(
                    child: Text(
                      'No recent safety alerts',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return Column(
                  children:
                      reports.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildAlertItem(
                          data['type'] ?? 'Unknown',
                          data['description'] ?? 'No description',
                          data['createdAt'] != null
                              ? (data['createdAt'] as Timestamp).toDate()
                              : DateTime.now(),
                        );
                      }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(String type, String description, DateTime date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: AppColors.warning, width: 4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  'Review Flagged Items',
                  Icons.flag,
                  () => _tabController.animateTo(1),
                ),
                _buildActionChip(
                  'User Reports',
                  Icons.report,
                  () => _tabController.animateTo(2),
                ),
                _buildActionChip('Export Data', Icons.download, _exportData),
                _buildActionChip(
                  'Safety Settings',
                  Icons.security,
                  _openSafetySettings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
      labelStyle: TextStyle(color: AppColors.primaryGreen),
    );
  }

  Widget _buildItemsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('items').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final doc = items[index];
            final item = FoodItem.fromFirestore(doc);
            return _buildItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildItemCard(FoodItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.lightGrey,
          child: Text(item.name[0].toUpperCase()),
        ),
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Owner: ${item.ownerId}'),
            Text('Category: ${item.category.name}'),
            if (item.expiryDate != null)
              Text(
                'Expires: ${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}',
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleItemAction(action, item),
          itemBuilder:
              (context) => [
                const PopupMenuItem(value: 'approve', child: Text('Approve')),
                const PopupMenuItem(
                  value: 'flag',
                  child: Text('Flag for Review'),
                ),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
                const PopupMenuItem(value: 'ban_user', child: Text('Ban User')),
              ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final doc = users[index];
            final user = AppUser.fromFirestore(doc);
            return _buildUserCard(user);
          },
        );
      },
    );
  }

  Widget _buildUserCard(AppUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.lightGrey,
          child: Text(user.displayName[0].toUpperCase()),
        ),
        title: Text(user.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email}'),
            Text('Role: ${user.role.name}'),
            Text('Trust: ${user.trustLevel.name}'),
            if (user.isBanned)
              Text(
                'BANNED: ${user.banReason}',
                style: TextStyle(color: AppColors.error),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleUserAction(action, user),
          itemBuilder:
              (context) => [
                if (!user.isBanned)
                  const PopupMenuItem(value: 'ban', child: Text('Ban User'))
                else
                  const PopupMenuItem(
                    value: 'unban',
                    child: Text('Unban User'),
                  ),
                const PopupMenuItem(value: 'verify', child: Text('Verify ID')),
                const PopupMenuItem(
                  value: 'trust_up',
                  child: Text('Increase Trust'),
                ),
                const PopupMenuItem(
                  value: 'trust_down',
                  child: Text('Decrease Trust'),
                ),
              ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community Analytics',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppDimensions.marginL),
          _buildAnalyticsCard(
            'User Activity',
            'Track user engagement and safety compliance',
          ),
          _buildAnalyticsCard(
            'Item Safety',
            'Monitor food safety violations and reports',
          ),
          _buildAnalyticsCard(
            'Trust Metrics',
            'Community trust scores and verification rates',
          ),
          _buildAnalyticsCard(
            'Geographic Data',
            'Location-based usage patterns',
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Analytics implementation coming soon',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleItemAction(String action, FoodItem item) async {
    switch (action) {
      case 'approve':
        await _firestore.collection('items').doc(item.id).update({
          'status': 'approved',
        });
        _showSnackBar('Item approved');
        break;
      case 'flag':
        await _firestore.collection('items').doc(item.id).update({
          'flagged': true,
        });
        _showSnackBar('Item flagged for review');
        break;
      case 'remove':
        await _firestore.collection('items').doc(item.id).delete();
        _showSnackBar('Item removed');
        break;
      case 'ban_user':
        await _banUser(item.ownerId, 'Sharing unsafe items');
        break;
    }
  }

  void _handleUserAction(String action, AppUser user) async {
    switch (action) {
      case 'ban':
        await _banUser(user.id, 'Safety violation');
        break;
      case 'unban':
        await _unbanUser(user.id);
        break;
      case 'verify':
        await _firestore.collection('users').doc(user.id).update({
          'idVerified': true,
          'idVerificationDate': Timestamp.now(),
        });
        _showSnackBar('User ID verified');
        break;
      case 'trust_up':
        final newLevel =
            user.trustLevel == TrustLevel.low
                ? TrustLevel.medium
                : TrustLevel.high;
        await _firestore.collection('users').doc(user.id).update({
          'trustLevel': newLevel.name,
        });
        _showSnackBar('Trust level increased');
        break;
      case 'trust_down':
        final newLevel =
            user.trustLevel == TrustLevel.high
                ? TrustLevel.medium
                : TrustLevel.low;
        await _firestore.collection('users').doc(user.id).update({
          'trustLevel': newLevel.name,
        });
        _showSnackBar('Trust level decreased');
        break;
    }
  }

  Future<void> _banUser(String userId, String reason) async {
    await _firestore.collection('users').doc(userId).update({
      'isBanned': true,
      'banReason': reason,
      'banDate': Timestamp.now(),
    });
    _showSnackBar('User banned');
  }

  Future<void> _unbanUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isBanned': false,
      'banReason': null,
      'banDate': null,
    });
    _showSnackBar('User unbanned');
  }

  void _exportData() {
    _showSnackBar('Data export feature coming soon');
  }

  void _openSafetySettings() {
    _showSnackBar('Safety settings coming soon');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
