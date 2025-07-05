import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/food_item_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/safety_protocol_service.dart';
import '../../auth/providers/auth_provider.dart';

class BarterConfirmationScreen extends StatefulWidget {
  final FoodItem item;
  final AppUser seller;

  const BarterConfirmationScreen({
    super.key,
    required this.item,
    required this.seller,
  });

  @override
  State<BarterConfirmationScreen> createState() =>
      _BarterConfirmationScreenState();
}

class _BarterConfirmationScreenState extends State<BarterConfirmationScreen> {
  bool _acceptedWarnings = false;
  bool _confirmedInspection = false;
  bool _agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.appUser!;

    final warnings = SafetyProtocolService.getBarterWarnings(
      widget.seller.role,
      currentUser.role,
      widget.item,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Exchange'),
        backgroundColor: isDark ? const Color(0xFF2D2D30) : AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemSummary(),
            const SizedBox(height: AppDimensions.marginL),
            _buildSellerInfo(),
            const SizedBox(height: AppDimensions.marginL),
            if (widget.seller.role == UserRole.communityMember)
              _buildCommunityMemberWarning(),
            _buildSafetyWarnings(warnings),
            const SizedBox(height: AppDimensions.marginL),
            _buildPhotoUploadSection(),
            const SizedBox(height: AppDimensions.marginL),
            _buildConfirmationChecks(),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildItemSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item Details',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginM),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  child:
                      widget.item.imageUrls.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: widget.item.imageUrls.first,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorWidget:
                                (context, url, error) =>
                                    _buildPlaceholderImage(),
                          )
                          : _buildPlaceholderImage(),
                ),
                const SizedBox(width: AppDimensions.marginM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.scale, size: 16, color: AppColors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.item.quantity} ${widget.item.unit}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (widget.item.expiryDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color:
                                  widget.item.isExpired
                                      ? AppColors.error
                                      : AppColors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Expires: ${_formatDate(widget.item.expiryDate!)}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color:
                                    widget.item.isExpired
                                        ? AppColors.error
                                        : null,
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
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: const Icon(Icons.restaurant, color: AppColors.grey),
    );
  }

  Widget _buildSellerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shared by',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginM),
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.lightGrey,
                  backgroundImage:
                      widget.seller.photoUrl != null
                          ? CachedNetworkImageProvider(widget.seller.photoUrl!)
                          : null,
                  child:
                      widget.seller.photoUrl == null
                          ? const Icon(Icons.person, color: AppColors.grey)
                          : null,
                ),
                const SizedBox(width: AppDimensions.marginM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.seller.displayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildRoleBadge(widget.seller.role),
                          const SizedBox(width: 8),
                          _buildTrustBadge(widget.seller.trustLevel),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    Color color;
    String text;

    switch (role) {
      case UserRole.communityMember:
        color = AppColors.warning;
        text = 'Community';
        break;
      case UserRole.individual:
        color = AppColors.primaryGreen;
        text = 'Friend';
        break;
      case UserRole.foodBank:
        color = AppColors.success;
        text = 'Food Bank';
        break;
      case UserRole.moderator:
        color = AppColors.error;
        text = 'Moderator';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTrustBadge(TrustLevel trustLevel) {
    Color color;
    IconData icon;

    switch (trustLevel) {
      case TrustLevel.low:
        color = AppColors.error;
        icon = Icons.shield_outlined;
        break;
      case TrustLevel.medium:
        color = AppColors.warning;
        icon = Icons.shield;
        break;
      case TrustLevel.high:
        color = AppColors.success;
        icon = Icons.verified;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          trustLevel.name.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityMemberWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.marginL),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        border: Border.all(color: AppColors.warning, width: 2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.warning, size: 24),
              const SizedBox(width: 8),
              Text(
                'COMMUNITY MEMBER ALERT',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This item is being shared by a community member. Community members can only share packaged, sealed items. Please verify:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ...[
            '• Package is sealed and unopened',
            '• Item is within expiration date',
            '• No visible damage to packaging',
            '• Ingredients are clearly labeled',
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(item, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyWarnings(List<String> warnings) {
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Safety Guidelines',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.marginM),
            ...warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUploadSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verification Photos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginS),
            Text(
              'Both parties should take photos of the item before exchange for safety and verification purposes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppDimensions.marginM),
            Row(
              children: [
                Expanded(
                  child: _buildPhotoUploadButton(
                    'Your Photo',
                    Icons.camera_alt,
                  ),
                ),
                const SizedBox(width: AppDimensions.marginM),
                Expanded(
                  child: _buildPhotoUploadButton(
                    'Item Received',
                    Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUploadButton(String label, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: Implement photo upload
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo upload feature coming soon')),
        );
      },
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
      ),
    );
  }

  Widget _buildConfirmationChecks() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmation Required',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.marginM),
            CheckboxListTile(
              value: _acceptedWarnings,
              onChanged:
                  (value) => setState(() => _acceptedWarnings = value ?? false),
              title: const Text(
                'I have read and understood all safety warnings',
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primaryGreen,
            ),
            CheckboxListTile(
              value: _confirmedInspection,
              onChanged:
                  (value) =>
                      setState(() => _confirmedInspection = value ?? false),
              title: const Text('I will inspect the item before consuming'),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primaryGreen,
            ),
            CheckboxListTile(
              value: _agreedToTerms,
              onChanged:
                  (value) => setState(() => _agreedToTerms = value ?? false),
              title: const Text(
                'I accept responsibility for my health and safety',
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final allConfirmed =
        _acceptedWarnings && _confirmedInspection && _agreedToTerms;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: AppDimensions.marginM),
          Expanded(
            child: ElevatedButton(
              onPressed: allConfirmed ? _confirmBarter : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Confirm Exchange'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBarter() {
    // TODO: Implement barter confirmation logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exchange confirmed! Please coordinate pickup details.'),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) {
      return 'Expired ${difference.abs()} days ago';
    } else if (difference == 0) {
      return 'Expires today';
    } else if (difference == 1) {
      return 'Expires tomorrow';
    } else {
      return 'Expires in $difference days';
    }
  }
}
