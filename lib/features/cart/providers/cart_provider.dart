import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/models/food_item_model.dart';

class CartItem {
  final FoodItem item;
  final bool isForBarter;
  final DateTime addedAt;

  CartItem({
    required this.item,
    required this.isForBarter,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': item.id,
      'isForBarter': isForBarter,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  static CartItem fromJson(Map<String, dynamic> json, FoodItem item) {
    return CartItem(
      item: item,
      isForBarter: json['isForBarter'] ?? false,
      addedAt: DateTime.parse(json['addedAt']),
    );
  }
}

class CartProvider extends ChangeNotifier {
  static const String _cartBoxName = 'cart';
  Box<Map>? _cartBox;

  List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  List<CartItem> get barterItems =>
      _items.where((item) => item.isForBarter).toList();

  List<CartItem> get donationItems =>
      _items.where((item) => !item.isForBarter).toList();

  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      _cartBox = await Hive.openBox<Map>(_cartBoxName);
      await _loadCartFromStorage();
    } catch (e) {
      debugPrint('Error initializing cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCartFromStorage() async {
    if (_cartBox == null) return;

    final cartData = _cartBox!.values.toList();
    _items =
        cartData
            .map((data) => _mapStorageDataToCartItem(data))
            .where((item) => item != null)
            .cast<CartItem>()
            .toList();
  }

  CartItem? _mapStorageDataToCartItem(Map data) {
    try {
      // For now, we'll create a minimal FoodItem
      // In a real app, you'd want to fetch the full item data from Firestore
      final item = FoodItem(
        id: data['itemId'] ?? '',
        ownerId: data['ownerId'] ?? '',
        name: data['itemName'] ?? '',
        description: data['itemDescription'] ?? '',
        category: ItemCategory.other,
        condition: ItemCondition.good,
        quantity: data['quantity'] ?? 1,
        unit: data['unit'] ?? 'pieces',
        reasonForOffering: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return CartItem(
        item: item,
        isForBarter: data['isForBarter'] ?? false,
        addedAt: DateTime.tryParse(data['addedAt'] ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error mapping cart item: $e');
      return null;
    }
  }

  Future<void> addItem(FoodItem item, {bool isForBarter = false}) async {
    // Check if item already exists
    final existingIndex = _items.indexWhere(
      (cartItem) => cartItem.item.id == item.id,
    );

    if (existingIndex != -1) {
      // Update existing item
      _items[existingIndex] = CartItem(
        item: item,
        isForBarter: isForBarter,
        addedAt: _items[existingIndex].addedAt,
      );
    } else {
      // Add new item
      final cartItem = CartItem(
        item: item,
        isForBarter: isForBarter,
        addedAt: DateTime.now(),
      );
      _items.add(cartItem);
    }

    await _saveToStorage();
    notifyListeners();
  }

  Future<void> removeItem(String itemId) async {
    _items.removeWhere((cartItem) => cartItem.item.id == itemId);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> updateItemType(String itemId, bool isForBarter) async {
    final index = _items.indexWhere((cartItem) => cartItem.item.id == itemId);
    if (index != -1) {
      _items[index] = CartItem(
        item: _items[index].item,
        isForBarter: isForBarter,
        addedAt: _items[index].addedAt,
      );
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    await _cartBox?.clear();
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    if (_cartBox == null) return;

    await _cartBox!.clear();

    for (int i = 0; i < _items.length; i++) {
      final cartItem = _items[i];
      await _cartBox!.put(i, {
        'itemId': cartItem.item.id,
        'ownerId': cartItem.item.ownerId,
        'itemName': cartItem.item.name,
        'itemDescription': cartItem.item.description,
        'quantity': cartItem.item.quantity,
        'unit': cartItem.item.unit,
        'isForBarter': cartItem.isForBarter,
        'addedAt': cartItem.addedAt.toIso8601String(),
      });
    }
  }

  bool isItemInCart(String itemId) {
    return _items.any((cartItem) => cartItem.item.id == itemId);
  }

  CartItem? getCartItem(String itemId) {
    try {
      return _items.firstWhere((cartItem) => cartItem.item.id == itemId);
    } catch (e) {
      return null;
    }
  }
}
