import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/cart_provider.dart';

class CartItemTile extends StatelessWidget {
  final CartItem cartItem;
  final VoidCallback onRemove;
  final Function(bool) onTypeChange;

  const CartItemTile({
    super.key,
    required this.cartItem,
    required this.onRemove,
    required this.onTypeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Row(
          children: [
            // Item image
            _buildImage(),

            const SizedBox(width: AppDimensions.marginM),

            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and remove button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cartItem.item.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.close),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        color: AppColors.grey,
                      ),
                    ],
                  ),

                  // Description
                  if (cartItem.item.description.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.marginXS),
                    Text(
                      cartItem.item.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: AppDimensions.marginS),

                  // Quantity and category
                  Row(
                    children: [
                      Icon(Icons.scale, size: 14, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${cartItem.item.quantity} ${cartItem.item.unit}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.marginM),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingXS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusS,
                          ),
                        ),
                        child: Text(
                          cartItem.item.categoryDisplayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.marginM),

                  // Request type selector
                  _buildTypeSelector(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        color: AppColors.lightGrey,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        child:
            cartItem.item.imageUrls.isNotEmpty
                ? CachedNetworkImage(
                  imageUrl: cartItem.item.imageUrls.first,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => const Icon(
                        Icons.restaurant,
                        color: AppColors.grey,
                        size: 24,
                      ),
                )
                : const Icon(Icons.restaurant, color: AppColors.grey, size: 24),
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onTypeChange(false),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingS,
              ),
              decoration: BoxDecoration(
                color:
                    !cartItem.isForBarter
                        ? AppColors.primaryGreen
                        : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(
                  color:
                      !cartItem.isForBarter
                          ? AppColors.primaryGreen
                          : AppColors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    size: 16,
                    color:
                        !cartItem.isForBarter
                            ? AppColors.white
                            : AppColors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Donate',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          !cartItem.isForBarter
                              ? AppColors.white
                              : AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: AppDimensions.marginS),

        Expanded(
          child: GestureDetector(
            onTap: () => onTypeChange(true),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingS,
              ),
              decoration: BoxDecoration(
                color:
                    cartItem.isForBarter
                        ? AppColors.primaryOrange
                        : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(
                  color:
                      cartItem.isForBarter
                          ? AppColors.primaryOrange
                          : AppColors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 16,
                    color:
                        cartItem.isForBarter ? AppColors.white : AppColors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Barter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          cartItem.isForBarter
                              ? AppColors.white
                              : AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
