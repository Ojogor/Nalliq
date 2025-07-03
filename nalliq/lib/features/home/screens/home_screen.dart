import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/food_item_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/food_item_card.dart';
import '../widgets/section_header.dart';
import '../widgets/food_bank_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final homeProvider = context.read<HomeProvider>();

    if (authProvider.isAuthenticated && authProvider.user != null) {
      homeProvider.loadHomeData(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer3<HomeProvider, AuthProvider, CartProvider>(
        builder: (context, homeProvider, authProvider, cartProvider, child) {
          if (!authProvider.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.goNamed('login');
            });
            return const SizedBox.shrink();
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(authProvider, cartProvider),

              if (homeProvider.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    child: SearchBarWidget(
                      onSearch: (query) => _handleSearch(homeProvider, query),
                    ),
                  ),
                ),

                // Food Banks Section
                if (homeProvider.foodBanks.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: AppStrings.foodBanks,
                      subtitle: 'Trusted community partners',
                      onSeeAll: () {},
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingM,
                        ),
                        itemCount: homeProvider.foodBanks.length,
                        itemBuilder: (context, index) {
                          final foodBank = homeProvider.foodBanks[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: AppDimensions.marginM,
                            ),
                            child: FoodBankCard(foodBank: foodBank),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // Food Bank Items
                if (homeProvider.foodBankItems.isNotEmpty)
                  _buildItemSection(
                    'Featured from Food Banks',
                    homeProvider.foodBankItems,
                    cartProvider,
                  ),

                // Friends' Items
                if (homeProvider.friendsItems.isNotEmpty)
                  _buildItemSection(
                    AppStrings.friendsListings,
                    homeProvider.friendsItems,
                    cartProvider,
                  ),

                // Community Items
                if (homeProvider.communityItems.isNotEmpty)
                  _buildItemSection(
                    AppStrings.communityListings,
                    homeProvider.communityItems,
                    cartProvider,
                  ),

                // Empty state
                if (homeProvider.foodBankItems.isEmpty &&
                    homeProvider.friendsItems.isEmpty &&
                    homeProvider.communityItems.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_outlined,
                            size: 64,
                            color: AppColors.grey,
                          ),
                          SizedBox(height: AppDimensions.marginM),
                          Text(
                            'No items available yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: AppDimensions.marginS),
                          Text(
                            'Be the first to share food in your community!',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(AuthProvider authProvider, CartProvider cartProvider) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: AppColors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${authProvider.appUser?.displayName ?? 'Friend'}!',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const Text(
            'What would you like to share today?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: AppColors.white,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => context.goNamed('cart'),
            ),
            if (cartProvider.itemCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${cartProvider.itemCount}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: AppDimensions.marginS),
      ],
    );
  }

  Widget _buildItemSection(
    String title,
    List<FoodItem> items,
    CartProvider cartProvider,
  ) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          SectionHeader(title: title, onSeeAll: () {}),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.marginM),
                  child: SizedBox(
                    width: 200,
                    child: FoodItemCard(
                      item: item,
                      onTap:
                          () => context.pushNamed(
                            'item-detail',
                            pathParameters: {'itemId': item.id},
                          ),
                      onAddToCart: () => _addToCart(cartProvider, item),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppDimensions.marginL),
        ],
      ),
    );
  }

  void _handleSearch(HomeProvider homeProvider, String query) {
    homeProvider.setSearchQuery(query);
    if (query.isNotEmpty) {
      // Navigate to search results or show search overlay
      // For now, we'll just update the search query
    }
  }

  void _addToCart(CartProvider cartProvider, FoodItem item) {
    cartProvider.addItem(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
