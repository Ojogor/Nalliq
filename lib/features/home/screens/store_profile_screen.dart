import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/widgets/report_user_dialog.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../widgets/food_item_card.dart';

class StoreProfileScreen extends StatefulWidget {
  final String storeUserId;

  const StoreProfileScreen({super.key, required this.storeUserId});

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        Provider.of<StoreProvider>(
          context,
          listen: false,
        ).loadStoreProfile(widget.storeUserId, authProvider.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final storeProvider = Provider.of<StoreProvider>(context);

    if (authProvider.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body:
          storeProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : storeProvider.error != null
              ? _buildErrorView(storeProvider.error!)
              : storeProvider.storeUser == null
              ? const Center(child: Text('Store not found'))
              : _buildStoreProfile(storeProvider, authProvider.user!.uid),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Error loading store',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreProfile(StoreProvider storeProvider, String currentUserId) {
    final store = storeProvider.storeUser!;
    final items = storeProvider.storeItems;
    final isFriend = storeProvider.isFriend;
    final friendRequestSent = storeProvider.friendRequestSent;
    final hasPendingRequest = storeProvider.hasPendingRequestFromStore;
    final isOwnStore = store.id == currentUserId;

    return CustomScrollView(
      slivers: [
        // App bar with store info
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          actions: [
            // Only show report button if not own store
            if (!isOwnStore)
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final currentUser = authProvider.appUser;
                  if (currentUser == null) return const SizedBox.shrink();

                  return IconButton(
                    onPressed: () => _showReportDialog(currentUser, store),
                    icon: const Icon(Icons.report, color: Colors.white),
                    tooltip: 'Report Store',
                  );
                },
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryGreen.withOpacity(0.8),
                    AppColors.lightGreen.withOpacity(0.6),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Center(
                              child: Text(
                                store.displayName.isNotEmpty
                                    ? store.displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Store info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        store.displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (store.role == UserRole.foodBank)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryOrange,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          'Food Bank',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${store.trustScore.toStringAsFixed(1)} trust score',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                // Location and distance info
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, child) {
                                    final currentUser = authProvider.appUser;
                                    final distance =
                                        currentUser?.location != null &&
                                                store.location != null
                                            ? DistanceCalculator.calculateDistanceToUser(
                                              currentUser!.location,
                                              store.location,
                                            )
                                            : null;

                                    if (store.location != null) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              color: Colors.white70,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                distance != null
                                                    ? '${store.location!['address'] ?? 'Location set'} • ${DistanceCalculator.formatDistance(distance)} away'
                                                    : store.location!['address'] ??
                                                        'Location set',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                if (store.bio?.isNotEmpty == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      store.bio!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Action buttons
        if (!isOwnStore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildFriendshipButtons(
                storeProvider,
                currentUserId,
                isFriend,
                friendRequestSent,
                hasPendingRequest,
              ),
            ),
          ),
        // Store stats
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Items Available',
                    '${items.length}',
                    Icons.inventory_2_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Exchanges',
                    '${store.stats['exchanges'] ?? 0}',
                    Icons.swap_horiz,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Member Since',
                    _formatDate(store.createdAt),
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Items grid
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Available Items',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        items.isEmpty
            ? const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No items available',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            )
            : SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = items[index];
                  return FoodItemCard(
                    item: item,
                    onTap: () => context.push('/item/${item.id}'),
                    showAddButton: !isOwnStore, // Hide add button for own items
                  );
                }, childCount: items.length),
              ),
            ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildFriendshipButtons(
    StoreProvider storeProvider,
    String currentUserId,
    bool isFriend,
    bool friendRequestSent,
    bool hasPendingRequest,
  ) {
    if (hasPendingRequest) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                storeProvider.acceptFriendRequest(
                  storeProvider.pendingRequestId!,
                  widget.storeUserId,
                  currentUserId,
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Accept Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                storeProvider.cancelFriendRequest(
                  storeProvider.pendingRequestId!,
                );
              },
              icon: const Icon(Icons.close),
              label: const Text('Decline'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
      );
    }

    if (isFriend) {
      return ElevatedButton.icon(
        onPressed:
            () => storeProvider.removeFriend(widget.storeUserId, currentUserId),
        icon: const Icon(Icons.person_remove),
        label: const Text('Remove Friend'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
    }

    if (friendRequestSent) {
      return ElevatedButton.icon(
        onPressed:
            () => storeProvider.cancelFriendRequest(
              storeProvider.pendingRequestId!,
            ),
        icon: const Icon(Icons.cancel_schedule_send),
        label: const Text('Cancel Request'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed:
          () => storeProvider.sendFriendRequest(
            widget.storeUserId,
            currentUserId,
          ),
      icon: const Icon(Icons.person_add),
      label: const Text('Add Friend'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}yr ago';
    }
  }

  void _showReportDialog(AppUser currentUser, AppUser storeUser) {
    showDialog(
      context: context,
      builder:
          (context) => ReportUserDialog(
            reportedUser: storeUser,
            currentUser: currentUser,
          ),
    );
  }
}
