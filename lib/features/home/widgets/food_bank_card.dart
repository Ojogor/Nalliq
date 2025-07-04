import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/user_model.dart';

class FoodBankCard extends StatelessWidget {
  final AppUser foodBank;
  final VoidCallback? onTap;

  const FoodBankCard({super.key, required this.foodBank, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: AppColors.primaryGreen.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Food bank avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
              backgroundImage:
                  foodBank.photoUrl != null
                      ? NetworkImage(foodBank.photoUrl!)
                      : null,
              child:
                  foodBank.photoUrl == null
                      ? const Icon(
                        Icons.local_grocery_store,
                        color: AppColors.primaryGreen,
                        size: 24,
                      )
                      : null,
            ),

            const SizedBox(height: AppDimensions.marginS),

            // Food bank name
            Text(
              foodBank.displayName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: AppDimensions.marginXS),

            // Trust indicator
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingXS,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified,
                    size: 10,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Verified',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
