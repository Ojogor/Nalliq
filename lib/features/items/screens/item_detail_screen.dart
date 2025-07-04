import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/food_item_model.dart';
import '../providers/item_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  FoodItem? _item;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    final itemProvider = context.read<ItemProvider>();
    final item = await itemProvider.getItemById(widget.itemId);

    if (mounted) {
      setState(() {
        _item = item;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : AppColors.background,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _item == null
              ? _buildNotFound()
              : _buildItemDetail(),
      bottomNavigationBar: _item != null ? _buildBottomActions() : null,
    );
  }

  Widget _buildNotFound() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54
                      : AppColors.grey,
            ),
            const SizedBox(height: AppDimensions.marginM),
            Text(
              'Item not found',
              style: TextStyle(
                fontSize: 18,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDetail() {
    return CustomScrollView(
      slivers: [
        // App bar with image
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          flexibleSpace: FlexibleSpaceBar(
            background:
                _item!.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: _item!.imageUrls.first,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]
                                    : AppColors.lightGrey,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]
                                    : AppColors.lightGrey,
                            child: Icon(
                              Icons.restaurant,
                              size: 64,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white54
                                      : AppColors.grey,
                            ),
                          ),
                    )
                    : Container(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : AppColors.lightGrey,
                      child: Icon(
                        Icons.restaurant,
                        size: 64,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white54
                                : AppColors.grey,
                      ),
                    ),
          ),
        ),

        // Item details
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item name and category
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _item!.name,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingS,
                        vertical: AppDimensions.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusS,
                        ),
                      ),
                      child: Text(
                        _item!.categoryDisplayName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.marginM),

                // Description
                Text(
                  _item!.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

                const SizedBox(height: AppDimensions.marginL),

                // Details cards
                _buildDetailsSection(),

                const SizedBox(height: AppDimensions.marginL),

                // Availability options
                _buildAvailabilitySection(),
                const SizedBox(height: AppDimensions.marginXL),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: AppDimensions.marginM),

        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                'Quantity',
                '${_item!.quantity} ${_item!.unit}',
                Icons.scale,
              ),
            ),
            const SizedBox(width: AppDimensions.marginM),
            Expanded(
              child: _buildDetailCard(
                'Condition',
                _item!.conditionDisplayName,
                Icons.grade,
              ),
            ),
          ],
        ),

        if (_item!.expiryDate != null) ...[
          const SizedBox(height: AppDimensions.marginM),
          _buildDetailCard(
            'Expiry Date',
            '${_item!.expiryDate!.day}/${_item!.expiryDate!.month}/${_item!.expiryDate!.year}',
            Icons.calendar_today,
            fullWidth: true,
          ),
        ],

        const SizedBox(height: AppDimensions.marginM),

        _buildDetailCard(
          'Reason for Offering',
          _item!.reasonForOffering,
          Icons.info_outline,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildDetailCard(
    String title,
    String value,
    IconData icon, {
    bool fullWidth = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.grey).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? Colors.white54 : AppColors.grey,
              ),
              const SizedBox(width: AppDimensions.marginXS),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.marginXS),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: AppDimensions.marginM),

        Row(
          children: [
            if (_item!.isForDonation)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: AppDimensions.marginS),
                      const Text(
                        'Available for\nDonation',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_item!.isForDonation && _item!.isForBarter)
              const SizedBox(width: AppDimensions.marginM),

            if (_item!.isForBarter)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: AppColors.primaryOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.swap_horiz,
                        color: AppColors.primaryOrange,
                        size: 20,
                      ),
                      const SizedBox(width: AppDimensions.marginS),
                      const Text(
                        'Available for\nBarter',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Consumer2<CartProvider, AuthProvider>(
      builder: (context, cartProvider, authProvider, child) {
        // Check if the current user owns this item
        final isOwnItem = authProvider.user?.uid == _item?.ownerId;

        // If user owns the item, don't show the cart button
        if (isOwnItem) {
          return const SizedBox.shrink();
        }

        final isInCart = cartProvider.isItemInCart(widget.itemId);

        return Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : AppColors.white,
            boxShadow: [
              BoxShadow(
                color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : AppColors.grey)
                    .withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: isInCart ? null : () => _addToCart(cartProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.paddingM,
                ),
              ),
              child: Text(
                isInCart ? 'Already in Cart' : 'Add to Cart',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _addToCart(CartProvider cartProvider) {
    if (_item != null) {
      cartProvider.addItem(_item!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_item!.name} added to cart'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
