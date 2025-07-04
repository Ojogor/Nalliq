import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/food_item_model.dart';
import '../../exchange/providers/exchange_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_item_tile.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.cart),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.isNotEmpty) {
                return TextButton(
                  onPressed: () => _showClearCartDialog(context, cartProvider),
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: AppColors.white),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartProvider.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // Cart items
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  itemCount: cartProvider.items.length,
                  separatorBuilder:
                      (context, index) =>
                          const SizedBox(height: AppDimensions.marginM),
                  itemBuilder: (context, index) {
                    final cartItem = cartProvider.items[index];
                    return CartItemTile(
                      cartItem: cartItem,
                      onRemove: () => cartProvider.removeItem(cartItem.item.id),
                      onTypeChange:
                          (isForBarter) => cartProvider.updateItemType(
                            cartItem.item.id,
                            isForBarter,
                          ),
                    );
                  },
                ),
              ),

              // Summary and action buttons
              _buildBottomSection(context, cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.grey),
          const SizedBox(height: AppDimensions.marginM),
          Text(
            'Your cart is empty',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.marginS),
          Text(
            'Browse items to add them to your cart',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.marginL),
          ElevatedButton(
            onPressed: () => context.goNamed('home'),
            child: const Text('Browse Items'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, CartProvider cartProvider) {
    final barterCount = cartProvider.barterItems.length;
    final donationCount = cartProvider.donationItems.length;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Items:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${cartProvider.itemCount}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (barterCount > 0) ...[
                  const SizedBox(height: AppDimensions.marginS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'For Barter:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      Text(
                        '$barterCount items',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (donationCount > 0) ...[
                  const SizedBox(height: AppDimensions.marginS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'For Donation:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      Text(
                        '$donationCount items',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.marginM),

          // Send request button
          ElevatedButton(
            onPressed: () => _sendRequests(context, cartProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingM,
              ),
            ),
            child: const Text('Send Requests'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequests(
    BuildContext context,
    CartProvider cartProvider,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final exchangeProvider = context.read<ExchangeProvider>();

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to send requests'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final barterItems = cartProvider.barterItems;
    final donationItems = cartProvider.donationItems;

    bool hasSuccess = false;

    try {
      // Send donation requests
      if (donationItems.isNotEmpty) {
        final donationItemIds =
            donationItems.map((item) => item.item.id).toList();
        final success = await exchangeProvider.sendDonationRequest(
          requestedItemIds: donationItemIds,
          message: 'Request for donation from cart',
        );
        if (success) hasSuccess = true;
      }

      // Send barter requests - need to show item selection for what to offer
      if (barterItems.isNotEmpty) {
        final result = await _showBarterItemSelection(context, barterItems);
        if (result != null && result.isNotEmpty) {
          final barterItemIds =
              barterItems.map((item) => item.item.id).toList();
          final success = await exchangeProvider.sendBarterRequest(
            requestedItemIds: barterItemIds,
            offeredItemIds: result,
            message: 'Barter request from cart',
          );
          if (success) hasSuccess = true;
        }
      }

      if (hasSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Requests sent successfully!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        // Clear cart after sending requests
        cartProvider.clearCart();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No requests were sent'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending requests: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<List<String>?> _showBarterItemSelection(
    BuildContext context,
    List<CartItem> barterItems,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final exchangeProvider = context.read<ExchangeProvider>();

    // Get user's available items for barter
    final availableItems = await exchangeProvider.getUserAvailableItems(
      authProvider.user!.uid,
    );

    if (availableItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You have no items available for barter. Please add some items first.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return null;
    }

    return showDialog<List<String>>(
      context: context,
      builder:
          (context) => BarterItemSelectionDialog(
            availableItems: availableItems,
            requestedItems: barterItems,
          ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Cart'),
            content: const Text(
              'Are you sure you want to remove all items from your cart?',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  cartProvider.clearCart();
                  context.pop();
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }
}

class BarterItemSelectionDialog extends StatefulWidget {
  final List<FoodItem> availableItems;
  final List<CartItem> requestedItems;

  const BarterItemSelectionDialog({
    super.key,
    required this.availableItems,
    required this.requestedItems,
  });

  @override
  State<BarterItemSelectionDialog> createState() =>
      _BarterItemSelectionDialogState();
}

class _BarterItemSelectionDialogState extends State<BarterItemSelectionDialog> {
  final Set<String> _selectedItemIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Items to Offer'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose items to offer in exchange for:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            // Show requested items
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requested items:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...widget.requestedItems.map(
                    (cartItem) => Text(
                      '• ${cartItem.item.name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your available items:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: widget.availableItems.length,
                itemBuilder: (context, index) {
                  final item = widget.availableItems[index];
                  final isSelected = _selectedItemIds.contains(item.id);

                  return CheckboxListTile(
                    title: Text(item.name),
                    subtitle: Text('${item.quantity} ${item.unit}'),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedItemIds.add(item.id);
                        } else {
                          _selectedItemIds.remove(item.id);
                        }
                      });
                    },
                    activeColor: AppColors.primaryGreen,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed:
              _selectedItemIds.isEmpty
                  ? null
                  : () => context.pop(_selectedItemIds.toList()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
          ),
          child: const Text('Send Barter Request'),
        ),
      ],
    );
  }
}
