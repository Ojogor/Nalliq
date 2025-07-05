import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../providers/home_provider.dart';

class UserStoreCard extends StatelessWidget {
  final UserStore store;
  final VoidCallback onTap;

  const UserStoreCard({super.key, required this.store, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 280,
      height: 220, // Fixed height to work in horizontal lists
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store header with avatar and info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          store.user.displayName.isNotEmpty
                              ? store.user.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Store info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.user.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${store.user.trustScore.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 16,
                                color: isDark ? Colors.white54 : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${store.totalItems} items',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white70 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          if (store.distanceKm != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  LocationService.getDistanceText(
                                    store.distanceKm!,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isDark ? Colors.white70 : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Recent items preview
              Flexible(
                child:
                    store.recentItems.isEmpty
                        ? Center(
                          child: Text(
                            'No items available',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                          ),
                        )
                        : Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent Items:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white70 : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: store.recentItems.take(3).length,
                                  separatorBuilder:
                                      (context, index) =>
                                          const SizedBox(height: 4),
                                  itemBuilder: (context, index) {
                                    final item = store.recentItems[index];
                                    return Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: AppColors.lightGreen
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.fastfood,
                                            size: 16,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                item.categoryDisplayName,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      isDark
                                                          ? Colors.white54
                                                          : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              if (store.recentItems.length > 3)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '+${store.recentItems.length - 3} more items',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
