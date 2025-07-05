import '../models/user_model.dart';
import '../models/food_item_model.dart';
import 'moderation_service.dart';

enum SafetyLevel { safe, caution, restricted, prohibited }

enum AllowedItemType {
  // Safe for all users
  cannedGoods,
  packagedSnacks,
  beverages,
  dryGoods,
  spices,

  // Friends and verified only
  freshProduce,
  bakeryItems,
  dairyProducts,
  meatProducts,

  // Food banks and organizations only
  preparedMeals,
  homemadeFood,
  bulkItems,

  // Prohibited for all
  alcoholicBeverages,
  medicinalItems,
  supplements,
  infantFormula,
  openedContainers,
}

class SafetyProtocolService {
  // Define what each user role can share
  static final Map<UserRole, List<AllowedItemType>> rolePermissions = {
    UserRole.communityMember: const [
      AllowedItemType.cannedGoods,
      AllowedItemType.packagedSnacks,
      AllowedItemType.beverages,
      AllowedItemType.dryGoods,
      AllowedItemType.spices,
    ],
    UserRole.individual: const [
      AllowedItemType.cannedGoods,
      AllowedItemType.packagedSnacks,
      AllowedItemType.beverages,
      AllowedItemType.dryGoods,
      AllowedItemType.spices,
      AllowedItemType.freshProduce,
      AllowedItemType.bakeryItems,
      AllowedItemType.dairyProducts,
    ],
    UserRole.foodBank: [
      // Food banks can share almost everything
      AllowedItemType.cannedGoods,
      AllowedItemType.packagedSnacks,
      AllowedItemType.beverages,
      AllowedItemType.dryGoods,
      AllowedItemType.spices,
      AllowedItemType.freshProduce,
      AllowedItemType.bakeryItems,
      AllowedItemType.dairyProducts,
      AllowedItemType.meatProducts,
      AllowedItemType.preparedMeals,
      AllowedItemType.homemadeFood,
      AllowedItemType.bulkItems,
    ],
    UserRole.moderator: const [
      // Moderators can access everything for review purposes
      AllowedItemType.cannedGoods,
      AllowedItemType.packagedSnacks,
      AllowedItemType.beverages,
      AllowedItemType.dryGoods,
      AllowedItemType.spices,
      AllowedItemType.freshProduce,
      AllowedItemType.bakeryItems,
      AllowedItemType.dairyProducts,
      AllowedItemType.meatProducts,
      AllowedItemType.preparedMeals,
      AllowedItemType.homemadeFood,
      AllowedItemType.bulkItems,
      AllowedItemType.alcoholicBeverages,
      AllowedItemType.medicinalItems,
      AllowedItemType.supplements,
      AllowedItemType.infantFormula,
      AllowedItemType.openedContainers,
    ],
  };

  // Check if a user can share a specific item type
  static bool canUserShareItemType(
    UserRole userRole,
    AllowedItemType itemType,
  ) {
    final allowedTypes = rolePermissions[userRole] ?? [];
    return allowedTypes.contains(itemType);
  }

  // Get safety level for an item based on user role
  static SafetyLevel getSafetyLevel(UserRole userRole, ItemCategory category) {
    switch (userRole) {
      case UserRole.communityMember:
        return _getCommunityMemberSafetyLevel(category);
      case UserRole.individual:
        return _getIndividualSafetyLevel(category);
      case UserRole.foodBank:
        return _getFoodBankSafetyLevel(category);
      case UserRole.moderator:
        return SafetyLevel.safe; // Moderators can review everything
    }
  }

  static SafetyLevel _getCommunityMemberSafetyLevel(ItemCategory category) {
    switch (category) {
      case ItemCategory.canned:
      case ItemCategory.snacks:
      case ItemCategory.beverages:
      case ItemCategory.spices:
      case ItemCategory.grains:
        return SafetyLevel.safe;
      case ItemCategory.fruits:
      case ItemCategory.vegetables:
      case ItemCategory.dairy:
      case ItemCategory.meat:
        return SafetyLevel.prohibited;
      case ItemCategory.other:
        return SafetyLevel.caution;
    }
  }

  static SafetyLevel _getIndividualSafetyLevel(ItemCategory category) {
    switch (category) {
      case ItemCategory.canned:
      case ItemCategory.snacks:
      case ItemCategory.beverages:
      case ItemCategory.spices:
      case ItemCategory.grains:
      case ItemCategory.fruits:
      case ItemCategory.vegetables:
        return SafetyLevel.safe;
      case ItemCategory.dairy:
      case ItemCategory.meat:
        return SafetyLevel.caution;
      case ItemCategory.other:
        return SafetyLevel.caution;
    }
  }

  static SafetyLevel _getFoodBankSafetyLevel(ItemCategory category) {
    // Food banks generally have fewer restrictions
    switch (category) {
      case ItemCategory.canned:
      case ItemCategory.snacks:
      case ItemCategory.beverages:
      case ItemCategory.spices:
      case ItemCategory.grains:
      case ItemCategory.fruits:
      case ItemCategory.vegetables:
      case ItemCategory.dairy:
      case ItemCategory.meat:
        return SafetyLevel.safe;
      case ItemCategory.other:
        return SafetyLevel.caution;
    }
  }

  // Get restriction message for a user role and category
  static String? getRestrictionMessage(
    UserRole userRole,
    ItemCategory category,
  ) {
    final safetyLevel = getSafetyLevel(userRole, category);

    switch (safetyLevel) {
      case SafetyLevel.safe:
        return null;
      case SafetyLevel.caution:
        return _getCautionMessage(userRole, category);
      case SafetyLevel.restricted:
        return _getRestrictedMessage(userRole, category);
      case SafetyLevel.prohibited:
        return _getProhibitedMessage(userRole, category);
    }
  }

  static String _getCautionMessage(UserRole userRole, ItemCategory category) {
    switch (userRole) {
      case UserRole.communityMember:
        return 'As a community member, please ensure this item is properly packaged and sealed.';
      case UserRole.individual:
        return 'Please ensure proper storage and include detailed expiration information.';
      case UserRole.foodBank:
        return 'Please follow your organization\'s food safety guidelines.';
      case UserRole.moderator:
        return 'Review this item carefully for safety compliance.';
    }
  }

  static String _getRestrictedMessage(
    UserRole userRole,
    ItemCategory category,
  ) {
    switch (userRole) {
      case UserRole.communityMember:
        return 'Community members have limited access to share this type of item. Consider upgrading your account or building trust in the community.';
      default:
        return 'This item type requires additional safety verification.';
    }
  }

  static String _getProhibitedMessage(
    UserRole userRole,
    ItemCategory category,
  ) {
    switch (userRole) {
      case UserRole.communityMember:
        switch (category) {
          case ItemCategory.fruits:
          case ItemCategory.vegetables:
            return 'Community members cannot share fresh produce. Only verified friends and food banks can share fresh items.';
          case ItemCategory.dairy:
          case ItemCategory.meat:
            return 'Community members cannot share dairy or meat products due to safety risks. Please share only packaged, shelf-stable items.';
          default:
            return 'This item type is not allowed for community members.';
        }
      default:
        return 'This item type is not permitted for sharing.';
    }
  }

  // Check if item needs AI verification
  static bool needsAIVerification(ItemCategory category, UserRole userRole) {
    // Community members need more verification
    if (userRole == UserRole.communityMember) {
      return [ItemCategory.canned, ItemCategory.snacks].contains(category);
    }

    // High-risk items always need verification
    return [
      ItemCategory.meat,
      ItemCategory.dairy,
      ItemCategory.other,
    ].contains(category);
  }

  // Generate safety warnings for barter confirmations
  static List<String> getBarterWarnings(
    UserRole sellerRole,
    UserRole buyerRole,
    FoodItem item,
  ) {
    List<String> warnings = [];

    // General food safety warning
    warnings.add('Always inspect food items before consumption.');

    // Community member specific warnings
    if (sellerRole == UserRole.communityMember) {
      warnings.add('⚠️ This item is being shared by a community member.');
      warnings.add('Community members can only share packaged, sealed items.');
      warnings.add('Extra caution recommended - verify packaging integrity.');
    }

    // Expiry warnings
    if (item.isNearExpiry) {
      warnings.add('⚠️ This item is near its expiration date.');
    }

    if (item.isExpired) {
      warnings.add(
        '🚨 WARNING: This item has expired. Consumption not recommended.',
      );
    }

    // Category-specific warnings
    switch (item.category) {
      case ItemCategory.dairy:
      case ItemCategory.meat:
        warnings.add('🌡️ Ensure proper refrigeration has been maintained.');
        break;
      default:
        break;
    }

    return warnings;
  }

  // Get required safety documentation for different item types
  static List<String> getRequiredDocumentation(
    ItemCategory category,
    UserRole userRole,
  ) {
    List<String> required = [];

    // Basic requirements for all
    required.addAll([
      'Clear expiration date',
      'Ingredient list or packaging photo',
      'Item condition description',
    ]);

    // Additional requirements based on category
    switch (category) {
      case ItemCategory.meat:
      case ItemCategory.dairy:
        required.addAll([
          'Storage temperature information',
          'Refrigeration chain documentation',
        ]);
        break;
      case ItemCategory.other:
        required.addAll([
          'Detailed description of contents',
          'Reason for sharing',
        ]);
        break;
      default:
        break;
    }

    // Community member additional requirements
    if (userRole == UserRole.communityMember) {
      required.addAll([
        'Sealed packaging verification',
        'Purchase date (if available)',
      ]);
    }

    return required;
  }

  // Check if user has moderator privileges for accessing restricted features
  static bool hasModeratorAccess(AppUser? user) {
    return user?.isModerator == true;
  }

  // Check if user should be restricted from sharing due to reports/trust score
  static bool isUserRestrictedFromSharing(AppUser user) {
    // Banned users cannot share
    if (user.isBanned || user.shouldBeBanned) return true;

    // Users with very low trust score and recent reports are restricted
    if (user.trustScore <= 1.0 && user.reportCount >= 3) return true;

    return false;
  }

  // Get restriction reason for user
  static String? getUserRestrictionReason(AppUser user) {
    if (user.isBanned || user.shouldBeBanned) {
      return ModerationService.getBanMessage(user);
    }

    if (user.trustScore <= 1.0 && user.reportCount >= 3) {
      return 'Your account is temporarily restricted from sharing due to recent reports and low trust score. Please contact support.';
    }

    return null;
  }

  // Enhanced safety level check that considers user reputation
  static SafetyLevel getEnhancedSafetyLevel(
    UserRole userRole,
    ItemCategory category,
    AppUser user,
  ) {
    // First check if user is restricted
    if (isUserRestrictedFromSharing(user)) {
      return SafetyLevel.prohibited;
    }

    // Get base safety level
    SafetyLevel baseLevel = getSafetyLevel(userRole, category);

    // Adjust based on user trust score for community members
    if (userRole == UserRole.communityMember && user.trustScore < 2.0) {
      // Downgrade safety level for low trust users
      switch (baseLevel) {
        case SafetyLevel.safe:
          return SafetyLevel.caution;
        case SafetyLevel.caution:
          return SafetyLevel.restricted;
        case SafetyLevel.restricted:
          return SafetyLevel.prohibited;
        case SafetyLevel.prohibited:
          return SafetyLevel.prohibited;
      }
    }

    return baseLevel;
  }
}
