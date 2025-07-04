import 'food_item_model.dart';

class CartItem {
  final FoodItem item;
  final bool isForBarter;
  final DateTime addedAt;

  const CartItem({
    required this.item,
    required this.isForBarter,
    required this.addedAt,
  });

  CartItem copyWith({FoodItem? item, bool? isForBarter, DateTime? addedAt}) {
    return CartItem(
      item: item ?? this.item,
      isForBarter: isForBarter ?? this.isForBarter,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': item.id,
      'ownerId': item.ownerId,
      'itemName': item.name,
      'isForBarter': isForBarter,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  static CartItem? fromMap(Map<String, dynamic> map, FoodItem item) {
    try {
      return CartItem(
        item: item,
        isForBarter: map['isForBarter'] as bool? ?? false,
        addedAt: DateTime.fromMillisecondsSinceEpoch(
          map['addedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (e) {
      return null;
    }
  }
}
