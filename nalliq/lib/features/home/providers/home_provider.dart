import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/food_item_model.dart';
import '../../../core/models/user_model.dart';

class HomeProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<FoodItem> _foodBankItems = [];
  List<FoodItem> _friendsItems = [];
  List<FoodItem> _communityItems = [];
  List<AppUser> _foodBanks = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<FoodItem> get foodBankItems => _foodBankItems;
  List<FoodItem> get friendsItems => _friendsItems;
  List<FoodItem> get communityItems => _communityItems;
  List<AppUser> get foodBanks => _foodBanks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  Future<void> loadHomeData(String currentUserId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Load in parallel
      await Future.wait([
        _loadFoodBankItems(),
        _loadFriendsItems(currentUserId),
        _loadCommunityItems(currentUserId),
        _loadFoodBanks(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFoodBankItems() async {
    // Get food bank users first
    final foodBankQuery =
        await _firestore
            .collection('users')
            .where('role', isEqualTo: 'foodBank')
            .get();

    final foodBankIds = foodBankQuery.docs.map((doc) => doc.id).toList();

    if (foodBankIds.isEmpty) {
      _foodBankItems = [];
      return;
    }

    final itemsQuery =
        await _firestore
            .collection('items')
            .where('ownerId', whereIn: foodBankIds)
            .where('status', isEqualTo: 'available')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();

    _foodBankItems =
        itemsQuery.docs.map((doc) => FoodItem.fromFirestore(doc)).toList();
  }

  Future<void> _loadFriendsItems(String currentUserId) async {
    // Get current user's friends
    final userDoc =
        await _firestore.collection('users').doc(currentUserId).get();
    if (!userDoc.exists) {
      _friendsItems = [];
      return;
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final friendIds = List<String>.from(userData['friendIds'] ?? []);

    if (friendIds.isEmpty) {
      _friendsItems = [];
      return;
    }

    final itemsQuery =
        await _firestore
            .collection('items')
            .where('ownerId', whereIn: friendIds)
            .where('status', isEqualTo: 'available')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();

    _friendsItems =
        itemsQuery.docs.map((doc) => FoodItem.fromFirestore(doc)).toList();
  }

  Future<void> _loadCommunityItems(String currentUserId) async {
    final itemsQuery =
        await _firestore
            .collection('items')
            .where('status', isEqualTo: 'available')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get();

    // Filter out current user's items and items already in other categories
    final allItems =
        itemsQuery.docs
            .map((doc) => FoodItem.fromFirestore(doc))
            .where((item) => item.ownerId != currentUserId)
            .toList();

    final foodBankOwnerIds = _foodBankItems.map((item) => item.ownerId).toSet();
    final friendOwnerIds = _friendsItems.map((item) => item.ownerId).toSet();

    _communityItems =
        allItems
            .where(
              (item) =>
                  !foodBankOwnerIds.contains(item.ownerId) &&
                  !friendOwnerIds.contains(item.ownerId),
            )
            .toList();
  }

  Future<void> _loadFoodBanks() async {
    final query =
        await _firestore
            .collection('users')
            .where('role', isEqualTo: 'foodBank')
            .orderBy('trustScore', descending: true)
            .get();

    _foodBanks = query.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
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
