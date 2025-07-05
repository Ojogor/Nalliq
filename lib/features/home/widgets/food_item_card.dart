import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/food_item_model.dart';
import '../../../core/models/user_location.dart';
import '../../../core/services/firebase_location_service.dart';
import '../../location/providers/new_location_provider.dart';

class FoodItemCard extends StatelessWidget {
  final FoodItem item;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool showAddButton;

  const FoodItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onAddToCart,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            _buildImageSection(),

            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Item name and condition
                    _buildHeader(context),

                    const SizedBox(height: 2), // Reduced spacing
                    // Description - flexible
                    Flexible(child: _buildDescription(context)),

                    const SizedBox(height: 2), // Reduced spacing
                    // Quantity and expiry
                    _buildDetails(context),

                    // Distance information if available - only show if space allows
                    if (MediaQuery.of(context).size.height > 600)
                      _buildDistanceInfo(context),

                    // Add spacing only if there's an add button
                    if (showAddButton && onAddToCart != null) ...[
                      const SizedBox(
                        height: 6,
                      ), // Fixed spacing instead of Spacer
                      _buildAddButton(context),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusM),
          topRight: Radius.circular(AppDimensions.radiusM),
        ),
        color: AppColors.lightGrey,
      ),
      child: Stack(
        children: [
          // Main image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusM),
              topRight: Radius.circular(AppDimensions.radiusM),
            ),
            child:
                item.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: item.imageUrls.first,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                      errorWidget:
                          (context, url, error) => _buildDefaultImage(),
                    )
                    : _buildDefaultImage(),
          ),

          // Category badge
          Positioned(
            top: AppDimensions.marginS,
            left: AppDimensions.marginS,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingS,
                vertical: AppDimensions.paddingXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.9),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Text(
                item.categoryDisplayName,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Expiry indicator
          if (item.isNearExpiry || item.isExpired)
            Positioned(
              top: AppDimensions.marginS,
              right: AppDimensions.marginS,
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingXS),
                decoration: BoxDecoration(
                  color: item.isExpired ? AppColors.error : AppColors.warning,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  item.isExpired ? Icons.warning : Icons.schedule,
                  color: AppColors.white,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.lightGrey,
      child: const Icon(Icons.restaurant, size: 40, color: AppColors.grey),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Text(
            item.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12, // Slightly smaller
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getConditionColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Text(
            item.conditionDisplayName,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: _getConditionColor(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      item.description,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: isDark ? Colors.white70 : AppColors.textSecondary,
        fontSize: 10, // Smaller font
        height: 1.2, // Reduced line height
      ),
      maxLines: 1, // Reduced from 2 to 1 line
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDetails(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          Icons.scale,
          size: 12,
          color: isDark ? Colors.white54 : AppColors.grey,
        ),
        const SizedBox(width: 3),
        Expanded(
          flex: 3,
          child: Text(
            '${item.quantity} ${item.unit}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 9,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (item.expiryDate != null) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.calendar_today,
            size: 12,
            color: isDark ? Colors.white54 : AppColors.grey,
          ),
          const SizedBox(width: 3),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(item.expiryDate!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 9,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDistanceInfo(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        if (locationProvider.currentLocation == null || item.location == null) {
          return const SizedBox.shrink();
        }

        try {
          final distance = FirebaseLocationService.calculateDistance(
            locationProvider.currentLocation!,
            UserLocation(
              latitude: (item.location!['latitude'] as num?)?.toDouble() ?? 0,
              longitude: (item.location!['longitude'] as num?)?.toDouble() ?? 0,
              address: item.location!['address'] as String? ?? '',
              city: item.location!['city'] as String? ?? '',
              province: item.location!['province'] as String? ?? '',
              country: item.location!['country'] as String? ?? '',
              isVisible: true,
              lastUpdated: DateTime.now(),
            ),
          );

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 10, color: AppColors.info),
                const SizedBox(width: 2),
                Text(
                  '${distance.toStringAsFixed(1)}km',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 24, // Further reduced height
      child: ElevatedButton(
        onPressed: onAddToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 24),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
        ),
        child: const Text(
          'Add to Cart',
          style: TextStyle(
            fontSize: 10, // Smaller font
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getConditionColor() {
    switch (item.condition) {
      case ItemCondition.excellent:
        return AppColors.success;
      case ItemCondition.good:
        return AppColors.primaryGreen;
      case ItemCondition.fair:
        return AppColors.warning;
      case ItemCondition.poor:
        return AppColors.error;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) {
      return 'Expired';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference <= 7) {
      return '${difference}d';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
