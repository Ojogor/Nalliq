import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/food_item_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../items/providers/item_provider.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  bool _isLoading = true;
  List<FoodItem> _myItems = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyListings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when the screen comes into focus
    _loadMyListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyListings() async {
    try {
      print('🔄 Loading my listings...');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        print('❌ User not authenticated');
        setState(() {
          _isLoading = false;
          _error = 'User not authenticated';
        });
        return;
      }

      print('👤 Loading items for user: ${authProvider.user!.uid}');
      final query =
          await _firestore
              .collection('items')
              .where('ownerId', isEqualTo: authProvider.user!.uid)
              .orderBy('createdAt', descending: true)
              .get();

      final items =
          query.docs.map((doc) => FoodItem.fromFirestore(doc)).toList();

      print('📋 Loaded ${items.length} items from Firebase');
      for (int i = 0; i < items.length; i++) {
        print('   Item $i: ${items[i].name} (${items[i].id})');
      }

      setState(() {
        _myItems = items;
        _isLoading = false;
      });

      print('✅ My listings loaded successfully'); // Debug logging
    } catch (e) {
      print('❌ Error loading my listings: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyListings,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/add-item-enhanced'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          indicatorColor: AppColors.white,
          tabs: const [Tab(text: 'Published'), Tab(text: 'Drafts')],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Published tab
            RefreshIndicator(
              onRefresh: _loadMyListings,
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? _buildErrorState()
                      : _buildPublishedContent(),
            ),
            // Drafts tab
            _buildDraftsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: AppColors.error),
          const SizedBox(height: AppDimensions.marginL),
          Text(
            'Error loading listings',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppDimensions.marginM),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.marginL),
          ElevatedButton(
            onPressed: _loadMyListings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishedContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final publishedItems =
        _myItems.where((item) => item.status != ItemStatus.draft).toList();

    if (publishedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: isDark ? Colors.white54 : AppColors.grey,
            ),
            const SizedBox(height: AppDimensions.marginL),
            Text(
              'No listings yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.marginM),
            Text(
              'Start sharing food with your community!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.marginL),
            ElevatedButton.icon(
              onPressed: () => context.push('/add-item-enhanced'),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: AppDimensions.marginM,
        mainAxisSpacing: AppDimensions.marginM,
      ),
      itemCount: publishedItems.length,
      itemBuilder: (context, index) {
        final item = publishedItems[index];
        return _buildMyListingCard(item);
      },
    );
  }

  Widget _buildDraftsContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final draftItems =
        _myItems.where((item) => item.status == ItemStatus.draft).toList();

    if (draftItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.drafts_outlined,
              size: 80,
              color: isDark ? Colors.white54 : AppColors.grey,
            ),
            const SizedBox(height: AppDimensions.marginL),
            Text(
              'No drafts yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.marginM),
            Text(
              'Drafts are saved automatically while creating new listings.\nFinish your current listing to see it here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.marginL),
            ElevatedButton.icon(
              onPressed: () => context.push('/add-item-enhanced'),
              icon: const Icon(Icons.edit),
              label: const Text('Create New Listing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: AppDimensions.marginM,
        mainAxisSpacing: AppDimensions.marginM,
      ),
      itemCount: draftItems.length,
      itemBuilder: (context, index) {
        final item = draftItems[index];
        return _buildDraftCard(item);
      },
    );
  }

  Widget _buildMyListingCard(FoodItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.go('/item/${item.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D30) : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.grey).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.grey.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppDimensions.radiusM),
                        topRight: Radius.circular(AppDimensions.radiusM),
                      ),
                    ),
                    child:
                        item.imageUrls.isNotEmpty
                            ? ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(AppDimensions.radiusM),
                                topRight: Radius.circular(
                                  AppDimensions.radiusM,
                                ),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: item.imageUrls.first,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color: AppColors.grey.withOpacity(0.1),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      color: AppColors.grey.withOpacity(0.1),
                                      child: const Icon(
                                        Icons.image_not_supported,
                                      ),
                                    ),
                              ),
                            )
                            : const Icon(
                              Icons.fastfood,
                              size: 40,
                              color: AppColors.grey,
                            ),
                  ),
                ),
                // Content section
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingS),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Text(
                            item.description,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  isDark
                                      ? Colors.white70
                                      : AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusS,
                                  ),
                                ),
                                child: Text(
                                  '${item.quantity} ${item.unit}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            _buildStatusBadge(item.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Delete button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _showDeleteConfirmation(item),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ItemStatus status) {
    Color color;
    String text;

    switch (status) {
      case ItemStatus.draft:
        color = Colors.grey;
        text = 'Draft';
        break;
      case ItemStatus.available:
        color = Colors.green;
        text = 'Available';
        break;
      case ItemStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case ItemStatus.completed:
        color = Colors.blue;
        text = 'Completed';
        break;
      case ItemStatus.expired:
        color = Colors.red;
        text = 'Expired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(FoodItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Listing'),
          content: Text(
            'Are you sure you want to delete "${item.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteItem(item);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(FoodItem item) async {
    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final success = await itemProvider.deleteItem(item.id);

      if (success) {
        // Remove from local list
        setState(() {
          _myItems.removeWhere((i) => i.id == item.id);
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete ${item.name}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDraftCard(FoodItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/add-item-enhanced?draftId=${item.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D30) : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.grey).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Draft banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppDimensions.radiusM),
                      topRight: Radius.circular(AppDimensions.radiusM),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'DRAFT',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Image section
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.grey.withOpacity(0.1),
                    ),
                    child:
                        item.imageUrls.isNotEmpty
                            ? ClipRRect(
                              child: CachedNetworkImage(
                                imageUrl: item.imageUrls.first,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color: AppColors.grey.withOpacity(0.1),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      color: AppColors.grey.withOpacity(0.1),
                                      child: const Icon(
                                        Icons.image_not_supported,
                                      ),
                                    ),
                              ),
                            )
                            : const Icon(
                              Icons.fastfood,
                              size: 40,
                              color: AppColors.grey,
                            ),
                  ),
                ),
                // Content section
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingS),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name.isEmpty ? 'Untitled Draft' : item.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Text(
                            item.description.isEmpty
                                ? 'No description yet'
                                : item.description,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  isDark
                                      ? Colors.white70
                                      : AppColors.textSecondary,
                              fontStyle:
                                  item.description.isEmpty
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Tap to continue editing',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.orange,
                              size: 12,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Delete button
            Positioned(
              top: 40,
              right: 8,
              child: GestureDetector(
                onTap: () => _showDeleteConfirmation(item),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
