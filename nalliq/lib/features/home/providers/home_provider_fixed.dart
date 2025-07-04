import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/food_item_model.dart';
import '../../../core/models/user_model.dart';

class UserStore {
  final AppUser user;
  final List<FoodItem> recentItems;
  final int totalItems;
  final bool isFriend;

  const UserStore({
    required this.user,
    required this.recentItems,
    required this.totalItems,
    required this.isFriend,
  });
}

class HomeProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserStore> _communityStores = [];
  List<UserStore> _friendStores = [];
  List<UserStore> _foodBankStores = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<UserStore> get communityStores => _communityStores;
  List<UserStore> get friendStores => _friendStores;
  List<UserStore> get foodBankStores => _foodBankStores;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  // Keep these for backward compatibility if needed
  List<FoodItem> get foodBankItems =>
      _foodBankStores.expand((store) => store.recentItems).toList();
  List<FoodItem> get friendsItems =>
      _friendStores.expand((store) => store.recentItems).toList();
  List<FoodItem> get communityItems =>
      _communityStores.expand((store) => store.recentItems).toList();
  List<AppUser> get foodBanks =>
      _foodBankStores.map((store) => store.user).toList();

  Future<void> loadHomeData(String currentUserId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🏠 Loading home data for user: $currentUserId');

      // Get current user's friends list
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final friendIds =
          currentUserDoc.exists
              ? List<String>.from(currentUserDoc.data()?['friendIds'] ?? [])
              : <String>[];

      print('👥 User has ${friendIds.length} friends: $friendIds');

      // Load all stores in parallel
      await Future.wait([
        _loadCommunityStores(currentUserId, friendIds),
        _loadFriendStores(friendIds),
        _loadFoodBankStores(friendIds),
      ]);

      print('✅ Home data loading completed');
      print(
        '📊 Summary: ${_communityStores.length} community, ${_friendStores.length} friends, ${_foodBankStores.length} food banks',
      );
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading home data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCommunityStores(
    String currentUserId,
    List<String> friendIds,
  ) async {
    try {
      print('🏘️ Loading community stores...');

      // Get all community users (using 'user' role instead of 'individual')
      final usersQuery =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'user')
              .get();

      print('👤 Found ${usersQuery.docs.length} users with role "user"');

      final communityUsers =
          usersQuery.docs
              .map((doc) => AppUser.fromFirestore(doc))
              .where(
                (user) =>
                    user.id != currentUserId && !friendIds.contains(user.id),
              )
              .toList();

      print('🔍 After filtering: ${communityUsers.length} community users');

      // For each community user, get their recent items
      final stores = <UserStore>[];
      for (final user in communityUsers) {
        print('📦 Loading items for user: ${user.displayName} (${user.id})');
        final itemsQuery =
            await _firestore
                .collection('items')
                .where('ownerId', isEqualTo: user.id)
                // No status filter since items don't have status field
                .orderBy('createdAt', descending: true)
                .limit(5)
                .get();

        final recentItems =
            itemsQuery.docs.map((doc) => FoodItem.fromFirestore(doc)).toList();

        print(
          '   📊 User ${user.displayName} has ${recentItems.length} recent items',
        );

        // Get total item count
        final totalItemsQuery =
            await _firestore
                .collection('items')
                .where('ownerId', isEqualTo: user.id)
                // No status filter since items don't have status field
                .get();

        // Include all users (even those with no items) for debugging
        stores.add(
          UserStore(
            user: user,
            recentItems: recentItems,
            totalItems: totalItemsQuery.docs.length,
            isFriend: false,
          ),
        );
      }

      _communityStores = stores;
      print('✅ Loaded ${stores.length} community stores');
    } catch (e) {
      print('❌ Error loading community stores: $e');
      _communityStores = [];
    }
  }

  Future<void> _loadFriendStores(List<String> friendIds) async {
    try {
      print('👥 Loading friend stores...');

      if (friendIds.isEmpty) {
        _friendStores = [];
        print('   ℹ️ No friends to load');
        return;
      }

      // Get friend users
      final usersQuery =
          await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: friendIds)
              .get();

      print('👤 Found ${usersQuery.docs.length} friend users');

      final friendUsers =
          usersQuery.docs.map((doc) => AppUser.fromFirestore(doc)).toList();

      // For each friend, get their recent items
      final stores = <UserStore>[];
      for (final user in friendUsers) {
        print('📦 Loading items for friend: ${user.displayName} (${user.id})');
        final itemsQuery =
            await _firestore
                .collection('items')
                .where('ownerId', isEqualTo: user.id)
                // No status filter since items don't have status field
                .orderBy('createdAt', descending: true)
                .limit(5)
                .get();

        final recentItems =
            itemsQuery.docs.map((doc) => FoodItem.fromFirestore(doc)).toList();

        print(
          '   📊 Friend ${user.displayName} has ${recentItems.length} recent items',
        );

        // Get total item count
        final totalItemsQuery =
            await _firestore
                .collection('items')
                .where('ownerId', isEqualTo: user.id)
                // No status filter since items don't have status field
                .get();

        stores.add(
          UserStore(
            user: user,
            recentItems: recentItems,
            totalItems: totalItemsQuery.docs.length,
            isFriend: true,
          ),
        );
      }

      _friendStores = stores;
      print('✅ Loaded ${stores.length} friend stores');
    } catch (e) {
      print('❌ Error loading friend stores: $e');
      _friendStores = [];
    }
  }

  Future<void> _loadFoodBankStores(List<String> friendIds) async {
    try {
      print('🏪 Loading food bank stores...');

      // Get all food bank users
      final usersQuery =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'foodBank')
              .orderBy('trustScore', descending: true)
              .get();

      print('🏦 Found ${usersQuery.docs.length} food bank users');

      final foodBankUsers =
          usersQuery.docs.map((doc) => AppUser.fromFirestore(doc)).toList();

      // For each food bank, get their recent items
      final stores = <UserStore>[];
      for (final user in foodBankUsers) {
        print(
          '📦 Loading items for food bank: ${user.displayName} (${user.id})',
        );
        final itemsQuery =
            await _firestore
                .collection('items')
                .where('ownerId', isEqualTo: user.id)
                // No status filter since items don't have status field
                .orderBy('createdAt', descending: true)
                .limit(5)
                .get();

        final recentItems =
            itemsQuery.docs.map((doc) => FoodItem.fromFirestore(doc)).toList();

        print(
          '   📊 Food bank ${user.displayName} has ${recentItems.length} recent items',
        );

        // Get total item count
        final totalItemsQuery =
            await _firestore
                .collection('items')
                .where('ownerId', isEqualTo: user.id)
                // No status filter since items don't have status field
                .get();

        stores.add(
          UserStore(
            user: user,
            recentItems: recentItems,
            totalItems: totalItemsQuery.docs.length,
            isFriend: friendIds.contains(user.id),
          ),
        );
      }

      _foodBankStores = stores;
      print('✅ Loaded ${stores.length} food bank stores');
    } catch (e) {
      print('❌ Error loading food bank stores: $e');
      _foodBankStores = [];
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<List<FoodItem>> searchItems(String query) async {
    if (query.isEmpty) return [];

    try {
      final results =
          await _firestore
              .collection('items')
              // Remove status filter for search too
              .orderBy('createdAt', descending: true)
              .get();

      final items =
          results.docs
              .map((doc) => FoodItem.fromFirestore(doc))
              .where(
                (item) =>
                    item.name.toLowerCase().contains(query.toLowerCase()) ||
                    item.description.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    item.categoryDisplayName.toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
              .toList();

      return items;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<void> refreshData(String currentUserId) async {
    await loadHomeData(currentUserId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
