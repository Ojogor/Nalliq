import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/providers/home_provider.dart';
import '../../home/widgets/food_item_card.dart';
import '../../home/widgets/user_store_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);

    // Combine all available food items from different sources
    final allItems = [
      ...homeProvider.communityItems,
      ...homeProvider.friendsItems,
      ...homeProvider.foodBankItems,
    ];

    // Filter food items based on search query
    final filteredItems =
        allItems.where((item) {
          return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
        }).toList();

    // Filter user stores based on search query
    final allStores = [
      ...homeProvider.communityStores,
      ...homeProvider.friendStores,
      ...homeProvider.foodBankStores,
    ];

    final filteredStores =
        allStores.where((store) {
          // Search by user name
          final nameMatch = store.user.displayName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

          // Search by items that the user has
          final itemMatch = store.recentItems.any(
            (item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          );

          return nameMatch || itemMatch;
        }).toList();

    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.black87),
            decoration: const InputDecoration(
              hintText: 'Search for food items or users...',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
          ),
        ],
        bottom:
            _searchQuery.isNotEmpty
                ? TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restaurant, size: 16),
                          const SizedBox(width: 4),
                          Text('Food (${filteredItems.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people, size: 16),
                          const SizedBox(width: 4),
                          Text('Users (${filteredStores.length})'),
                        ],
                      ),
                    ),
                  ],
                  indicatorColor: AppColors.white,
                  labelColor: AppColors.white,
                  unselectedLabelColor: Colors.white70,
                )
                : null,
      ),
      body:
          _searchQuery.isEmpty
              ? _buildEmptyState()
              : TabBarView(
                controller: _tabController,
                children: [
                  // Food Items Tab
                  filteredItems.isEmpty
                      ? _buildNoResultsState('food items')
                      : _buildFoodSearchResults(filteredItems),
                  // Users Tab
                  filteredStores.isEmpty
                      ? _buildNoResultsState('users')
                      : _buildUserSearchResults(filteredStores),
                ],
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white54
                    : AppColors.grey,
          ),
          const SizedBox(height: AppDimensions.marginM),
          Text(
            'Start typing to search for food items',
            style: TextStyle(
              fontSize: 16,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState([String searchType = 'items']) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white54
                    : AppColors.grey,
          ),
          const SizedBox(height: AppDimensions.marginM),
          Text(
            'No $searchType found for "$_searchQuery"',
            style: TextStyle(
              fontSize: 16,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.marginS),
          Text(
            'Try different keywords or check spelling',
            style: TextStyle(
              fontSize: 14,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54
                      : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodSearchResults(List items) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.marginM),
          child: SizedBox(
            height: 280, // Fixed height for ListView cards
            child: FoodItemCard(
              item: item,
              onTap:
                  () => context.pushNamed(
                    'item-detail',
                    pathParameters: {'itemId': item.id},
                  ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserSearchResults(List stores) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final store = stores[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.marginM),
          child: UserStoreCard(
            store: store,
            onTap: () {
              // Navigate to user store profile
              context.pushNamed('store-profile', extra: store.user);
            },
          ),
        );
      },
    );
  }
}
