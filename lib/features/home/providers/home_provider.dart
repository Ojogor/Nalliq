import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/food_item_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/user_service.dart';
import '../../location/providers/new_location_provider.dart';
import '../../../core/models/user_location.dart';

class UserStore {
  final AppUser user;
  final List<FoodItem> recentItems;
  final int totalItems;
  final bool isFriend;
  final double? distanceKm;

  const UserStore({
    required this.user,
    required this.recentItems,
    required this.totalItems,
    required this.isFriend,
    this.distanceKm,
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

  LocationProvider? locationProvider;

  HomeProvider({this.locationProvider});

  void updateLocationProvider(LocationProvider? provider) {
    if (locationProvider != provider) {
      locationProvider = provider;
      _recalculateDistances();
      notifyListeners();
    }
  }

  void _recalculateDistances() {
    if (locationProvider?.currentLocation == null) return;

    final location = locationProvider!.currentLocation!;

    _communityStores = _recalculateStoreDistances(_communityStores, location);
    _friendStores = _recalculateStoreDistances(_friendStores, location);
    _foodBankStores = _recalculateStoreDistances(_foodBankStores, location);
  }

  List<UserStore> _recalculateStoreDistances(
    List<UserStore> stores,
    UserLocation location,
  ) {
    return stores.map((store) {
      if (store.user.location == null) return store;

      final userLat = store.user.location!['lat'] as double?;
      final userLng = store.user.location!['lng'] as double?;

      if (userLat == null || userLng == null) return store;

      final distance = LocationService.calculateDistance(
        location.latitude,
        location.longitude,
        userLat,
        userLng,
      );

      return UserStore(
        user: store.user,
        recentItems: store.recentItems,
        totalItems: store.totalItems,
        isFriend: store.isFriend,
        distanceKm: distance,
      );
    }).toList();
  }

  Future<double?> _calculateDistanceToUser(AppUser user) async {
    try {
      final location = locationProvider?.currentLocation;
      // Use location from provider if available
      if (location != null && user.location != null) {
        final currentLat = location.latitude;
        final currentLng = location.longitude;
        final userLat = user.location!['lat'] as double?;
        final userLng = user.location!['lng'] as double?;

        if (userLat != null && userLng != null) {
          return LocationService.calculateDistance(
            currentLat,
            currentLng,
            userLat,
            userLng,
          );
        }
      }

      // Fallback to Firestore location
      final currentUser = await UserService.getCurrentUser();
      if (currentUser?.location == null || user.location == null) {
        return null;
      }

      final currentLat = currentUser!.location!['lat'] as double?;
      final currentLng = currentUser.location!['lng'] as double?;
      final userLat = user.location!['lat'] as double?;
      final userLng = user.location!['lng'] as double?;

      if (currentLat != null &&
          currentLng != null &&
          userLat != null &&
          userLng != null) {
        return LocationService.calculateDistance(
          currentLat,
          currentLng,
          userLat,
          userLng,
        );
      }
    } catch (e) {
      print('Error calculating distance: $e');
    }
    return null;
  }

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

      // Get all community users (not food banks, not current user, not friends)
      final usersSnapshot =
          await _firestore
              .collection('users')
              .where(
                'role',
                isEqualTo: 'individual',
              ) // Changed to 'individual' to match what we set in fix
              .get();
      print(
        '👤 Found ${usersSnapshot.docs.length} users with role "individual"',
      );

      // Debug: Print all found users
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        print(
          '   📄 User: ${data['displayName']} (${doc.id}) - Role: ${data['role']}',
        );
      }

      // Debug specific user
      final specificUserId = 'QBy4SvUGjKcydW3eu4cypbYfuZ92';
      final hasSpecificUser = usersSnapshot.docs.any(
        (doc) => doc.id == specificUserId,
      );
      print('🔍 Does query include user $specificUserId? $hasSpecificUser');

      final communityUsers =
          usersSnapshot.docs
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
                // Temporarily remove status filter until Firestore index is built
                // .where('status', isEqualTo: 'available')
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
                // Temporarily remove status filter until Firestore index is built
                // .where('status', isEqualTo: 'available')
                .get();

        // Calculate distance to this user
        final distance = await _calculateDistanceToUser(user);

        // Include all users (even those with no items) for debugging
        stores.add(
          UserStore(
            user: user,
            recentItems: recentItems,
            totalItems: totalItemsQuery.docs.length,
            isFriend: false,
            distanceKm: distance,
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
                // Temporarily remove status filter until Firestore index is built
                // .where('status', isEqualTo: 'available')
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
                .where(
                  'status',
                  isEqualTo: 'available',
                ) // Restored since items DO have status
                .get();

        // Calculate distance to this friend
        final distance = await _calculateDistanceToUser(user);

        stores.add(
          UserStore(
            user: user,
            recentItems: recentItems,
            totalItems: totalItemsQuery.docs.length,
            isFriend: true,
            distanceKm: distance,
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

      // First, let's check all users and their roles for debugging
      final allUsersQuery = await _firestore.collection('users').get();
      print('👥 Total users in database: ${allUsersQuery.docs.length}');
      for (final doc in allUsersQuery.docs) {
        final data = doc.data();
        print('   User: ${data['displayName']} - Role: ${data['role']}');
      }

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
                .where(
                  'status',
                  isEqualTo: 'available',
                ) // Restored since items DO have status
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
                .where(
                  'status',
                  isEqualTo: 'available',
                ) // Restored since items DO have status
                .get();

        // Calculate distance to this food bank
        final distance = await _calculateDistanceToUser(user);

        stores.add(
          UserStore(
            user: user,
            recentItems: recentItems,
            totalItems: totalItemsQuery.docs.length,
            isFriend: friendIds.contains(user.id),
            distanceKm: distance,
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
              .where('status', isEqualTo: 'available')
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
