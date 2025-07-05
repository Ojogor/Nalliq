# Enhanced Safety Protocol and Moderation System Implementation

## Overview
This implementation provides a comprehensive safety protocol and moderation system for the Nalliq food sharing app, including user reporting, automatic banning, trust score management, and moderator controls.

## 🔐 API Key Management

### Files Created:
- `config/api_keys.json` - Stores the Google Maps API key securely
- `lib/core/services/config_service.dart` - Service to load configuration
- Updated `.gitignore` to exclude API keys from version control

### Usage:
```dart
await ConfigService.loadConfig();
String? apiKey = ConfigService.googleMapsApiKey;
```

## 👮‍♂️ Moderation System

### Core Features:
1. **User Reporting System**
   - Users can report other users for various reasons
   - Prevents duplicate reports from the same user
   - Tracks report count and adjusts trust scores

2. **Automatic Banning Logic**
   - Every 5 reports = -2 trust score points
   - Users with trust score ≤ 0 and account age > 1 week are auto-banned
   - Manual moderator override available

3. **Trust Score Management**
   - Dynamic scoring based on user behavior
   - Logged adjustments with moderator notes
   - Affects user capabilities in the app

### Files Created:

#### Models:
- `lib/core/models/user_report_model.dart` - Report data structure
- Enhanced `lib/core/models/user_model.dart` with reporting fields

#### Services:
- `lib/core/services/moderation_service.dart` - Core moderation logic

#### UI Components:
- `lib/core/widgets/ban_screen.dart` - Screen shown to banned users
- `lib/core/widgets/report_user_dialog.dart` - User reporting interface
- `lib/core/widgets/moderator_dashboard.dart` - Moderator management interface
- `lib/core/widgets/auth_wrapper.dart` - Authentication wrapper with ban checking

## 🛡️ Enhanced Safety Protocol

### Updated Features:
- Enhanced role-based permissions
- User reputation-based safety levels
- Moderator-only access controls
- Integration with moderation system

### Key Methods:
```dart
// Check moderator access
SafetyProtocolService.hasModeratorAccess(user)

// Check if user is restricted
SafetyProtocolService.isUserRestrictedFromSharing(user)

// Enhanced safety level with reputation
SafetyProtocolService.getEnhancedSafetyLevel(role, category, user)
```

## 📋 Report Reasons
- Inappropriate Content
- Scam or Fraud
- Unsafe Food Item
- Harassment
- Spam
- Fake Profile
- Other

## 👨‍💼 Moderator Capabilities

### Access Control:
- Only users with `UserRole.moderator` can access moderator features
- Non-moderators see "Access Denied" screen

### Dashboard Features:
1. **Pending Reports Tab**
   - View all unresolved reports
   - Resolve or dismiss reports
   - Add moderator notes

2. **User Management Tab**
   - Ban/unban users manually
   - Adjust trust scores
   - View user history

### Moderator Actions:
- Resolve/dismiss reports
- Manual user bans
- Trust score adjustments
- Review report history

## 🚫 Ban System

### Automatic Ban Triggers:
1. Trust score ≤ 0 AND account age > 1 week
2. Manual moderator action

### Ban Screen Features:
- Clear ban message
- User account information
- Contact support option
- Sign out functionality

### Ban Messages:
- Automatic: "Sorry, you have been banned from the app due to low trust score. Contact support if this is not the case."
- Manual: Custom reason provided by moderator

## 🔄 Integration Points

### Authentication Flow:
```dart
StreamBuilder<AppUser?>(
  stream: authService.userStream,
  builder: (context, snapshot) {
    return AuthWrapper(
      user: snapshot.data,
      authenticatedChild: MainAppScreen(user: snapshot.data!),
      unauthenticatedChild: LoginScreen(),
    );
  },
)
```

### Report User Example:
```dart
// In a user profile or food item screen
IconButton(
  onPressed: () => showDialog(
    context: context,
    builder: (context) => ReportUserDialog(
      reportedUser: targetUser,
      currentUser: currentUser,
      relatedItemId: foodItem?.id,
    ),
  ),
  icon: Icon(Icons.report),
)
```

### Moderator Dashboard Access:
```dart
// Only show moderator option if user is moderator
if (currentUser.isModerator) {
  ListTile(
    leading: Icon(Icons.security),
    title: Text('Moderator Dashboard'),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModeratorDashboard(currentUser: currentUser),
      ),
    ),
  ),
}
```

## 🗃️ Database Structure

### Users Collection Updates:
```json
{
  "reportCount": 0,
  "reportedByUsers": [],
  "lastReportDate": null,
  "trustScore": 5.0,
  "lastTrustScoreUpdate": null,
  "isBanned": false,
  "banReason": null,
  "banDate": null
}
```

### Reports Collection:
```json
{
  "reporterId": "user_id",
  "reportedUserId": "reported_user_id",
  "reason": "spam",
  "description": "User is posting inappropriate content",
  "status": "pending",
  "createdAt": "timestamp",
  "reviewedAt": null,
  "reviewedBy": null,
  "moderatorNotes": null,
  "relatedItemId": "food_item_id"
}
```

### Trust Score Logs Collection:
```json
{
  "userId": "user_id",
  "adjustedBy": "moderator_id",
  "newScore": 3.0,
  "reason": "Manual adjustment due to positive community feedback",
  "timestamp": "timestamp"
}
```

## 🔧 Configuration

### Required Assets in pubspec.yaml:
```yaml
assets:
  - config/firebase_config.json
  - config/api_keys.json
```

### Environment Setup:
1. Add `config/api_keys.json` to your project
2. Update `.gitignore` to exclude sensitive files
3. Initialize `ConfigService` in your app startup
4. Set up Firestore security rules for new collections

## 🚀 Next Steps

1. **Implement in Main App:**
   - Add `AuthWrapper` to your authentication flow
   - Integrate report buttons in user profiles and food item screens
   - Add moderator dashboard to admin navigation

2. **Testing:**
   - Test reporting functionality
   - Verify automatic ban triggers
   - Test moderator dashboard features

3. **Security:**
   - Set up Firestore security rules
   - Implement proper user role verification
   - Add rate limiting for reports

4. **Enhancements:**
   - Email notifications for bans
   - Appeal system for banned users
   - Analytics dashboard for moderators
   - Automated content filtering

This implementation provides a robust foundation for community moderation and safety in your food sharing application.
