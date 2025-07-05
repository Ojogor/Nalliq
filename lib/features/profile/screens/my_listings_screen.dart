import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/food_item_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/widgets/food_item_card.dart';

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

    if (_myItems.isEmpty) {
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
      itemCount: _myItems.length,
      itemBuilder: (context, index) {
        final item = _myItems[index];
        return FoodItemCard(
          item: item,
          onTap: () => context.go('/item/${item.id}'),
          showAddButton: false, // Never show add to cart for own items
        );
      },
    );
  }

  Widget _buildDraftsContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
}
